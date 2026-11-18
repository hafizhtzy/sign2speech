import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { HttpError, requireActiveRole } from '../_shared/auth_guard.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { actor, adminClient } = await requireActiveRole(req, ['admin']);
    const body = await req.json();
    const action = String(body.action ?? '').trim();

    // Hard block against any attempt to create or escalate to ADMIN via Edge Function
    if (body.role && String(body.role).toLowerCase() !== 'cashier') {
      return jsonResponse(
        {
          error:
            'Forbidden: Only CASHIER accounts can be provisioned from the application UI.',
        },
        403,
      );
    }

    if (action === 'list_cashiers') {
      const { data: profiles, error } = await adminClient
        .from('profiles')
        .select(
          'id, email, full_name, phone, role, status, communication_mode, created_at, updated_at, disabled_at',
        )
        .eq('role', 'cashier')
        .order('created_at', { ascending: false });

      if (error) {
        throw new HttpError(500, 'Failed to fetch cashier profiles.');
      }

      const { data: orderCounts } = await adminClient
        .from('cafe_orders')
        .select('cashier_id, order_id, grand_total, payment_status')
        .not('cashier_id', 'is', null);

      const statsByCashier: Record<
        string,
        { ordersProcessed: number; totalHandledSales: number }
      > = {};
      for (const row of orderCounts ?? []) {
        const cid = String(row.cashier_id ?? '');
        if (!cid) continue;
        if (!statsByCashier[cid]) {
          statsByCashier[cid] = { ordersProcessed: 0, totalHandledSales: 0 };
        }
        statsByCashier[cid].ordersProcessed += 1;
        if (row.payment_status === 'paid') {
          statsByCashier[cid].totalHandledSales += Number(row.grand_total ?? 0);
        }
      }

      const enriched = await Promise.all(
        (profiles ?? []).map(async (p) => {
          const { data: authUser } = await adminClient.auth.admin.getUserById(
            p.id,
          );
          return {
            ...p,
            email_confirmed_at: authUser?.user?.email_confirmed_at ?? null,
            last_sign_in_at: authUser?.user?.last_sign_in_at ?? null,
            orders_processed: statsByCashier[p.id]?.ordersProcessed ?? 0,
            total_handled_sales: statsByCashier[p.id]?.totalHandledSales ?? 0,
          };
        }),
      );

      return jsonResponse({ cashiers: enriched });
    }

    if (action === 'invite_cashier') {
      const email = String(body.email ?? '')
        .trim()
        .toLowerCase();
      const fullName = String(body.full_name ?? '').trim();
      const phone = body.phone ? String(body.phone).trim() : null;

      if (!email || !email.includes('@') || !fullName) {
        return jsonResponse(
          { error: 'Valid email and full_name are required.' },
          400,
        );
      }

      const { data: inviteData, error: inviteErr } =
        await adminClient.auth.admin.inviteUserByEmail(email, {
          data: {
            full_name: fullName,
            phone,
          },
        });

      if (inviteErr || !inviteData?.user) {
        return jsonResponse(
          { error: inviteErr?.message ?? 'Failed to invite cashier.' },
          400,
        );
      }

      const cashierUserId = inviteData.user.id;

      await adminClient.auth.admin.updateUserById(cashierUserId, {
        app_metadata: {
          app_role: 'cashier',
          account_status: 'active',
        },
      });

      const { data: savedProfile, error: upsertErr } = await adminClient
        .from('profiles')
        .upsert(
          {
            id: cashierUserId,
            email,
            full_name: fullName,
            phone,
            role: 'cashier',
            status: 'active',
            invited_by: actor.userId,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'id' },
        )
        .select()
        .single();

      if (upsertErr) {
        throw new HttpError(500, 'Failed to save cashier profile.');
      }

      await adminClient.from('audit_logs').insert({
        actor_id: actor.userId,
        actor_role: actor.role,
        actor_name: actor.fullName,
        action: 'cashier_invited',
        entity_type: 'profiles',
        entity_id: cashierUserId,
        before_data: null,
        after_data: {
          email,
          full_name: fullName,
          role: 'cashier',
          status: 'active',
        },
        status: 'success',
      });

      return jsonResponse({ cashier: savedProfile }, 201);
    }

    if (action === 'set_cashier_status') {
      const cashierId = String(body.cashier_id ?? '').trim();
      const targetStatus = String(body.status ?? '').trim();
      const reason = String(body.reason ?? '').trim();

      if (!cashierId || !['active', 'disabled'].includes(targetStatus)) {
        return jsonResponse(
          { error: 'cashier_id and valid status (active|disabled) required.' },
          400,
        );
      }

      const { data: existing, error: fetchErr } = await adminClient
        .from('profiles')
        .select('id, email, full_name, role, status')
        .eq('id', cashierId)
        .single();

      if (fetchErr || !existing) {
        return jsonResponse({ error: 'Cashier account not found.' }, 404);
      }

      if (existing.role !== 'cashier') {
        return jsonResponse(
          { error: 'Forbidden: Target user is not a CASHIER account.' },
          403,
        );
      }

      const isDisabling = targetStatus === 'disabled';

      // Ban at Auth level + update app_metadata so token refresh & sign-in are immediately blocked
      await adminClient.auth.admin.updateUserById(cashierId, {
        ban_duration: isDisabling ? '876000h' : 'none',
        app_metadata: {
          app_role: 'cashier',
          account_status: targetStatus,
        },
      });

      if (isDisabling) {
        try {
          await adminClient.auth.admin.signOut(cashierId);
        } catch (_) {
          // Best-effort session revocation; RLS + Realtime profile stream also enforce instant lockout
        }
      }

      const { data: updatedProfile, error: updateErr } = await adminClient
        .from('profiles')
        .update({
          status: targetStatus,
          disabled_at: isDisabling ? new Date().toISOString() : null,
          disabled_by: isDisabling ? actor.userId : null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', cashierId)
        .select()
        .single();

      if (updateErr) {
        throw new HttpError(500, 'Failed to update cashier status.');
      }

      await adminClient.from('audit_logs').insert({
        actor_id: actor.userId,
        actor_role: actor.role,
        actor_name: actor.fullName,
        action: isDisabling ? 'cashier_disabled' : 'cashier_activated',
        entity_type: 'profiles',
        entity_id: cashierId,
        before_data: { status: existing.status },
        after_data: { status: targetStatus, reason },
        status: 'success',
      });

      return jsonResponse({ cashier: updatedProfile });
    }

    return jsonResponse({ error: `Unsupported action: ${action}` }, 400);
  } catch (err) {
    if (err instanceof HttpError) {
      return jsonResponse({ error: err.message }, err.status);
    }
    return jsonResponse({ error: 'Internal server error.' }, 500);
  }
});
