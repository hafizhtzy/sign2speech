import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { HttpError, requireActiveRole } from '../_shared/auth_guard.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { actor, adminClient } = await requireActiveRole(req, ['admin']);
    const body = await req.json();

    const orderId = String(body.order_id ?? '').trim();
    const amount = Number(body.amount ?? 0);
    const reason = String(body.reason ?? '').trim();
    const restockItems = Boolean(body.restock_items ?? false);

    if (!orderId || amount <= 0 || reason.length < 3) {
      return jsonResponse(
        {
          error:
            'order_id, positive amount, and reason (min 3 chars) are required.',
        },
        400,
      );
    }

    const { data: order, error: orderErr } = await adminClient
      .from('cafe_orders')
      .select('*')
      .eq('order_id', orderId)
      .single();

    if (orderErr || !order) {
      return jsonResponse({ error: 'Order not found.' }, 404);
    }

    if (!['paid', 'partially_refunded'].includes(order.payment_status)) {
      return jsonResponse(
        { error: 'Only paid orders can be refunded.' },
        409,
      );
    }

    const { data: payment, error: payErr } = await adminClient
      .from('payments')
      .select('*')
      .eq('order_id', orderId)
      .eq('status', 'paid')
      .maybeSingle();

    if (payErr || !payment) {
      return jsonResponse({ error: 'Paid payment record not found.' }, 404);
    }

    const { data: existingRefunds } = await adminClient
      .from('refunds')
      .select('amount')
      .eq('order_id', orderId)
      .eq('status', 'completed');

    const alreadyRefunded = (existingRefunds ?? []).reduce(
      (sum, r) => sum + Number(r.amount ?? 0),
      0,
    );

    if (alreadyRefunded + amount > Number(order.grand_total)) {
      return jsonResponse(
        { error: 'Refund amount exceeds remaining refundable order total.' },
        400,
      );
    }

    const { data: refundRow, error: refundErr } = await adminClient
      .from('refunds')
      .insert({
        order_id: orderId,
        payment_id: payment.id,
        amount,
        reason,
        restock_items: restockItems,
        status: 'completed',
        requested_by: actor.userId,
        approved_by: actor.userId,
        completed_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (refundErr) {
      throw new HttpError(500, 'Failed to record refund.');
    }

    const newPaymentStatus =
      alreadyRefunded + amount >= Number(order.grand_total)
        ? 'refunded'
        : 'partially_refunded';

    await adminClient
      .from('cafe_orders')
      .update({
        payment_status: newPaymentStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('order_id', orderId);

    if (newPaymentStatus === 'refunded') {
      await adminClient
        .from('payments')
        .update({ status: 'refunded', updated_at: new Date().toISOString() })
        .eq('id', payment.id);
    }

    if (restockItems) {
      const { data: items } = await adminClient
        .from('cafe_order_items')
        .select('product_id, quantity')
        .eq('order_id', orderId);

      for (const item of items ?? []) {
        await adminClient.rpc('rpc_admin_adjust_stock', {
          p_product_id: item.product_id,
          p_movement_type: 'adjustment_in',
          p_quantity_delta: Number(item.quantity),
          p_reason: `Restock dari refund pesanan ${orderId}: ${reason}`,
          p_reference_id: refundRow.id,
        });
      }
    }

    await adminClient.from('audit_logs').insert({
      actor_id: actor.userId,
      actor_role: actor.role,
      actor_name: actor.fullName,
      action: 'order_refunded',
      entity_type: 'cafe_orders',
      entity_id: orderId,
      before_data: { payment_status: order.payment_status },
      after_data: {
        payment_status: newPaymentStatus,
        refund_amount: amount,
        reason,
      },
      status: 'success',
    });

    return jsonResponse({
      refund: refundRow,
      payment_status: newPaymentStatus,
    });
  } catch (err) {
    if (err instanceof HttpError) {
      return jsonResponse({ error: err.message }, err.status);
    }
    return jsonResponse({ error: 'Internal server error.' }, 500);
  }
});
