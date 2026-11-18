import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { HttpError, requireActiveRole } from '../_shared/auth_guard.ts';

interface MidtransAction {
  name?: string;
  method?: string;
  url?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { actor, adminClient } = await requireActiveRole(req, [
      'customer',
      'cashier',
      'admin',
    ]);
    const body = await req.json();
    const orderId = String(body.order_id ?? '').trim();

    if (!orderId) {
      return jsonResponse({ error: 'order_id is required.' }, 400);
    }

    const { data: order, error: orderErr } = await adminClient
      .from('cafe_orders')
      .select(
        'order_id, customer_id, grand_total, payment_method, payment_status, status, expires_at',
      )
      .eq('order_id', orderId)
      .single();

    if (orderErr || !order) {
      return jsonResponse({ error: 'Order not found.' }, 404);
    }

    if (actor.role === 'customer' && order.customer_id !== actor.userId) {
      return jsonResponse(
        { error: 'Forbidden: You do not own this order.' },
        403,
      );
    }

    if (order.payment_method !== 'qris') {
      return jsonResponse({ error: 'Order payment_method is not qris.' }, 400);
    }

    if (order.payment_status === 'paid') {
      return jsonResponse({ error: 'Order is already paid.' }, 409);
    }

    // Return existing pending QRIS payment if already created (idempotent)
    const { data: existingPayment } = await adminClient
      .from('payments')
      .select('*')
      .eq('order_id', orderId)
      .eq('status', 'pending')
      .maybeSingle();

    if (existingPayment) {
      return jsonResponse({ payment: existingPayment });
    }

    const midtransServerKey = Deno.env.get('MIDTRANS_SERVER_KEY') ?? '';
    const isProduction =
      (Deno.env.get('MIDTRANS_IS_PRODUCTION') ?? 'false').toLowerCase() ===
      'true';
    const appEnv = (Deno.env.get('APP_ENV') ?? 'development').toLowerCase();
    const allowSimulator =
      (Deno.env.get('ALLOW_SANDBOX_SIMULATOR') ?? 'true').toLowerCase() ===
      'true';

    const grossAmount = Number(order.grand_total);
    const idempotencyKey = `qris:${orderId}`;

    // Path A: Official Midtrans Core API v2 QRIS Charge
    if (midtransServerKey) {
      const baseUrl = isProduction
        ? 'https://api.midtrans.com'
        : 'https://api.sandbox.midtrans.com';
      const basicAuth = btoa(`${midtransServerKey}:`);

      const chargePayload = {
        payment_type: 'qris',
        transaction_details: {
          order_id: orderId,
          gross_amount: grossAmount,
        },
        qris: {
          acquirer: 'gopay',
        },
      };

      const midtransResp = await fetch(`${baseUrl}/v2/charge`, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          Authorization: `Basic ${basicAuth}`,
          'Idempotency-Key': idempotencyKey,
        },
        body: JSON.stringify(chargePayload),
      });

      const midtransJson = await midtransResp.json();
      const statusCode = String(midtransJson.status_code ?? '');
      if (!midtransResp.ok || !['200', '201'].includes(statusCode)) {
        return jsonResponse(
          {
            error:
              midtransJson.status_message ??
              'Midtrans QRIS charge creation failed.',
          },
          502,
        );
      }

      // Extract QR code URL from Midtrans Core API `actions` array
      // (generate-qr-code-v2 or generate-qr-code) without assuming qr_string always exists.
      const actions: MidtransAction[] = Array.isArray(midtransJson.actions)
        ? midtransJson.actions
        : [];
      const qrAction =
        actions.find((a) => a.name === 'generate-qr-code-v2') ??
        actions.find((a) => a.name === 'generate-qr-code');

      const qrCodeUrl = qrAction?.url ?? null;
      const qrString =
        typeof midtransJson.qr_string === 'string' &&
        midtransJson.qr_string.length > 0
          ? midtransJson.qr_string
          : null;
      const expiryTime = midtransJson.expiry_time
        ? new Date(String(midtransJson.expiry_time)).toISOString()
        : order.expires_at ??
          new Date(Date.now() + 15 * 60 * 1000).toISOString();

      const { data: savedPayment, error: insertErr } = await adminClient
        .from('payments')
        .insert({
          order_id: orderId,
          provider: 'midtrans',
          is_simulation: false,
          payment_method: 'qris',
          midtrans_order_id: String(midtransJson.order_id ?? orderId),
          midtrans_transaction_id: midtransJson.transaction_id
            ? String(midtransJson.transaction_id)
            : null,
          idempotency_key: idempotencyKey,
          gross_amount: grossAmount,
          status: 'pending',
          qr_string: qrString,
          qr_code_url: qrCodeUrl,
          qris_actions: actions,
          acquirer: String(midtransJson.acquirer ?? 'gopay'),
          expires_at: expiryTime,
          created_by: actor.userId,
        })
        .select()
        .single();

      if (insertErr) {
        throw new HttpError(500, 'Failed to store Midtrans payment record.');
      }

      return jsonResponse({ payment: savedPayment }, 201);
    }

    // Path B: Controlled Non-Production Sandbox Simulator (Strictly blocked in production)
    if (
      !isProduction &&
      ['development', 'staging'].includes(appEnv) &&
      allowSimulator
    ) {
      const simTxId = `SIM-TX-${crypto.randomUUID()}`;
      const expiryTime =
        order.expires_at ?? new Date(Date.now() + 15 * 60 * 1000).toISOString();

      const { data: simPayment, error: simErr } = await adminClient
        .from('payments')
        .insert({
          order_id: orderId,
          provider: 'sandbox_simulator',
          is_simulation: true,
          payment_method: 'qris',
          midtrans_order_id: orderId,
          midtrans_transaction_id: simTxId,
          idempotency_key: idempotencyKey,
          gross_amount: grossAmount,
          status: 'pending',
          qr_string: `00020101021226580014ID.CO.SIGN2SPEECH.SIM011893600914${orderId}520458125303360540${grossAmount}5802ID5911SIGN2SPEECH6007JAKARTA6304SIM0`,
          qr_code_url: null,
          qris_actions: [],
          acquirer: 'sandbox_simulator',
          expires_at: expiryTime,
          created_by: actor.userId,
        })
        .select()
        .single();

      if (simErr) {
        throw new HttpError(500, 'Failed to create sandbox simulator payment.');
      }

      return jsonResponse({ payment: simPayment }, 201);
    }

    return jsonResponse(
      {
        error:
          'QRIS payment gateway is not configured and simulator is disabled in production.',
      },
      503,
    );
  } catch (err) {
    if (err instanceof HttpError) {
      return jsonResponse({ error: err.message }, err.status);
    }
    return jsonResponse({ error: 'Internal server error.' }, 500);
  }
});
