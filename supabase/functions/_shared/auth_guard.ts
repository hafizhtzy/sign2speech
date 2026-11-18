import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

export interface VerifiedActor {
  userId: string;
  email: string;
  fullName: string;
  role: 'customer' | 'cashier' | 'admin';
  status: 'active' | 'disabled' | 'invited';
}

export interface AuthGuardContext {
  actor: VerifiedActor;
  adminClient: SupabaseClient;
}

/**
 * Verifies the caller's Bearer JWT and inspects `public.profiles` directly
 * using the server-side service_role client so disabled accounts or stale JWTs
 * are rejected immediately.
 */
export async function requireActiveRole(
  req: Request,
  allowedRoles: Array<'customer' | 'cashier' | 'admin'>,
): Promise<AuthGuardContext> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    throw new HttpError(500, 'Server configuration incomplete.');
  }

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    throw new HttpError(401, 'Missing or invalid Authorization Bearer token.');
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData?.user) {
    throw new HttpError(401, 'Invalid or expired authentication token.');
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: profile, error: profileErr } = await adminClient
    .from('profiles')
    .select('id, email, full_name, role, status')
    .eq('id', userData.user.id)
    .single();

  if (profileErr || !profile) {
    throw new HttpError(403, 'User profile not found.');
  }

  if (profile.status !== 'active') {
    throw new HttpError(403, 'Account is disabled or inactive.');
  }

  const role = profile.role as 'customer' | 'cashier' | 'admin';
  if (!allowedRoles.includes(role)) {
    throw new HttpError(
      403,
      `Forbidden: role '${role}' is not permitted to perform this operation.`,
    );
  }

  return {
    actor: {
      userId: profile.id,
      email: profile.email ?? userData.user.email ?? '',
      fullName: profile.full_name ?? '',
      role,
      status: profile.status,
    },
    adminClient,
  };
}

export class HttpError extends Error {
  readonly status: number;
  constructor(status: number, message: string) {
    super(message);
    this.status = status;
  }
}

export async function sha256Hex(input: string): Promise<string> {
  const bytes = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-256', bytes);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

export async function sha512Hex(input: string): Promise<string> {
  const bytes = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest('SHA-512', bytes);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
