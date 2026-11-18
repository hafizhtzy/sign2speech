#!/usr/bin/env node
/**
 * Trusted Server-Side Admin Provisioning Script for Sign2Speech Addendum V3.
 *
 * Usage (by project owner only, using server-side .env.server.secret):
 *   node supabase/scripts/provision_admin.mjs --email admin@sign2speech.id --name "Admin Utama" --password "<StrongInitialPassword>"
 *
 * Security Rules:
 * - Reads SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY from environment or .env.server.secret.
 * - Never prints or logs secret keys or passwords.
 * - Never bundled into the Flutter application.
 */

import fs from 'node:fs';
import path from 'node:path';

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  const map = {};
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eqIdx = trimmed.indexOf('=');
    if (eqIdx <= 0) continue;
    const key = trimmed.slice(0, eqIdx).trim();
    const val = trimmed.slice(eqIdx + 1).trim().replace(/^['"]|['"]$/g, '');
    map[key] = val;
  }
  return map;
}

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const token = argv[i];
    if (token.startsWith('--')) {
      const key = token.slice(2);
      const val = argv[i + 1] && !argv[i + 1].startsWith('--') ? argv[++i] : 'true';
      args[key] = val;
    }
  }
  return args;
}

async function main() {
  const rootDir = process.cwd();
  const envPublic = loadEnvFile(path.join(rootDir, '.env'));
  const envSecret = loadEnvFile(path.join(rootDir, '.env.server.secret'));

  const supabaseUrl =
    process.env.SUPABASE_URL || envSecret.SUPABASE_URL || envPublic.SUPABASE_URL;
  const serviceRoleKey =
    process.env.SUPABASE_SERVICE_ROLE_KEY || envSecret.SUPABASE_SERVICE_ROLE_KEY;

  if (!supabaseUrl || !serviceRoleKey) {
    console.error(
      'ERROR: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in .env.server.secret or environment.',
    );
    process.exit(1);
  }

  const args = parseArgs(process.argv);
  const email = (args.email || '').trim().toLowerCase();
  const fullName = (args.name || 'Admin Sign2Speech').trim();
  const password = args.password || '';

  if (!email || !email.includes('@') || password.length < 8) {
    console.error(
      'Usage: node supabase/scripts/provision_admin.mjs --email <email> --name "<Full Name>" --password <min-8-chars>',
    );
    process.exit(1);
  }

  const headers = {
    apikey: serviceRoleKey,
    Authorization: `Bearer ${serviceRoleKey}`,
    'Content-Type': 'application/json',
  };

  // Create or update user via Supabase Auth Admin REST API
  const createResp = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName },
      app_metadata: { app_role: 'admin', account_status: 'active' },
    }),
  });

  const createJson = await createResp.json();
  if (!createResp.ok || !createJson.id) {
    console.error(
      'Failed to provision auth user:',
      createJson.msg || createJson.message || createResp.status,
    );
    process.exit(1);
  }

  const userId = createJson.id;

  // Upsert authoritative profile row with role = 'admin'
  const profileResp = await fetch(
    `${supabaseUrl}/rest/v1/profiles?on_conflict=id`,
    {
      method: 'POST',
      headers: {
        ...headers,
        Prefer: 'resolution=merge-duplicates,return=representation',
      },
      body: JSON.stringify({
        id: userId,
        email,
        full_name: fullName,
        role: 'admin',
        status: 'active',
        updated_at: new Date().toISOString(),
      }),
    },
  );

  if (!profileResp.ok) {
    console.error('Failed to upsert public.profiles row for ADMIN.');
    process.exit(1);
  }

  await fetch(`${supabaseUrl}/rest/v1/audit_logs`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      actor_id: userId,
      actor_role: 'admin',
      actor_name: fullName,
      action: 'trusted_admin_provisioned',
      entity_type: 'profiles',
      entity_id: userId,
      after_data: { email, full_name: fullName, role: 'admin', status: 'active' },
      status: 'success',
    }),
  });

  console.log(`SUCCESS: Provisioned ADMIN account for ${email} (id: ${userId}).`);
}

main().catch((err) => {
  console.error('Unexpected provisioning error:', err.message);
  process.exit(1);
});
