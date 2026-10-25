# Audit notes and limitations

## What was preserved

The input was the latest user Library file `renew of index html` (493,633 bytes), not a blank rewrite. Its existing modules and routing remain in `index.html`; the output adds a Connects page, routing/loader entries, purchase history, server-side application quote display, insufficient-balance path, and a Connects-aware application submit handler.

## Static checks performed

- Extracted the inline executable JavaScript blocks and ran `node --check` on them successfully after the edits.
- Inspected the source SQL schema for the existing `jobs`, `profiles`, and `applications` objects and the `choose_worker` status transition (`hired` / `not_selected`).
- Added the Connects-specific SQL as a separate migration rather than appending it to the 241 KB legacy schema script.
- The migration uses a unique purchase reference, a ledger, a row lock, server-computed package/pricing values, provider API verification, webhook signature validation, and an idempotent database credit operation.

## Not tested / not certified

- The migration was not executed against the live Supabase database; schema/permission conflicts with the live installation remain possible.
- The TypeScript function was not compiled by Deno/Supabase CLI here and no real Paystack test payment/webhook was run.
- The existing codebase is large and accumulated over multiple iterations. A successful JavaScript syntax check does not prove every screen, RPC, RLS policy, storage bucket, or payment path works at runtime.
- The legacy SQL contains older broad grants/functions and existing wallet/deposit/withdrawal paths that need a separate full security review against the actual live schema. This package does not certify those unrelated money-moving flows.
- Connects packages currently seed ₦100 per Connect and configurable example application tiers. The migration uses `ON CONFLICT DO NOTHING` for seeds so re-running it does not overwrite later admin edits; changing prices must be deliberate and reviewed.
- The Connects pilot is NGN-only. Although the broader product direction is international, country-specific price schedules, currency/payment routing and country eligibility are not implemented in this Connects slice.
- Referral tracking/rewards were discussed, but final reward values and eligibility/fraud rules were not approved. This package does not issue referral rewards.
- The Connects migration does not implement a hold/release escrow for the full job payment. Do not advertise payment protection, escrow, guaranteed refund, or deferred Paystack settlement based on this package.

## Important permission change

`connects_migration.sql` revokes all direct privileges on `public.applications` from `public`, `anon`, and `authenticated`, then grants authenticated users read-only access. The included front end reads applications directly but uses RPCs for state changes. Check your actual production integrations and any scripts/admin tools before applying this permission change.
