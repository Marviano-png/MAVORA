# MAVORA — current website source + Connects payment module

This package preserves the latest `renew of index html` website as the starting point. It does **not** restart MAVORA from a blank template. It adds the Connects purchase/application flow discussed most recently.

## Files

- `index.html` — current full front-end source, including the existing MAVORA features and the added Connects UI.
- `connects_migration.sql` — additive database migration for Connects balances, package catalogue, purchase ledger, application reservations, refund/consume events, RPCs, and application-table permissions.
- `supabase/functions/mavora-connects/index.ts` — Supabase Edge Function for authenticated Paystack checkout, payment verification, signature-verified Paystack webhook events, and server-side Connects crediting.
- `supabase/config.toml` — tells Supabase to permit the payment provider's webhook request to reach the function. The handler then verifies the webhook signature and authenticates ordinary user requests itself.
- `reference_existing_core_schema_DO_NOT_RERUN_BLINDLY.sql` — the existing core SQL file included only as a reference for schema context. **Do not execute it again just because it is in this package.**
- `AUDIT_NOTES.md` — what was checked and what remains unverified.
- `TEST_CHECKLIST.md` — an ordered staging test plan.

## Important status

This is the best-effort continuation of the current codebase, not a claim that every MAVORA idea discussed across all chats is finished or production-certified. The front-end JavaScript syntax was checked locally. The SQL has **not** been run against your live Supabase project, and the Paystack test flow has **not** been executed from this environment.

The Connects implementation is intentionally a Nigeria/NGN pilot. The confirmed pricing idea was **1 Connect = ₦100**; the application-cost tiers are provisional examples and must be reviewed before you rely on them. Referral reward amounts/eligibility and full country-by-country pricing/payment support were not finalized, so they are not silently activated here.

## Deploy safely

### 1. Make backups first

1. Download a copy of the current GitHub Pages repository and preserve its present `index.html`.
2. In Supabase, take a database backup/export before changing permissions or running a migration.
3. Review the existing live database schema and confirm the `profiles`, `jobs`, and `applications` tables match this project. The migration relies on those existing tables.

### 2. Apply the Connects migration once

Open the Supabase SQL Editor for the MAVORA project and run `connects_migration.sql` **after** the existing core schema is already installed.

This is an additive migration. It creates Connects tables/RPCs, adds a profile trigger for new Connects wallets, protects pricing/ledger tables, and restricts direct browser writes to `applications` so an application cannot bypass the Connects RPC. Since that last step changes database permissions, do not run it until you have a backup and have checked that all required application edits/hiring/work-state operations use the existing secured RPCs.

Do not run `reference_existing_core_schema_DO_NOT_RERUN_BLINDLY.sql` as part of this step. It is included for reference, not as the new migration.

### 3. Configure the Supabase Function secrets

From the `MAVORA_Complete_Package` directory, or through Supabase Dashboard → Edge Functions → Secrets, set:

```sh
supabase secrets set PAYSTACK_SECRET_KEY="sk_test_REPLACE_WITH_YOUR_TEST_SECRET" MAVORA_SITE_URL="https://marviano-png.github.io/MAVORA/" --project-ref nyxymywtsiwsidgmhszq
```

Use your real **test** secret in the test environment; the placeholder above is not a usable key. Do not put any Paystack secret or Supabase service-role key into `index.html`, GitHub, screenshots, or messages. Supabase supplies its standard project URL/keys to hosted Edge Functions; do not place secret keys in browser code.

### 4. Deploy the function

Install/use the Supabase CLI, log in, then run from this package folder:

```sh
supabase functions deploy mavora-connects --project-ref nyxymywtsiwsidgmhszq
```

The included `supabase/config.toml` has `verify_jwt = false` for this function because Paystack's webhook does not carry a Supabase user JWT. The function manually authenticates user checkout/verification requests and requires Paystack's HMAC-SHA512 signature on webhook requests. Keep those checks intact.

### 5. Configure the Paystack test webhook

In the **Paystack test-mode** dashboard, set the webhook URL to:

```text
https://nyxymywtsiwsidgmhszq.supabase.co/functions/v1/mavora-connects
```

Enable the `charge.success` event. The Edge Function verifies the signature and independently asks Paystack to verify the transaction before it credits Connects. Browser redirects alone do not credit Connects.

### 6. Publish the front end

Replace the repository's existing `index.html` with this package's `index.html` and publish your GitHub Pages site as you normally do. Keep the existing Supabase project URL/key configuration already in the source. Do not publish secret keys.

## How Connects should work in testing

- User opens **MAVORA Connects**, chooses an active package, and checks out through Paystack.
- The Edge Function stores a pending purchase before asking Paystack to initialize checkout.
- A verified callback or signed webhook asks Paystack's API to confirm status, amount, currency, and reference.
- The service-role-only database RPC credits the Connects once. Repeated webhook/callback events should not duplicate credit.
- Before an application is created, the database computes its Connects cost from the job budget and checks the account balance under lock.
- Connects are reserved during application. A selected (`hired`) application consumes the reservation; eligible not-selected/withdrawn/rejected/cancelled applications and applications on a closed job are refunded according to the migration's state transitions.

## Before accepting live payments

Do not switch from Paystack test mode until Paystack has approved the registered business and this exact Connects sale/marketplace model in writing, the account is live-enabled, refund/dispute terms are published, and successful/failed/duplicate/concurrent payment tests have passed. This Connects purchase flow does not create a licensed escrow service and does not certify the site's existing wallet deposits, job payments, balance settlement, or withdrawals.
