# MAVORA staging checklist

Run these checks against a staging/test environment, not the live payment account.

## Database and navigation

- [ ] Back up the database and current website first.
- [ ] Apply `connects_migration.sql` once after confirming the core schema.
- [ ] Confirm new users and existing profiles have a zero-balance Connects wallet.
- [ ] Confirm anonymous users cannot read balances, purchase history, or ledger entries.
- [ ] Confirm users can only read their own wallet/history/ledger rows.
- [ ] Confirm authenticated clients cannot insert/update/delete applications directly.
- [ ] Confirm `show('connects')` opens the page, balance loads, and package prices reflect the package table.

## Purchase flow (Paystack test mode)

- [ ] Confirm a user with a verified email can start checkout.
- [ ] Confirm an unverified-email account is prevented from buying.
- [ ] Confirm an inactive or unknown package cannot be purchased.
- [ ] Complete a successful test payment and confirm Connects are credited by the verified backend.
- [ ] Replay the same webhook/reference and verify the account is not credited twice.
- [ ] Verify failed/cancelled payment attempts do not add Connects.
- [ ] Tamper with amount/currency/reference in a test-only request and confirm it cannot credit Connects.
- [ ] Confirm purchase history shows the correct amount, status and reference.

## Application flow and reservation settlement

- [ ] With zero Connects, open a job application and verify the cost and shortfall are shown.
- [ ] Confirm the insufficient-balance path opens the Connects purchase page and creates no application.
- [ ] Buy enough Connects; submit a valid application and confirm the exact server-calculated cost is reserved once.
- [ ] Apply twice to the same job and confirm the duplicate application does not deduct more Connects.
- [ ] Submit applications concurrently on separate jobs and confirm the balance never drops below zero.
- [ ] Confirm the selected (`hired`) application consumes its reserved Connects.
- [ ] Confirm unselected applicants receive one refund each.
- [ ] Confirm withdrawal or closing/cancelling/expiring an eligible open job refunds reserved Connects once.
- [ ] Confirm a second status update does not create a second refund.

## Operational verification

- [ ] Check Supabase Function logs for failed initialization, webhook, and verification requests.
- [ ] Check Paystack test dashboard events and compare each successful transaction with the internal purchase reference/amount/currency.
- [ ] Confirm no secret key appears in public HTML, GitHub, browser logs, or the repository.
- [ ] Obtain written Paystack approval and complete all business/live readiness checks before live mode.
