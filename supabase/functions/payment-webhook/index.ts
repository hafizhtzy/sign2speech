import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { sha256Hex, sha512Hex } from '../_shared/auth_guard.ts';

function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'Server configuration incomplete.' }, 500);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const rawBody = await req.text();
  const payloadSha256 = await sha256Hex(rawBody);

  let body: Record<string, unknown>;
  try {
    body = JSON.parse(rawBody);
  } catch (_) {
    return jsonResponse({ error: 'Invalid JSON payload.' }, 400);
  }

  const orderId = String(body.order_id ?? '').trim();
  const transactionId = String(body.transaction_id ?? '').trim();
  const transactionStatus = String(body.transaction_status ?? '')
    .trim()
    .toLowerCase();
  const statusCode = String(body.status_code ?? '').trim();
  const grossAmount = String(body.gross_amount ?? '').trim();
  const fraudStatus = String(body.fraud_status ?? 'accept')
    .trim()
    .toLowerCase();
  const signatureKey = String(body.signature_key ?? '')
    .trim()
    .toLowerCase();

  if (!orderId || !transactionStatus) {
    return jsonResponse(
      { error: 'order_id and transaction_status are required.' },
      400,
    );
  }

  const { data: payment, error: payErr } = await adminClient
    .from('payments')
    .select('*')
    .or(`midtrans_order_id.eq.${orderId},order_id.eq.${orderId}`)
    .maybeSingle();

  if (payErr || !payment) {
    return jsonResponse({ error: 'Matching payment record not found.' }, 404);
  }

  const midtransServerKey = Deno.env.get('MIDTRANS_SERVER_KEY') ?? '';
  const isProduction =
    (Deno.env.get('MIDTRANS_IS_PRODUCTION') ?? 'false').toLowerCase() ===
    'true';
  const appEnv = (Deno.env.get('APP_ENV') ?? 'development').toLowerCase();
  const allowSimulator =
    (Deno.env.get('ALLOW_SANDBOX_SIMULATOR') ?? 'false').toLowerCase() ===
    'true';
  const simulatorSecret = Deno.env.get('SANDBOX_WEBHOOK_SECRET') ?? '';
  const headerSimulatorSecret =
    req.headers.get('x-sandbox-simulator-secret') ?? '';

  const isSimulatorRequest = Boolean(headerSimulatorSecret);

  if (isSimulatorRequest) {
    // Hard gate: Simulator webhook is strictly forbidden in production or against real Midtrans payments
    if (
      isProduction ||
      !['development', 'staging'].includes(appEnv) ||
      !allowSimulator ||
      !simulatorSecret ||
      !timingSafeEqualHex(headerSimulatorSecret, simulatorSecret)
    ) {
      return jsonResponse(
        { error: 'Forbidden: Sandbox simulator webhook is not permitted.' },
        403,
      );
    }

    if (!payment.is_simulation || payment.provider !== 'sandbox_simulator') {
      return jsonResponse(
        {
          error:
            'Security violation: Simulator webhook cannot settle a real gateway payment.',
        },
        403,
      );
    }
  } else {
    // Official Midtrans Webhook Signature Verification:
    // SHA512(order_id + status_code + gross_amount + ServerKey)
    if (!midtransServerKey || !signatureKey || !statusCode || !grossAmount) {
      return jsonResponse(
        { error: 'Unauthorized: Missing Midtrans signature parameters.' },
        401,
      );
    }

    const expectedSig = (
      await sha512Hex(
        `${orderId}${statusCode}${grossAmount}${midtransServerKey}`,
      )
    ).toLowerCase();

    if (!timingSafeEqualHex(signatureKey, expectedSig)) {
      return jsonResponse(
        { error: 'Unauthorized: Invalid Midtrans webhook signature.' },
        401,
      );
    }
  }

  // Composite deduplication key from actual Midtrans attributes (does not rely on a separate event_id)
  const dedupKey = `${
    transactionId || orderId
  }:${orderId}:${transactionStatus}:${statusCode}:${grossAmount}`;

  const sanitizedPayload = {
    order_id: orderId,
    transaction_id: transactionId,
    transaction_status: transactionStatus,
    fraud_status: fraudStatus,
    status_code: statusCode,
    gross_amount: grossAmount,
    payment_type: body.payment_type ?? 'qris',
    acquirer: body.acquirer ?? null,
    settlement_time: body.settlement_time ?? null,
  };

  if (
    transactionStatus === 'settlement' ||
    (transactionStatus === 'capture' && fraudStatus === 'accept')
  ) {
    const { data: rpcRes, error: rpcErr } = await adminClient.rpc(
      'rpc_finalize_payment_stock',
      {
        p_payment_id: payment.id,
        p_dedup_key: dedupKey,
        p_payload_sha256: payloadSha256,
        p_midtrans_transaction_id:
          transactionId || payment.midtrans_transaction_id,
        p_midtrans_order_id: orderId,
        p_transaction_status: transactionStatus,
        p_fraud_status: fraudStatus,
        p_status_code: statusCode || '200',
        p_signature_verified: true,
        p_is_simulation: isSimulatorRequest,
        p_payload_sanitized: sanitizedPayload,
      },
    );

    if (rpcErr) {
      return jsonResponse({ error: rpcErr.message }, 409);
    }

    return jsonResponse({ result: rpcRes });
  }

  if (['expire', 'cancel', 'deny'].includes(transactionStatus)) {
    const targetStatus =
      transactionStatus === 'expire'
        ? 'expired'
        : transactionStatus === 'cancel'
        ? 'cancelled'
        : 'failed';

    await adminClient.from('payment_events').upsert(
      {
        payment_id: payment.id,
        dedup_key: dedupKey,
        payload_sha256: payloadSha256,
        midtrans_transaction_id: transactionId || null,
        midtrans_order_id: orderId,
        transaction_status: transactionStatus,
        fraud_status: fraudStatus,
        status_code: statusCode || null,
        signature_verified: true,
        is_simulation: isSimulatorRequest,
        payload_sanitized: sanitizedPayload,
      },
      { onConflict: 'dedup_key' },
    );

    const { data: releaseRes, error: releaseErr } = await adminClient.rpc(
      'rpc_release_stock_reservation',
      {
        p_order_id: payment.order_id,
        p_target_status: targetStatus,
        p_reason: `Midtrans webhook status: ${transactionStatus}`,
      },
    );

    if (releaseErr) {
      return jsonResponse({ error: releaseErr.message }, 409);
    }

    return jsonResponse({ result: releaseRes });
  }

  return jsonResponse({ status: 'ignored', transaction_status: transactionStatus });
});
