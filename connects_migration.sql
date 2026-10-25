-- MAVORA CONNECTS: additive migration for the current MAVORA V2 schema.
-- Run only after the existing MAVORA core schema has been installed.
-- This file does not delete or replace user/job/payment data.
-- NGN-only pilot; package/application prices are provisional and configurable.

begin;
create extension if not exists pgcrypto;

-- One available balance for each account. Connects are separate from the cash wallet.
create table if not exists public.mavora_connects_wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.mavora_connects_packages (
  connects integer primary key check (connects > 0),
  amount_minor bigint not null check (amount_minor > 0),
  currency text not null default 'NGN' check (currency = 'NGN'),
  active boolean not null default true,
  updated_at timestamptz not null default now()
);

-- Price tiers are provisional defaults based on previously discussed examples.
-- Edit these values in Supabase after reviewing costs, customer fairness, and provider fees.
create table if not exists public.mavora_connects_cost_rules (
  id bigserial primary key,
  min_budget numeric not null check (min_budget >= 0),
  max_budget numeric,
  connects_cost integer not null check (connects_cost > 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (max_budget is null or max_budget >= min_budget),
  unique(min_budget)
);

create table if not exists public.mavora_connects_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reference text not null unique,
  provider_reference text,
  connects integer not null check (connects > 0),
  amount_minor bigint not null check (amount_minor > 0),
  currency text not null default 'NGN' check (currency = 'NGN'),
  status text not null default 'pending' check (status in ('pending','paid','failed')),
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.mavora_connects_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  delta_connects integer not null,
  entry_type text not null check (entry_type in ('purchase','reserve','consume','refund','referral','admin_adjustment')),
  reference text,
  application_id uuid references public.applications(id) on delete set null,
  purchase_id uuid references public.mavora_connects_purchases(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create unique index if not exists mavora_connects_ledger_idempotency_idx
  on public.mavora_connects_ledger(user_id, entry_type, reference)
  where reference is not null;
create index if not exists mavora_connects_ledger_user_time_idx
  on public.mavora_connects_ledger(user_id, created_at desc);
create index if not exists mavora_connects_purchases_user_time_idx
  on public.mavora_connects_purchases(user_id, created_at desc);

-- One reservation per application. Credits are deducted at application time,
-- consumed if selected, or refunded to eligible unselected/withdrawn applications.
create table if not exists public.mavora_connects_reservations (
  id uuid primary key default gen_random_uuid(),
  application_id uuid unique references public.applications(id) on delete set null,
  user_id uuid not null references public.profiles(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  connects integer not null check (connects > 0),
  status text not null default 'reserved' check (status in ('reserved','consumed','refunded')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists mavora_connects_reservation_job_idx
  on public.mavora_connects_reservations(job_id, status);

-- Provisional price packs: 1 Connect = ₦100. amount_minor is kobo (₦1 = 100 kobo).
insert into public.mavora_connects_packages(connects, amount_minor, currency, active)
values (1,10000,'NGN',true),(3,30000,'NGN',true),(5,50000,'NGN',true),
       (10,100000,'NGN',true),(20,200000,'NGN',true),(50,500000,'NGN',true),
       (100,1000000,'NGN',true),(500,5000000,'NGN',true)
on conflict (connects) do nothing;

-- Provisional suggested application costs. Budget is treated as NGN for this pilot.
insert into public.mavora_connects_cost_rules(min_budget,max_budget,connects_cost,active)
values (0,5000.01,2,true),(5000.01,20000.01,4,true),(20000.01,50000.01,7,true),
       (50000.01,100000.01,10,true),(100000.01,250000.01,15,true),(250000.01,null,20,true)
on conflict (min_budget) do nothing;

-- Seed wallets for accounts that already exist. No free Connects are assumed/granted.
insert into public.mavora_connects_wallets(user_id)
select p.id from public.profiles p
on conflict (user_id) do nothing;

create or replace function public.mavora_connects_seed_wallet()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.mavora_connects_wallets(user_id) values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;
revoke all on function public.mavora_connects_seed_wallet() from public, anon, authenticated;
drop trigger if exists mavora_connects_seed_wallet on public.profiles;
create trigger mavora_connects_seed_wallet
after insert on public.profiles
for each row execute function public.mavora_connects_seed_wallet();

-- Publicly readable catalogue; no direct client writes to packs/rules.
alter table public.mavora_connects_packages enable row level security;
revoke all on public.mavora_connects_packages from public, anon, authenticated;
grant select on public.mavora_connects_packages to anon, authenticated;
drop policy if exists mavora_connects_packages_read_active on public.mavora_connects_packages;
create policy mavora_connects_packages_read_active on public.mavora_connects_packages
for select to anon, authenticated using (active = true);

alter table public.mavora_connects_wallets enable row level security;
revoke all on public.mavora_connects_wallets from public, anon, authenticated;
grant select on public.mavora_connects_wallets to authenticated;
drop policy if exists mavora_connects_wallets_read_own on public.mavora_connects_wallets;
create policy mavora_connects_wallets_read_own on public.mavora_connects_wallets
for select to authenticated using (user_id = auth.uid());

alter table public.mavora_connects_purchases enable row level security;
revoke all on public.mavora_connects_purchases from public, anon, authenticated;
grant select on public.mavora_connects_purchases to authenticated;
drop policy if exists mavora_connects_purchases_read_own on public.mavora_connects_purchases;
create policy mavora_connects_purchases_read_own on public.mavora_connects_purchases
for select to authenticated using (user_id = auth.uid());

alter table public.mavora_connects_ledger enable row level security;
revoke all on public.mavora_connects_ledger from public, anon, authenticated;
grant select on public.mavora_connects_ledger to authenticated;
drop policy if exists mavora_connects_ledger_read_own on public.mavora_connects_ledger;
create policy mavora_connects_ledger_read_own on public.mavora_connects_ledger
for select to authenticated using (user_id = auth.uid());

alter table public.mavora_connects_reservations enable row level security;
revoke all on public.mavora_connects_reservations from public, anon, authenticated;
grant select on public.mavora_connects_reservations to authenticated;
drop policy if exists mavora_connects_reservations_read_own on public.mavora_connects_reservations;
create policy mavora_connects_reservations_read_own on public.mavora_connects_reservations
for select to authenticated using (user_id = auth.uid());

-- Price rules are server-side configuration, not a browser-editable catalogue.
alter table public.mavora_connects_cost_rules enable row level security;
revoke all privileges on public.mavora_connects_cost_rules from public, anon, authenticated;

-- Applications must go through server-side RPCs so a browser cannot bypass Connects
-- or self-edit status to manufacture a refund. Existing UI reads rows but uses RPCs
-- for application/edit/withdraw/hire/work state transitions.
revoke all privileges on table public.applications from public, anon, authenticated;
grant select on table public.applications to authenticated;

-- Returns a server-computed quote and current balance. Never accept the cost from the browser.
create or replace function public.mavora_connects_quote_for_job(p_job_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job public.jobs%rowtype;
  v_cost integer;
  v_balance integer;
begin
  if auth.uid() is null then return jsonb_build_object('success',false,'reason','not_authenticated','message','Please log in first.'); end if;
  select * into v_job from public.jobs where id=p_job_id;
  if not found or v_job.status <> 'open' then return jsonb_build_object('success',false,'reason','job_unavailable','message','This job is not open for applications.'); end if;
  if v_job.client_id = auth.uid() then return jsonb_build_object('success',false,'reason','own_job','message','You cannot apply to your own job.'); end if;
  select connects_cost into v_cost from public.mavora_connects_cost_rules
    where active and min_budget <= coalesce(v_job.budget,0) and (max_budget is null or coalesce(v_job.budget,0) < max_budget)
    order by min_budget desc limit 1;
  if v_cost is null then return jsonb_build_object('success',false,'reason','pricing_unconfigured','message','Application pricing is not configured for this budget.'); end if;
  insert into public.mavora_connects_wallets(user_id) values (auth.uid()) on conflict (user_id) do nothing;
  select balance into v_balance from public.mavora_connects_wallets where user_id=auth.uid();
  return jsonb_build_object('success',true,'job_id',p_job_id,'required_connects',v_cost,'balance',coalesce(v_balance,0),'shortfall',greatest(v_cost-coalesce(v_balance,0),0),'affordable',coalesce(v_balance,0)>=v_cost,'currency','NGN');
end;
$$;
revoke all on function public.mavora_connects_quote_for_job(uuid) from public, anon;
grant execute on function public.mavora_connects_quote_for_job(uuid) to authenticated;

-- Atomic application + Connects reservation. The browser cannot select the price/cost.
create or replace function public.mavora_apply_for_job_with_connects(
  p_job_id uuid,
  p_proposed_price numeric,
  p_proposal text,
  p_delivery_time text default null,
  p_questions text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_job public.jobs%rowtype;
  v_cost integer;
  v_balance integer;
  v_app_id uuid;
  v_reference text;
begin
  if auth.uid() is null then return jsonb_build_object('success',false,'reason','not_authenticated','message','Please log in first.'); end if;
  if p_proposed_price is null or p_proposed_price < 0 then return jsonb_build_object('success',false,'reason','invalid_price','message','Enter a valid proposed price.'); end if;
  if length(trim(coalesce(p_proposal,''))) = 0 or length(p_proposal) > 12000 then return jsonb_build_object('success',false,'reason','invalid_proposal','message','Enter a proposal (up to 12,000 characters).'); end if;

  select * into v_job from public.jobs where id=p_job_id for update;
  if not found or v_job.status <> 'open' then return jsonb_build_object('success',false,'reason','job_unavailable','message','This job is not open for applications.'); end if;
  if v_job.client_id = auth.uid() then return jsonb_build_object('success',false,'reason','own_job','message','You cannot apply to your own job.'); end if;

  select connects_cost into v_cost from public.mavora_connects_cost_rules
    where active and min_budget <= coalesce(v_job.budget,0) and (max_budget is null or coalesce(v_job.budget,0) < max_budget)
    order by min_budget desc limit 1;
  if v_cost is null then return jsonb_build_object('success',false,'reason','pricing_unconfigured','message','Application pricing is not configured for this budget.'); end if;

  insert into public.mavora_connects_wallets(user_id) values(auth.uid()) on conflict(user_id) do nothing;
  select balance into v_balance from public.mavora_connects_wallets where user_id=auth.uid() for update;
  if coalesce(v_balance,0) < v_cost then
    return jsonb_build_object('success',false,'reason','insufficient_connects','required_connects',v_cost,'balance',coalesce(v_balance,0),'shortfall',v_cost-coalesce(v_balance,0),'message','Not enough Connects to apply.');
  end if;

  begin
    insert into public.applications(job_id,worker_id,proposed_price,proposal,delivery_time,questions)
    values(p_job_id,auth.uid(),p_proposed_price,trim(p_proposal),nullif(trim(coalesce(p_delivery_time,'')),''),nullif(trim(coalesce(p_questions,'')),''))
    returning id into v_app_id;
  exception when unique_violation then
    return jsonb_build_object('success',false,'reason','already_applied','message','You have already applied for this job.');
  end;

  update public.mavora_connects_wallets set balance=balance-v_cost,updated_at=now() where user_id=auth.uid();
  v_reference := 'APP-'||v_app_id::text;
  insert into public.mavora_connects_reservations(application_id,user_id,job_id,connects,status)
  values(v_app_id,auth.uid(),p_job_id,v_cost,'reserved');
  insert into public.mavora_connects_ledger(user_id,delta_connects,entry_type,reference,application_id,metadata)
  values(auth.uid(),-v_cost,'reserve',v_reference,v_app_id,jsonb_build_object('job_id',p_job_id,'connects',v_cost));

  return jsonb_build_object('success',true,'application_id',v_app_id,'connects_reserved',v_cost,'balance_remaining',v_balance-v_cost);
end;
$$;
revoke all on function public.mavora_apply_for_job_with_connects(uuid,numeric,text,text,text) from public, anon;
grant execute on function public.mavora_apply_for_job_with_connects(uuid,numeric,text,text,text) to authenticated;

-- Keep the legacy RPC from being a Connects bypass for callers using an old page or API client.
create or replace function public.apply_for_job(p_job_id uuid,p_proposed_price numeric,p_proposal text,p_delivery_time text default null,p_questions text default null)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_result jsonb;
begin
  v_result := public.mavora_apply_for_job_with_connects(p_job_id,p_proposed_price,p_proposal,p_delivery_time,p_questions);
  if coalesce((v_result->>'success')::boolean,false) is not true then
    raise exception '%',coalesce(v_result->>'message','Application could not be submitted.');
  end if;
  return (v_result->>'application_id')::uuid;
end;
$$;
revoke all on function public.apply_for_job(uuid,numeric,text,text,text) from public, anon;
grant execute on function public.apply_for_job(uuid,numeric,text,text,text) to authenticated;

-- Reconcile reservations when a client selects/doesn't select applicants or a worker withdraws.
create or replace function public.mavora_connects_settle_application_reservation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_res public.mavora_connects_reservations%rowtype;
  v_ref text;
begin
  if old.status is not distinct from new.status then return new; end if;
  select * into v_res from public.mavora_connects_reservations where application_id=new.id for update;
  if not found or v_res.status <> 'reserved' then return new; end if;

  if new.status='hired' then
    update public.mavora_connects_reservations set status='consumed',updated_at=now() where id=v_res.id;
    insert into public.mavora_connects_ledger(user_id,delta_connects,entry_type,reference,application_id,metadata)
    values(v_res.user_id,0,'consume','APP-'||new.id::text,new.id,jsonb_build_object('connects',v_res.connects,'job_id',v_res.job_id))
    on conflict (user_id,entry_type,reference) where reference is not null do nothing;
  elsif new.status in ('not_selected','withdrawn','rejected','cancelled','job_closed') then
    update public.mavora_connects_wallets set balance=balance+v_res.connects,updated_at=now() where user_id=v_res.user_id;
    update public.mavora_connects_reservations set status='refunded',updated_at=now() where id=v_res.id;
    v_ref := 'APP-'||new.id::text;
    insert into public.mavora_connects_ledger(user_id,delta_connects,entry_type,reference,application_id,metadata)
    values(v_res.user_id,v_res.connects,'refund',v_ref,new.id,jsonb_build_object('connects',v_res.connects,'job_id',v_res.job_id,'reason',new.status))
    on conflict (user_id,entry_type,reference) where reference is not null do nothing;
  end if;
  return new;
end;
$$;
revoke all on function public.mavora_connects_settle_application_reservation() from public, anon, authenticated;
drop trigger if exists mavora_connects_settle_application_reservation on public.applications;
create trigger mavora_connects_settle_application_reservation
after update of status on public.applications
for each row execute function public.mavora_connects_settle_application_reservation();

-- Handle deleted applications safely. A still-reserved charge is returned first.
create or replace function public.mavora_connects_refund_deleted_application()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_res public.mavora_connects_reservations%rowtype;
begin
  select * into v_res from public.mavora_connects_reservations where application_id=old.id for update;
  if found and v_res.status='reserved' then
    update public.mavora_connects_wallets set balance=balance+v_res.connects,updated_at=now() where user_id=v_res.user_id;
    update public.mavora_connects_reservations set status='refunded',updated_at=now(),application_id=null where id=v_res.id;
    insert into public.mavora_connects_ledger(user_id,delta_connects,entry_type,reference,metadata)
    values(v_res.user_id,v_res.connects,'refund','APP-DELETE-'||old.id::text,jsonb_build_object('connects',v_res.connects,'job_id',v_res.job_id,'reason','application_deleted'))
    on conflict (user_id,entry_type,reference) where reference is not null do nothing;
  end if;
  return old;
end;
$$;
revoke all on function public.mavora_connects_refund_deleted_application() from public, anon, authenticated;
drop trigger if exists mavora_connects_refund_deleted_application on public.applications;
create trigger mavora_connects_refund_deleted_application
before delete on public.applications
for each row execute function public.mavora_connects_refund_deleted_application();

-- Closing a job before selection returns the reserved Connects for its pending applicants.
create or replace function public.mavora_connects_refund_on_job_close()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if old.status is distinct from new.status and new.status in ('closed','cancelled','expired') and old.status='open' then
    update public.applications set status='not_selected',updated_at=now()
      where job_id=new.id and status='pending';
  end if;
  return new;
end;
$$;
revoke all on function public.mavora_connects_refund_on_job_close() from public, anon, authenticated;
drop trigger if exists mavora_connects_refund_on_job_close on public.jobs;
create trigger mavora_connects_refund_on_job_close
after update of status on public.jobs
for each row execute function public.mavora_connects_refund_on_job_close();

-- Server-side Paystack confirmation; only service_role may call this function.
-- The Edge Function must verify Paystack's transaction API response and webhook signature first.
create or replace function public.mavora_confirm_connects_purchase(
  p_reference text,
  p_provider_reference text,
  p_amount_minor bigint,
  p_currency text
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_purchase public.mavora_connects_purchases%rowtype;
  v_new_balance integer;
begin
  if coalesce(auth.role(),'') <> 'service_role' then raise exception 'Service role required'; end if;
  select * into v_purchase from public.mavora_connects_purchases where reference=p_reference for update;
  if not found then raise exception 'Connects purchase reference not found'; end if;
  if v_purchase.status='paid' then
    select balance into v_new_balance from public.mavora_connects_wallets where user_id=v_purchase.user_id;
    return jsonb_build_object('success',true,'already_credited',true,'connects',v_purchase.connects,'balance',coalesce(v_new_balance,0));
  end if;
  if v_purchase.status <> 'pending' then raise exception 'Connects purchase is not pending'; end if;
  if p_amount_minor is distinct from v_purchase.amount_minor or upper(coalesce(p_currency,'')) <> v_purchase.currency then
    raise exception 'Verified Paystack amount/currency does not match the purchase';
  end if;

  insert into public.mavora_connects_wallets(user_id) values(v_purchase.user_id) on conflict(user_id) do nothing;
  update public.mavora_connects_purchases
    set status='paid',provider_reference=p_provider_reference,paid_at=now(),updated_at=now()
    where id=v_purchase.id;
  update public.mavora_connects_wallets
    set balance=balance+v_purchase.connects,updated_at=now()
    where user_id=v_purchase.user_id
    returning balance into v_new_balance;
  insert into public.mavora_connects_ledger(user_id,delta_connects,entry_type,reference,purchase_id,metadata)
    values(v_purchase.user_id,v_purchase.connects,'purchase',v_purchase.reference,v_purchase.id,
           jsonb_build_object('amount_minor',v_purchase.amount_minor,'currency',v_purchase.currency,'provider_reference',p_provider_reference));
  return jsonb_build_object('success',true,'already_credited',false,'connects',v_purchase.connects,'balance',v_new_balance);
end;
$$;
revoke all on function public.mavora_confirm_connects_purchase(text,text,bigint,text) from public, anon, authenticated;
grant execute on function public.mavora_confirm_connects_purchase(text,text,bigint,text) to service_role;

commit;

-- IMPORTANT POST-MIGRATION CHECKS:
-- 1. Confirm RLS is enabled on all mavora_connects_* tables.
-- 2. Confirm only service_role can insert/update purchases and credit via the confirmation RPC.
-- 3. Run a test payment in Paystack test mode; do not use live money until the provider approves this model.
-- 4. Application cost rules and packages above are provisional. Confirm them before production.
