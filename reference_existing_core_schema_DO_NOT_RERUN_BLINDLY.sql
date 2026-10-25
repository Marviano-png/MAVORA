-- ============================================================
-- MAVORA CORRECTED MASTER SUPABASE SQL
-- Based on the current MAVORA_MASTER_SUPABASE.sql in the Library.
-- Corrected to be rerunnable when existing RLS policies are already present.
-- IMPORTANT: This script does NOT delete tables, rows, users, wallets, jobs,
-- or other MAVORA data. It only replaces policies with the same names.
-- Run this corrected file instead of the previous master SQL.
-- No API keys or payment secrets belong in this file.
-- ============================================================

-- ============================================================
-- MAVORA MASTER SUPABASE SQL
-- Consolidated from the latest MAVORA backend pieces + KYC review addon.
-- Safe/additive where possible. Does not contain API keys or secrets.
-- Run as ONE script in Supabase SQL Editor.
-- ============================================================

-- MAVORA V2 production-oriented foundation.
-- Run in Supabase SQL Editor. Review names against any existing schema before production migration.
-- NEVER put a Supabase service-role key or payment secret in the HTML.

create extension if not exists pgcrypto;

-- ============================================================
-- FUNCTION SIGNATURE COMPATIBILITY RESET
-- PostgreSQL cannot change a function return type with
-- CREATE OR REPLACE FUNCTION. Older MAVORA migrations created
-- these two functions with different return types. Drop only
-- those old function signatures before recreating the final ones.
-- No MAVORA tables, rows, users, wallets, jobs, messages,
-- payments, or other stored data are deleted by these statements.
-- ============================================================
drop function if exists public.choose_worker(uuid,uuid);
drop function if exists public.change_job_status(uuid,text);


create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  username text unique,
  professional_title text,
  skills text,
  about text,
  state text,
  lga text,
  city text,
  area text,
  availability text default 'available',
  service_radius_km numeric,
  nearby_enabled boolean default false,
  role text default 'user',
  identity_status text default 'not_verified',
  rating numeric default 0,
  completed_jobs integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.profiles.
alter table public.profiles add column if not exists id uuid default gen_random_uuid();
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists full_name text;
alter table public.profiles add column if not exists username text;
alter table public.profiles add column if not exists professional_title text;
alter table public.profiles add column if not exists skills text;
alter table public.profiles add column if not exists about text;
alter table public.profiles add column if not exists state text;
alter table public.profiles add column if not exists lga text;
alter table public.profiles add column if not exists city text;
alter table public.profiles add column if not exists area text;
alter table public.profiles add column if not exists availability text;
alter table public.profiles add column if not exists service_radius_km numeric default 0;
alter table public.profiles add column if not exists nearby_enabled boolean default false;
alter table public.profiles add column if not exists role text;
alter table public.profiles add column if not exists identity_status text;
alter table public.profiles add column if not exists rating numeric default 0;
alter table public.profiles add column if not exists completed_jobs integer default 0;
alter table public.profiles add column if not exists created_at timestamptz default now();
alter table public.profiles add column if not exists updated_at timestamptz default now();


create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null,
  category text,
  budget numeric not null default 0 check (budget >= 0),
  job_mode text default 'Remote',
  experience_level text default 'Any level',
  state text,
  lga text,
  city text,
  area text,
  delivery_details text,
  deadline timestamptz,
  visibility text default 'public',
  status text default 'open',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.jobs.
alter table public.jobs add column if not exists id uuid default gen_random_uuid();
alter table public.jobs add column if not exists client_id uuid;
alter table public.jobs add column if not exists title text;
alter table public.jobs add column if not exists description text;
alter table public.jobs add column if not exists category text;
alter table public.jobs add column if not exists budget numeric default 0;
alter table public.jobs add column if not exists job_mode text;
alter table public.jobs add column if not exists experience_level text;
alter table public.jobs add column if not exists state text;
alter table public.jobs add column if not exists lga text;
alter table public.jobs add column if not exists city text;
alter table public.jobs add column if not exists area text;
alter table public.jobs add column if not exists delivery_details text;
alter table public.jobs add column if not exists deadline timestamptz default now();
alter table public.jobs add column if not exists visibility text;
alter table public.jobs add column if not exists status text;
alter table public.jobs add column if not exists created_at timestamptz default now();
alter table public.jobs add column if not exists updated_at timestamptz default now();


create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  worker_id uuid not null references public.profiles(id) on delete cascade,
  proposed_price numeric not null default 0 check (proposed_price >= 0),
  proposal text,
  delivery_time text,
  questions text,
  status text default 'pending',
  work_status text default 'not_started',
  work_submission text,
  submitted_at timestamptz,
  revision_note text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(job_id,worker_id)
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.applications.
alter table public.applications add column if not exists id uuid default gen_random_uuid();
alter table public.applications add column if not exists job_id uuid;
alter table public.applications add column if not exists worker_id uuid;
alter table public.applications add column if not exists proposed_price numeric default 0;
alter table public.applications add column if not exists proposal text;
alter table public.applications add column if not exists delivery_time text;
alter table public.applications add column if not exists questions text;
alter table public.applications add column if not exists status text;
alter table public.applications add column if not exists work_status text;
alter table public.applications add column if not exists work_submission text;
alter table public.applications add column if not exists submitted_at timestamptz default now();
alter table public.applications add column if not exists revision_note text;
alter table public.applications add column if not exists created_at timestamptz default now();
alter table public.applications add column if not exists updated_at timestamptz default now();


create table if not exists public.contracts (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  application_id uuid unique references public.applications(id) on delete set null,
  client_id uuid not null references public.profiles(id),
  worker_id uuid not null references public.profiles(id),
  agreed_price numeric not null default 0,
  start_at timestamptz,
  deadline timestamptz,
  status text default 'pending',
  terms_snapshot jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.contracts.
alter table public.contracts add column if not exists id uuid default gen_random_uuid();
alter table public.contracts add column if not exists job_id uuid;
alter table public.contracts add column if not exists application_id uuid;
alter table public.contracts add column if not exists client_id uuid;
alter table public.contracts add column if not exists worker_id uuid;
alter table public.contracts add column if not exists agreed_price numeric default 0;
alter table public.contracts add column if not exists start_at timestamptz default now();
alter table public.contracts add column if not exists deadline timestamptz default now();
alter table public.contracts add column if not exists status text;
alter table public.contracts add column if not exists terms_snapshot jsonb default '{}'::jsonb;
alter table public.contracts add column if not exists created_at timestamptz default now();
alter table public.contracts add column if not exists updated_at timestamptz default now();


create table if not exists public.work_files (
  id uuid primary key default gen_random_uuid(),
  application_id uuid not null references public.applications(id) on delete cascade,
  uploader_id uuid not null references public.profiles(id) on delete cascade,
  file_path text not null,
  file_name text,
  mime_type text,
  size_bytes bigint,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.work_files.
alter table public.work_files add column if not exists id uuid default gen_random_uuid();
alter table public.work_files add column if not exists application_id uuid;
alter table public.work_files add column if not exists uploader_id uuid;
alter table public.work_files add column if not exists file_path text;
alter table public.work_files add column if not exists file_name text;
alter table public.work_files add column if not exists mime_type text;
alter table public.work_files add column if not exists size_bytes bigint default 0;
alter table public.work_files add column if not exists created_at timestamptz default now();


create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete set null,
  contract_id uuid references public.contracts(id) on delete set null,
  message text not null check (length(message) between 1 and 5000),
  is_read boolean default false,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.messages.
alter table public.messages add column if not exists id uuid default gen_random_uuid();
alter table public.messages add column if not exists sender_id uuid;
alter table public.messages add column if not exists recipient_id uuid;
alter table public.messages add column if not exists job_id uuid;
alter table public.messages add column if not exists contract_id uuid;
alter table public.messages add column if not exists message text;
alter table public.messages add column if not exists is_read boolean default false;
alter table public.messages add column if not exists created_at timestamptz default now();


create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text,
  message text not null,
  type text,
  is_read boolean default false,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.notifications.
alter table public.notifications add column if not exists id uuid default gen_random_uuid();
alter table public.notifications add column if not exists user_id uuid;
alter table public.notifications add column if not exists title text;
alter table public.notifications add column if not exists message text;
alter table public.notifications add column if not exists type text;
alter table public.notifications add column if not exists is_read boolean default false;
alter table public.notifications add column if not exists created_at timestamptz default now();
alter table public.notifications add column if not exists target_page text;
alter table public.notifications add column if not exists target_id uuid;
alter table public.notifications add column if not exists data jsonb default '{}'::jsonb;


create table if not exists public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  available_balance numeric not null default 0 check (available_balance >= 0),
  pending_balance numeric not null default 0 check (pending_balance >= 0),
  held_balance numeric not null default 0 check (held_balance >= 0),
  spending_balance numeric not null default 0 check (spending_balance >= 0),
  currency text default 'NGN',
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.wallets.
alter table public.wallets add column if not exists user_id uuid;
alter table public.wallets add column if not exists available_balance numeric default 0;
alter table public.wallets add column if not exists pending_balance numeric default 0;
alter table public.wallets add column if not exists held_balance numeric default 0;
alter table public.wallets add column if not exists spending_balance numeric default 0;
alter table public.wallets add column if not exists currency text;
alter table public.wallets add column if not exists updated_at timestamptz default now();


create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  amount numeric not null check (amount >= 0),
  status text not null default 'pending',
  reference text unique,
  provider text,
  provider_reference text,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.transactions.
alter table public.transactions add column if not exists id uuid default gen_random_uuid();
alter table public.transactions add column if not exists user_id uuid;
alter table public.transactions add column if not exists type text;
alter table public.transactions add column if not exists amount numeric default 0;
alter table public.transactions add column if not exists status text;
alter table public.transactions add column if not exists reference text;
alter table public.transactions add column if not exists provider text;
alter table public.transactions add column if not exists provider_reference text;
alter table public.transactions add column if not exists metadata jsonb default '{}'::jsonb;
alter table public.transactions add column if not exists created_at timestamptz default now();
alter table public.transactions add column if not exists updated_at timestamptz default now();


create table if not exists public.withdrawals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric not null check (amount > 0),
  status text default 'pending',
  bank_reference text,
  provider text,
  provider_reference text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.withdrawals.
alter table public.withdrawals add column if not exists id uuid default gen_random_uuid();
alter table public.withdrawals add column if not exists user_id uuid;
alter table public.withdrawals add column if not exists amount numeric default 0;
alter table public.withdrawals add column if not exists status text;
alter table public.withdrawals add column if not exists bank_reference text;
alter table public.withdrawals add column if not exists provider text;
alter table public.withdrawals add column if not exists provider_reference text;
alter table public.withdrawals add column if not exists created_at timestamptz default now();
alter table public.withdrawals add column if not exists updated_at timestamptz default now();


create table if not exists public.saved_jobs (
  user_id uuid references public.profiles(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  created_at timestamptz default now(),
  primary key(user_id,job_id)
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.saved_jobs.
alter table public.saved_jobs add column if not exists user_id uuid;
alter table public.saved_jobs add column if not exists job_id uuid;
alter table public.saved_jobs add column if not exists created_at timestamptz default now();


create table if not exists public.saved_searches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  name text,
  query text,
  filters jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.saved_searches.
alter table public.saved_searches add column if not exists id uuid default gen_random_uuid();
alter table public.saved_searches add column if not exists user_id uuid;
alter table public.saved_searches add column if not exists name text;
alter table public.saved_searches add column if not exists query text;
alter table public.saved_searches add column if not exists filters jsonb default '{}'::jsonb;
alter table public.saved_searches add column if not exists created_at timestamptz default now();


create table if not exists public.revision_requests (
  id uuid primary key default gen_random_uuid(),
  application_id uuid references public.applications(id) on delete cascade,
  requester_id uuid references public.profiles(id) on delete cascade,
  note text not null,
  status text default 'open',
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.revision_requests.
alter table public.revision_requests add column if not exists id uuid default gen_random_uuid();
alter table public.revision_requests add column if not exists application_id uuid;
alter table public.revision_requests add column if not exists requester_id uuid;
alter table public.revision_requests add column if not exists note text;
alter table public.revision_requests add column if not exists status text;
alter table public.revision_requests add column if not exists created_at timestamptz default now();


create table if not exists public.disputes (
  id uuid primary key default gen_random_uuid(),
  application_id uuid references public.applications(id) on delete cascade,
  opened_by uuid references public.profiles(id) on delete cascade,
  reason text not null,
  status text default 'open',
  resolution text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.disputes.
alter table public.disputes add column if not exists id uuid default gen_random_uuid();
alter table public.disputes add column if not exists application_id uuid;
alter table public.disputes add column if not exists opened_by uuid;
alter table public.disputes add column if not exists reason text;
alter table public.disputes add column if not exists status text;
alter table public.disputes add column if not exists resolution text;
alter table public.disputes add column if not exists created_at timestamptz default now();
alter table public.disputes add column if not exists updated_at timestamptz default now();


create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references public.profiles(id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  reason text not null,
  status text default 'open',
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.reports.
alter table public.reports add column if not exists id uuid default gen_random_uuid();
alter table public.reports add column if not exists reporter_id uuid;
alter table public.reports add column if not exists target_type text;
alter table public.reports add column if not exists target_id uuid;
alter table public.reports add column if not exists reason text;
alter table public.reports add column if not exists status text;
alter table public.reports add column if not exists created_at timestamptz default now();


create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  type text,
  subject text not null,
  message text not null,
  status text default 'open',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.support_tickets.
alter table public.support_tickets add column if not exists id uuid default gen_random_uuid();
alter table public.support_tickets add column if not exists user_id uuid;
alter table public.support_tickets add column if not exists type text;
alter table public.support_tickets add column if not exists subject text;
alter table public.support_tickets add column if not exists message text;
alter table public.support_tickets add column if not exists status text;
alter table public.support_tickets add column if not exists created_at timestamptz default now();
alter table public.support_tickets add column if not exists updated_at timestamptz default now();


-- Helpful indexes
create index if not exists idx_jobs_client on public.jobs(client_id);
create index if not exists idx_jobs_status on public.jobs(status);
create index if not exists idx_jobs_state on public.jobs(state);
create index if not exists idx_jobs_created on public.jobs(created_at desc);
create index if not exists idx_applications_job on public.applications(job_id);
create index if not exists idx_applications_worker on public.applications(worker_id);
create index if not exists idx_messages_sender on public.messages(sender_id);
create index if not exists idx_messages_recipient on public.messages(recipient_id);
create index if not exists idx_notifications_user on public.notifications(user_id,created_at desc);
create index if not exists idx_transactions_user on public.transactions(user_id,created_at desc);

-- Profile auto-creation. This avoids client-side dependence on a profile row existing first.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,email,full_name,username)
  values(new.id,new.email,new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'username')
  on conflict(id) do update set email=excluded.email;
  insert into public.wallets(user_id) values(new.id) on conflict(user_id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.applications enable row level security;
alter table public.contracts enable row level security;
alter table public.work_files enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.wallets enable row level security;
alter table public.transactions enable row level security;
alter table public.withdrawals enable row level security;
alter table public.saved_jobs enable row level security;
alter table public.saved_searches enable row level security;
alter table public.revision_requests enable row level security;
alter table public.disputes enable row level security;
alter table public.reports enable row level security;
alter table public.support_tickets enable row level security;

-- Recreate simple user policies safely.
drop policy if exists profiles_select_public on public.profiles;
create policy profiles_select_public on public.profiles for select to authenticated using (true);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles for insert to authenticated with check (id=auth.uid());

drop policy if exists jobs_select_open on public.jobs;
create policy jobs_select_open on public.jobs for select to authenticated using (status='open' or client_id=auth.uid());
drop policy if exists jobs_insert_own on public.jobs;
create policy jobs_insert_own on public.jobs for insert to authenticated with check (client_id=auth.uid());
drop policy if exists jobs_update_own on public.jobs;
create policy jobs_update_own on public.jobs for update to authenticated using (client_id=auth.uid()) with check (client_id=auth.uid());

drop policy if exists applications_select_related on public.applications;
create policy applications_select_related on public.applications for select to authenticated using (worker_id=auth.uid() or exists(select 1 from public.jobs j where j.id=job_id and j.client_id=auth.uid()));
drop policy if exists applications_insert_own on public.applications;
create policy applications_insert_own on public.applications for insert to authenticated with check (worker_id=auth.uid());

drop policy if exists contracts_select_related on public.contracts;
create policy contracts_select_related on public.contracts for select to authenticated using (client_id=auth.uid() or worker_id=auth.uid());

drop policy if exists work_files_select_related on public.work_files;
create policy work_files_select_related on public.work_files for select to authenticated using (uploader_id=auth.uid() or exists(select 1 from public.applications a join public.jobs j on j.id=a.job_id where a.id=application_id and (a.worker_id=auth.uid() or j.client_id=auth.uid())));
drop policy if exists work_files_insert_own on public.work_files;
create policy work_files_insert_own on public.work_files for insert to authenticated with check (uploader_id=auth.uid());

-- Messages: only sender/recipient can see; sender must be current user on insert.
drop policy if exists messages_select_related on public.messages;
create policy messages_select_related on public.messages for select to authenticated using (sender_id=auth.uid() or recipient_id=auth.uid());
drop policy if exists messages_insert_sender on public.messages;
create policy messages_insert_sender on public.messages for insert to authenticated with check (sender_id=auth.uid());

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications for select to authenticated using (user_id=auth.uid());
drop policy if exists notifications_update_own on public.notifications;
create policy notifications_update_own on public.notifications for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());

-- Financial tables: users can read their own records, but balances/statuses must not be directly writable from the browser.
drop policy if exists wallets_select_own on public.wallets;
create policy wallets_select_own on public.wallets for select to authenticated using (user_id=auth.uid());
drop policy if exists transactions_select_own on public.transactions;
create policy transactions_select_own on public.transactions for select to authenticated using (user_id=auth.uid());
drop policy if exists withdrawals_select_own on public.withdrawals;
create policy withdrawals_select_own on public.withdrawals for select to authenticated using (user_id=auth.uid());

-- Saved jobs/searches
drop policy if exists saved_jobs_all_own on public.saved_jobs;
create policy saved_jobs_all_own on public.saved_jobs for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists saved_searches_all_own on public.saved_searches;
create policy saved_searches_all_own on public.saved_searches for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

-- Support/report/dispute requests
drop policy if exists reports_insert_own on public.reports;
create policy reports_insert_own on public.reports for insert to authenticated with check(reporter_id=auth.uid());
drop policy if exists reports_select_own on public.reports;
create policy reports_select_own on public.reports for select to authenticated using(reporter_id=auth.uid());
drop policy if exists support_insert_own on public.support_tickets;
create policy support_insert_own on public.support_tickets for insert to authenticated with check(user_id=auth.uid());
drop policy if exists support_select_own on public.support_tickets;
create policy support_select_own on public.support_tickets for select to authenticated using(user_id=auth.uid());
drop policy if exists disputes_select_related on public.disputes;
create policy disputes_select_related on public.disputes for select to authenticated using(opened_by=auth.uid() or exists(select 1 from public.applications a join public.jobs j on j.id=a.job_id where a.id=application_id and (a.worker_id=auth.uid() or j.client_id=auth.uid())));
drop policy if exists disputes_insert_own on public.disputes;
create policy disputes_insert_own on public.disputes for insert to authenticated with check(opened_by=auth.uid());
drop policy if exists revision_insert_own on public.revision_requests;
create policy revision_insert_own on public.revision_requests for insert to authenticated with check(requester_id=auth.uid());
drop policy if exists revision_select_related on public.revision_requests;
create policy revision_select_related on public.revision_requests for select to authenticated using(requester_id=auth.uid() or exists(select 1 from public.applications a join public.jobs j on j.id=a.job_id where a.id=application_id and (a.worker_id=auth.uid() or j.client_id=auth.uid())));

-- Secure profile save RPC fixes the previous browser permission problem without granting broad table writes.
create or replace function public.save_my_profile(p_profile jsonb)
returns void language plpgsql security definer set search_path=public as $$
begin
  if (p_profile->>'id')::uuid <> auth.uid() then raise exception 'not allowed'; end if;
  update public.profiles set
    full_name=coalesce(p_profile->>'full_name',full_name),
    username=nullif(p_profile->>'username',''),
    professional_title=p_profile->>'professional_title',skills=p_profile->>'skills',about=p_profile->>'about',
    state=p_profile->>'state',lga=p_profile->>'lga',city=p_profile->>'city',area=p_profile->>'area',
    availability=coalesce(p_profile->>'availability',availability),
    service_radius_km=nullif(p_profile->>'service_radius_km','')::numeric,
    nearby_enabled=coalesce((p_profile->>'nearby_enabled')::boolean,false),updated_at=now()
  where id=auth.uid();
end; $$;
grant execute on function public.save_my_profile(jsonb) to authenticated;

-- Application RPC with duplicate prevention and ownership checks.
create or replace function public.apply_for_job(p_job_id uuid,p_proposed_price numeric,p_proposal text,p_delivery_time text default null,p_questions text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if not exists(select 1 from public.jobs where id=p_job_id and status='open') then raise exception 'job is not open'; end if;
  insert into public.applications(job_id,worker_id,proposed_price,proposal,delivery_time,questions)
  values(p_job_id,auth.uid(),p_proposed_price,p_proposal,p_delivery_time,p_questions)
  returning id into v_id;
  return v_id;
exception when unique_violation then raise exception 'you have already applied for this job';
end; $$;
grant execute on function public.apply_for_job(uuid,numeric,text,text,text) to authenticated;

-- Worker selection is defined once in the final payment/hiring compatibility layer below.
-- These two RPC signatures have existed in earlier MAVORA migrations with different
-- return types. PostgreSQL cannot change a function's return type with CREATE OR REPLACE,
-- so remove the old signature before installing the final versions.
drop function if exists public.change_job_status(uuid,text);
drop function if exists public.choose_worker(uuid,uuid);

create or replace function public.change_job_status(p_job_id uuid,p_status text)
returns void language plpgsql security definer set search_path=public as $$
begin
 update public.jobs set status=p_status,updated_at=now() where id=p_job_id and client_id=auth.uid();
 if not found then raise exception 'job not found or not allowed'; end if;
end; $$;
grant execute on function public.change_job_status(uuid,text) to authenticated;

create or replace function public.submit_work(p_application_id uuid,p_submission text)
returns void language plpgsql security definer set search_path=public as $$
begin
 update public.applications set work_submission=p_submission,work_status='submitted',submitted_at=now(),updated_at=now() where id=p_application_id and worker_id=auth.uid();
 if not found then raise exception 'work not found or not allowed'; end if;
end; $$;
grant execute on function public.submit_work(uuid,text) to authenticated;

-- Withdrawal request: this only creates a request. Actual payout must be confirmed by a secure provider/backend workflow.
create or replace function public.request_withdrawal(p_amount numeric)
returns uuid language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_balance numeric;
begin
 select available_balance into v_balance from public.wallets where user_id=auth.uid() for update;
 if coalesce(v_balance,0)<p_amount then raise exception 'insufficient available balance'; end if;
 if p_amount<=0 then raise exception 'invalid amount'; end if;
 update public.wallets set available_balance=available_balance-p_amount,updated_at=now() where user_id=auth.uid();
 insert into public.withdrawals(user_id,amount,status) values(auth.uid(),p_amount,'pending') returning id into v_id;
 insert into public.transactions(user_id,type,amount,status,reference) values(auth.uid(),'withdrawal',p_amount,'pending',concat('WD-',v_id));
 return v_id;
end; $$;
grant execute on function public.request_withdrawal(numeric) to authenticated;

-- Storage bucket. Tighten further if you need more restrictive MIME rules.
insert into storage.buckets(id,name,public) values('mavora-work','mavora-work',false) on conflict(id) do nothing;

-- IMPORTANT: payment webhooks, KYC, payout confirmation, escrow/fund release, fee calculation,
-- reconciliation, admin suspension and provider secrets belong in secure server-side Edge Functions
-- or another backend. Do not implement them with the anon key in this HTML.


-- ============================================================
-- MAVORA FINAL PRODUCT LAYER
-- ============================================================
-- MAVORA FINAL BACKEND FOUNDATION
-- Run in Supabase SQL Editor after taking a database backup.
-- This script is additive where possible and enables the final product layer.
-- External services such as Paystack webhook deployment and Supabase Auth SMS provider
-- configuration still require their respective dashboards/Edge Functions.

create extension if not exists pgcrypto;

-- ============================================================
-- 1. PROFILE / TRUST FIELDS
-- ============================================================
alter table public.profiles add column if not exists phone_verified boolean default false;
alter table public.profiles add column if not exists phone_verified_at timestamptz;
alter table public.profiles add column if not exists identity_verified boolean default false;
alter table public.profiles add column if not exists identity_verified_at timestamptz;
alter table public.profiles add column if not exists profile_visibility text default 'public';
alter table public.profiles add column if not exists business_mode boolean default false;

-- ============================================================
-- 2. WORK PASSPORT
-- ============================================================
create table if not exists public.work_passports (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  passport_slug text unique,
  headline text,
  summary text,
  public_enabled boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.work_passports.
alter table public.work_passports add column if not exists user_id uuid;
alter table public.work_passports add column if not exists passport_slug text;
alter table public.work_passports add column if not exists headline text;
alter table public.work_passports add column if not exists summary text;
alter table public.work_passports add column if not exists public_enabled boolean default false;
alter table public.work_passports add column if not exists created_at timestamptz default now();
alter table public.work_passports add column if not exists updated_at timestamptz default now();


create table if not exists public.proof_of_work (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  contract_id uuid references public.contracts(id) on delete set null,
  title text not null,
  summary text,
  status text not null default 'verified' check (status in ('pending','verified','hidden','revoked')),
  verified_at timestamptz,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.proof_of_work.
alter table public.proof_of_work add column if not exists id uuid default gen_random_uuid();
alter table public.proof_of_work add column if not exists user_id uuid;
alter table public.proof_of_work add column if not exists contract_id uuid;
alter table public.proof_of_work add column if not exists title text;
alter table public.proof_of_work add column if not exists summary text;
alter table public.proof_of_work add column if not exists status text;
alter table public.proof_of_work add column if not exists verified_at timestamptz default now();
alter table public.proof_of_work add column if not exists created_at timestamptz default now();


create table if not exists public.skill_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  skill_name text not null,
  verification_type text default 'assessment',
  status text not null default 'pending' check (status in ('pending','verified','failed','revoked')),
  score numeric,
  evidence_url text,
  verified_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz default now(),
  verified_at timestamptz
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.skill_verifications.
alter table public.skill_verifications add column if not exists id uuid default gen_random_uuid();
alter table public.skill_verifications add column if not exists user_id uuid;
alter table public.skill_verifications add column if not exists skill_name text;
alter table public.skill_verifications add column if not exists verification_type text;
alter table public.skill_verifications add column if not exists status text;
alter table public.skill_verifications add column if not exists score numeric default 0;
alter table public.skill_verifications add column if not exists evidence_url text;
alter table public.skill_verifications add column if not exists verified_by uuid;
alter table public.skill_verifications add column if not exists created_at timestamptz default now();
alter table public.skill_verifications add column if not exists verified_at timestamptz default now();


create index if not exists proof_of_work_user_idx on public.proof_of_work(user_id, created_at desc);
create index if not exists skill_verifications_user_idx on public.skill_verifications(user_id, created_at desc);

-- ============================================================
-- 3. PORTFOLIO
-- ============================================================
create table if not exists public.portfolio_projects (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null,
  public_url text,
  cover_file_path text,
  verified_work boolean default false,
  source_contract_id uuid references public.contracts(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.portfolio_projects.
alter table public.portfolio_projects add column if not exists id uuid default gen_random_uuid();
alter table public.portfolio_projects add column if not exists user_id uuid;
alter table public.portfolio_projects add column if not exists title text;
alter table public.portfolio_projects add column if not exists description text;
alter table public.portfolio_projects add column if not exists public_url text;
alter table public.portfolio_projects add column if not exists cover_file_path text;
alter table public.portfolio_projects add column if not exists verified_work boolean default false;
alter table public.portfolio_projects add column if not exists source_contract_id uuid;
alter table public.portfolio_projects add column if not exists created_at timestamptz default now();
alter table public.portfolio_projects add column if not exists updated_at timestamptz default now();


create index if not exists portfolio_projects_user_idx on public.portfolio_projects(user_id, created_at desc);

-- ============================================================
-- 4. JOB / WORKROOM INFRASTRUCTURE
-- ============================================================
create table if not exists public.job_events (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  event_data jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.job_events.
alter table public.job_events add column if not exists id uuid default gen_random_uuid();
alter table public.job_events add column if not exists job_id uuid;
alter table public.job_events add column if not exists actor_id uuid;
alter table public.job_events add column if not exists event_type text;
alter table public.job_events add column if not exists event_data jsonb default '{}'::jsonb;
alter table public.job_events add column if not exists created_at timestamptz default now();


create table if not exists public.contract_milestones (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references public.contracts(id) on delete cascade,
  title text not null,
  description text,
  amount numeric not null default 0 check (amount >= 0),
  due_at timestamptz,
  status text not null default 'pending' check (status in ('pending','funded','submitted','revision','approved','released','cancelled','disputed')),
  sort_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.contract_milestones.
alter table public.contract_milestones add column if not exists id uuid default gen_random_uuid();
alter table public.contract_milestones add column if not exists contract_id uuid;
alter table public.contract_milestones add column if not exists title text;
alter table public.contract_milestones add column if not exists description text;
alter table public.contract_milestones add column if not exists amount numeric default 0;
alter table public.contract_milestones add column if not exists due_at timestamptz default now();
alter table public.contract_milestones add column if not exists status text;
alter table public.contract_milestones add column if not exists sort_order integer default 0;
alter table public.contract_milestones add column if not exists created_at timestamptz default now();
alter table public.contract_milestones add column if not exists updated_at timestamptz default now();


create table if not exists public.work_submissions (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references public.contracts(id) on delete cascade,
  worker_id uuid not null references public.profiles(id) on delete cascade,
  message text,
  status text not null default 'submitted' check (status in ('submitted','revision_requested','approved','rejected')),
  submitted_at timestamptz default now(),
  reviewed_at timestamptz
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.work_submissions.
alter table public.work_submissions add column if not exists id uuid default gen_random_uuid();
alter table public.work_submissions add column if not exists contract_id uuid;
alter table public.work_submissions add column if not exists worker_id uuid;
alter table public.work_submissions add column if not exists message text;
alter table public.work_submissions add column if not exists status text;
alter table public.work_submissions add column if not exists submitted_at timestamptz default now();
alter table public.work_submissions add column if not exists reviewed_at timestamptz default now();


create table if not exists public.work_revisions (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.work_submissions(id) on delete cascade,
  requested_by uuid not null references public.profiles(id) on delete cascade,
  note text not null,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.work_revisions.
alter table public.work_revisions add column if not exists id uuid default gen_random_uuid();
alter table public.work_revisions add column if not exists submission_id uuid;
alter table public.work_revisions add column if not exists requested_by uuid;
alter table public.work_revisions add column if not exists note text;
alter table public.work_revisions add column if not exists created_at timestamptz default now();


create index if not exists job_events_job_idx on public.job_events(job_id, created_at desc);
create index if not exists milestones_contract_idx on public.contract_milestones(contract_id, sort_order);
create index if not exists work_submissions_contract_idx on public.work_submissions(contract_id, submitted_at desc);

-- ============================================================
-- 5. RECURRING WORK
-- ============================================================
create table if not exists public.recurring_jobs (
  id uuid primary key default gen_random_uuid(),
  source_job_id uuid references public.jobs(id) on delete set null,
  client_id uuid not null references public.profiles(id) on delete cascade,
  worker_id uuid references public.profiles(id) on delete set null,
  frequency text not null check (frequency in ('weekly','biweekly','monthly','custom')),
  next_run_at timestamptz,
  active boolean default true,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.recurring_jobs.
alter table public.recurring_jobs add column if not exists id uuid default gen_random_uuid();
alter table public.recurring_jobs add column if not exists source_job_id uuid;
alter table public.recurring_jobs add column if not exists client_id uuid;
alter table public.recurring_jobs add column if not exists worker_id uuid;
alter table public.recurring_jobs add column if not exists frequency text;
alter table public.recurring_jobs add column if not exists next_run_at timestamptz default now();
alter table public.recurring_jobs add column if not exists active boolean default false;
alter table public.recurring_jobs add column if not exists created_at timestamptz default now();


-- ============================================================
-- 6. BUSINESS MODE / TEAMS
-- ============================================================
create table if not exists public.business_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references public.profiles(id) on delete cascade,
  business_name text not null,
  description text,
  website text,
  logo_path text,
  verified boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.business_profiles.
alter table public.business_profiles add column if not exists id uuid default gen_random_uuid();
alter table public.business_profiles add column if not exists owner_id uuid;
alter table public.business_profiles add column if not exists business_name text;
alter table public.business_profiles add column if not exists description text;
alter table public.business_profiles add column if not exists website text;
alter table public.business_profiles add column if not exists logo_path text;
alter table public.business_profiles add column if not exists verified boolean default false;
alter table public.business_profiles add column if not exists created_at timestamptz default now();
alter table public.business_profiles add column if not exists updated_at timestamptz default now();


create table if not exists public.business_members (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.business_profiles(id) on delete cascade,
  member_user_id uuid references public.profiles(id) on delete set null,
  member_email text not null,
  role text not null default 'member' check (role in ('member','manager','admin')),
  status text not null default 'invited' check (status in ('invited','active','removed')),
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.business_members.
alter table public.business_members add column if not exists id uuid default gen_random_uuid();
alter table public.business_members add column if not exists business_id uuid;
alter table public.business_members add column if not exists member_user_id uuid;
alter table public.business_members add column if not exists member_email text;
alter table public.business_members add column if not exists role text;
alter table public.business_members add column if not exists status text;
alter table public.business_members add column if not exists created_at timestamptz default now();


create unique index if not exists business_member_email_unique on public.business_members(business_id, lower(member_email));

-- ============================================================
-- 7. TEAM PROJECTS
-- ============================================================
create table if not exists public.contract_team_members (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references public.contracts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text,
  status text default 'active',
  created_at timestamptz default now(),
  unique(contract_id,user_id)
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.contract_team_members.
alter table public.contract_team_members add column if not exists id uuid default gen_random_uuid();
alter table public.contract_team_members add column if not exists contract_id uuid;
alter table public.contract_team_members add column if not exists user_id uuid;
alter table public.contract_team_members add column if not exists role text;
alter table public.contract_team_members add column if not exists status text;
alter table public.contract_team_members add column if not exists created_at timestamptz default now();


-- ============================================================
-- 8. CLIENT RELIABILITY / TRUST SIGNALS
-- ============================================================
create table if not exists public.client_reliability (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  completed_jobs integer default 0,
  cancelled_jobs integer default 0,
  paid_jobs integer default 0,
  dispute_count integer default 0,
  average_response_hours numeric,
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.client_reliability.
alter table public.client_reliability add column if not exists user_id uuid;
alter table public.client_reliability add column if not exists completed_jobs integer default 0;
alter table public.client_reliability add column if not exists cancelled_jobs integer default 0;
alter table public.client_reliability add column if not exists paid_jobs integer default 0;
alter table public.client_reliability add column if not exists dispute_count integer default 0;
alter table public.client_reliability add column if not exists average_response_hours numeric default 0;
alter table public.client_reliability add column if not exists updated_at timestamptz default now();


-- ============================================================
-- 9. AUDIT LOG
-- ============================================================
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.audit_logs.
alter table public.audit_logs add column if not exists id uuid default gen_random_uuid();
alter table public.audit_logs add column if not exists actor_id uuid;
alter table public.audit_logs add column if not exists action text;
alter table public.audit_logs add column if not exists entity_type text;
alter table public.audit_logs add column if not exists entity_id uuid;
alter table public.audit_logs add column if not exists metadata jsonb default '{}'::jsonb;
alter table public.audit_logs add column if not exists created_at timestamptz default now();


create index if not exists audit_logs_entity_idx on public.audit_logs(entity_type, entity_id, created_at desc);
create index if not exists audit_logs_actor_idx on public.audit_logs(actor_id, created_at desc);

-- ============================================================
-- 10. PHONE VERIFICATION SYNC
-- Supabase Auth handles the OTP. This function only syncs the verified state.
-- ============================================================
create or replace function public.sync_phone_verification()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text;
  v_confirmed timestamptz;
begin
  select phone, phone_confirmed_at
    into v_phone, v_confirmed
  from auth.users
  where id = auth.uid();

  update public.profiles
  set phone_verified = (v_confirmed is not null),
      phone_verified_at = v_confirmed,
      updated_at = now()
  where id = auth.uid();

  return jsonb_build_object(
    'success', true,
    'phone_verified', v_confirmed is not null
  );
end;
$$;

revoke all on function public.sync_phone_verification() from public;
grant execute on function public.sync_phone_verification() to authenticated;

-- ============================================================
-- 11. RLS
-- ============================================================
alter table public.work_passports enable row level security;
alter table public.proof_of_work enable row level security;
alter table public.skill_verifications enable row level security;
alter table public.portfolio_projects enable row level security;
alter table public.job_events enable row level security;
alter table public.contract_milestones enable row level security;
alter table public.work_submissions enable row level security;
alter table public.work_revisions enable row level security;
alter table public.recurring_jobs enable row level security;
alter table public.business_profiles enable row level security;
alter table public.business_members enable row level security;
alter table public.contract_team_members enable row level security;
alter table public.client_reliability enable row level security;
alter table public.audit_logs enable row level security;

-- Work passports are public only when enabled; owner can always manage theirs.
drop policy if exists work_passport_public_read on public.work_passports;
create policy work_passport_public_read on public.work_passports for select to authenticated using (public_enabled = true or user_id = auth.uid());
drop policy if exists work_passport_owner_write on public.work_passports;
create policy work_passport_owner_write on public.work_passports for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Proof of work: owner + authenticated users can read verified public records; owner can manage.
drop policy if exists proof_work_public_read on public.proof_of_work;
create policy proof_work_public_read on public.proof_of_work for select to authenticated using (status='verified' or user_id=auth.uid());
drop policy if exists proof_work_owner_insert on public.proof_of_work;
create policy proof_work_owner_insert on public.proof_of_work for insert to authenticated with check (user_id=auth.uid());
drop policy if exists proof_work_owner_update on public.proof_of_work;
create policy proof_work_owner_update on public.proof_of_work for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());

-- Skill verification results are public; only admin/server should mark verified in production.
drop policy if exists skill_verification_read on public.skill_verifications;
create policy skill_verification_read on public.skill_verifications for select to authenticated using (true);
drop policy if exists skill_verification_owner_insert on public.skill_verifications;
create policy skill_verification_owner_insert on public.skill_verifications for insert to authenticated with check (user_id=auth.uid());

-- Portfolio is public unless the user chooses profile visibility elsewhere.
drop policy if exists portfolio_public_read on public.portfolio_projects;
create policy portfolio_public_read on public.portfolio_projects for select to authenticated using (true);
drop policy if exists portfolio_owner_write on public.portfolio_projects;
create policy portfolio_owner_write on public.portfolio_projects for all to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());

-- Business profile: public profile read, owner management.
drop policy if exists business_profile_read on public.business_profiles;
create policy business_profile_read on public.business_profiles for select to authenticated using (true);
drop policy if exists business_profile_owner_write on public.business_profiles;
create policy business_profile_owner_write on public.business_profiles for all to authenticated using (owner_id=auth.uid()) with check (owner_id=auth.uid());

-- Business members: owner/admin should be managed by secure RPCs in a production deployment.
drop policy if exists business_members_read on public.business_members;
create policy business_members_read on public.business_members for select to authenticated using (exists(select 1 from public.business_profiles b where b.id=business_id and b.owner_id=auth.uid()) or member_user_id=auth.uid());

-- Reliability is readable, but should be written by trusted functions.
drop policy if exists client_reliability_read on public.client_reliability;
create policy client_reliability_read on public.client_reliability for select to authenticated using (true);

-- Audit logs: users cannot directly read/write the global audit log unless an admin policy is added.
drop policy if exists audit_logs_none on public.audit_logs;
create policy audit_logs_none on public.audit_logs for select to authenticated using (false);

-- ============================================================
-- 12. EVENT HELPER
-- ============================================================
create or replace function public.record_job_event(p_job_id uuid,p_event_type text,p_event_data jsonb default '{}'::jsonb)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_id uuid;
begin
  if not exists(select 1 from public.jobs where id=p_job_id and (client_id=auth.uid() or exists(select 1 from public.applications a where a.job_id=p_job_id and a.worker_id=auth.uid()))) then
    raise exception 'Not authorized for this job';
  end if;
  insert into public.job_events(job_id,actor_id,event_type,event_data) values(p_job_id,auth.uid(),p_event_type,coalesce(p_event_data,'{}'::jsonb)) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.record_job_event(uuid,text,jsonb) from public;
grant execute on function public.record_job_event(uuid,text,jsonb) to authenticated;

-- ============================================================
-- 13. PROOF OF WORK CREATION AFTER COMPLETION
-- ============================================================
create or replace function public.create_verified_proof_of_work(p_contract_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_worker uuid; v_job uuid; v_title text; v_id uuid;
begin
  select c.worker_id,c.job_id,j.title into v_worker,v_job,v_title
  from public.contracts c join public.jobs j on j.id=c.job_id
  where c.id=p_contract_id and c.status='completed';
  if v_worker is null then raise exception 'Completed contract not found'; end if;
  if auth.uid()<>v_worker and not exists(select 1 from public.profiles where id=auth.uid() and is_admin=true) then raise exception 'Not authorized'; end if;
  if exists(select 1 from public.proof_of_work where contract_id=p_contract_id and status='verified') then
    return jsonb_build_object('success',true,'existing',true);
  end if;
  insert into public.proof_of_work(user_id,contract_id,title,summary,status,verified_at)
  values(v_worker,p_contract_id,v_title,'Completed and approved MAVORA work.','verified',now()) returning id into v_id;
  return jsonb_build_object('success',true,'id',v_id);
end;
$$;
revoke all on function public.create_verified_proof_of_work(uuid) from public;
grant execute on function public.create_verified_proof_of_work(uuid) to authenticated;

-- ============================================================
-- 14. NOTIFICATION ENHANCEMENTS
-- Add optional deep-link fields if notifications table exists.
-- ============================================================
do $$
begin
  if to_regclass('public.notifications') is not null then
    alter table public.notifications add column if not exists target_page text;
    alter table public.notifications add column if not exists target_id uuid;
    alter table public.notifications add column if not exists data jsonb default '{}'::jsonb;
  end if;
end $$;

-- ============================================================
-- 15. SECURITY INDEXES / DUPLICATE PROTECTION
-- ============================================================
create index if not exists jobs_client_status_idx on public.jobs(client_id,status,created_at desc);
create index if not exists applications_worker_status_idx on public.applications(worker_id,status,created_at desc);
create index if not exists applications_job_status_idx on public.applications(job_id,status,created_at desc);
create index if not exists contracts_client_status_idx on public.contracts(client_id,status,updated_at desc);
create index if not exists contracts_worker_status_idx on public.contracts(worker_id,status,updated_at desc);

-- Prevent multiple active team memberships and repeated verified proof for one contract.
create unique index if not exists verified_proof_contract_unique on public.proof_of_work(contract_id) where status='verified' and contract_id is not null;

-- ============================================================
-- 16. RECOMMENDED STORAGE BUCKETS
-- ============================================================
insert into storage.buckets(id,name,public) values ('mavora-work','mavora-work',false) on conflict (id) do update set public=false;
insert into storage.buckets(id,name,public) values ('mavora-avatars','mavora-avatars',true) on conflict (id) do update set public=true;
insert into storage.buckets(id,name,public) values ('mavora-evidence','mavora-evidence',false) on conflict (id) do update set public=false;
insert into storage.buckets(id,name,public) values ('mavora-portfolio','mavora-portfolio',false) on conflict (id) do update set public=false;

-- Work files: user may upload only under their own UUID prefix.
drop policy if exists mavora_work_insert_own on storage.objects;
create policy mavora_work_insert_own on storage.objects for insert to authenticated with check (bucket_id='mavora-work' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists mavora_work_select_participant on storage.objects;
create policy mavora_work_select_participant on storage.objects for select to authenticated using (bucket_id='mavora-work' and (storage.foldername(name))[1]=auth.uid()::text);

-- Portfolio uploads are private by default; public rendering should use controlled signed URLs.
drop policy if exists mavora_portfolio_insert_own on storage.objects;
create policy mavora_portfolio_insert_own on storage.objects for insert to authenticated with check (bucket_id='mavora-portfolio' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists mavora_portfolio_select_own on storage.objects;
create policy mavora_portfolio_select_own on storage.objects for select to authenticated using (bucket_id='mavora-portfolio' and (storage.foldername(name))[1]=auth.uid()::text);

-- ============================================================
-- 17. PHONE / ACCOUNT SAFETY NOTES
-- ============================================================
-- Configure Supabase Authentication > Phone provider with a supported SMS provider.
-- Do not store OTPs in a normal public table.
-- Never put Paystack secret keys, webhook signing secrets, service-role keys,
-- SMS provider secrets, or bank credentials in index.html.

-- ============================================================
-- 18. PAYMENT / PAYSTACK REQUIREMENT
-- ============================================================
-- Keep the existing secure payment RPCs and Edge Functions such as:
--   mavora-paystack
--   payment-verification
-- They must validate the authenticated user, application/job ownership,
-- transaction reference, amount, currency and idempotency server-side.
-- The frontend must only receive a checkout URL/reference and never a secret key.

-- ============================================================
-- 19. ADMIN NOTE
-- ============================================================
-- Existing admin authorization must remain server-side. Do not grant normal
-- authenticated users access to audit logs, refunds, withdrawal approvals,
-- identity verification decisions, or payment-release overrides.

-- ============================================================
-- END
-- ============================================================


-- ============================================================
-- MAVORA ADDITIVE SAVED JOBS / SERVICES LAYER
-- ============================================================
-- MAVORA ADDITIVE MIGRATION
-- Adds missing support for Saved Jobs, clickable Notifications, Services,
-- Identity status, and wallet/profile initialization without deleting existing data.

create extension if not exists pgcrypto;

-- Identity status (safe status fields only; do NOT store raw ID documents here)
alter table public.profiles add column if not exists identity_verified boolean default false;
alter table public.profiles add column if not exists identity_verified_at timestamptz;

-- Saved jobs: composite primary key is intentional; the frontend must not expect saved_jobs.id.
create table if not exists public.saved_jobs (
  user_id uuid not null references public.profiles(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  created_at timestamptz default now(),
  primary key(user_id, job_id)
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.saved_jobs.
alter table public.saved_jobs add column if not exists user_id uuid;
alter table public.saved_jobs add column if not exists job_id uuid;
alter table public.saved_jobs add column if not exists created_at timestamptz default now();


create table if not exists public.saved_searches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text,
  query text,
  filters jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.saved_searches.
alter table public.saved_searches add column if not exists id uuid default gen_random_uuid();
alter table public.saved_searches add column if not exists user_id uuid;
alter table public.saved_searches add column if not exists name text;
alter table public.saved_searches add column if not exists query text;
alter table public.saved_searches add column if not exists filters jsonb default '{}'::jsonb;
alter table public.saved_searches add column if not exists created_at timestamptz default now();


-- Make notifications capable of opening the exact related screen/item.
alter table public.notifications add column if not exists target_page text;
alter table public.notifications add column if not exists target_id uuid;

-- Earn Online / Services layer.
create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null,
  category text,
  price numeric(14,2) not null default 0 check (price >= 0),
  status text not null default 'active' check (status in ('active','paused','removed')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.services.
alter table public.services add column if not exists id uuid default gen_random_uuid();
alter table public.services add column if not exists user_id uuid;
alter table public.services add column if not exists title text;
alter table public.services add column if not exists description text;
alter table public.services add column if not exists category text;
alter table public.services add column if not exists price numeric(14,2) default 0;
alter table public.services add column if not exists status text;
alter table public.services add column if not exists created_at timestamptz default now();
alter table public.services add column if not exists updated_at timestamptz default now();

create index if not exists services_user_idx on public.services(user_id,created_at desc);
create index if not exists services_status_idx on public.services(status,created_at desc);

-- Wallet row initialization for existing users.
insert into public.wallets(user_id)
select p.id from public.profiles p
where not exists (select 1 from public.wallets w where w.user_id=p.id);

-- Ensure new accounts receive a wallet without relying on the frontend.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  insert into public.profiles(id,email,full_name,username)
  values(new.id,new.email,new.raw_user_meta_data->>'full_name',new.raw_user_meta_data->>'username')
  on conflict(id) do update set email=excluded.email;

  insert into public.wallets(user_id)
  values(new.id)
  on conflict(user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS
alter table public.saved_jobs enable row level security;
alter table public.saved_searches enable row level security;
alter table public.services enable row level security;

-- Saved jobs
 drop policy if exists saved_jobs_select_own on public.saved_jobs;
 drop policy if exists saved_jobs_insert_own on public.saved_jobs;
 drop policy if exists saved_jobs_delete_own on public.saved_jobs;
drop policy if exists saved_jobs_select_own on public.saved_jobs;
create policy saved_jobs_select_own on public.saved_jobs for select to authenticated using (user_id=auth.uid());
drop policy if exists saved_jobs_insert_own on public.saved_jobs;
create policy saved_jobs_insert_own on public.saved_jobs for insert to authenticated with check (user_id=auth.uid());
drop policy if exists saved_jobs_delete_own on public.saved_jobs;
create policy saved_jobs_delete_own on public.saved_jobs for delete to authenticated using (user_id=auth.uid());

-- Saved searches
 drop policy if exists saved_searches_select_own on public.saved_searches;
 drop policy if exists saved_searches_insert_own on public.saved_searches;
 drop policy if exists saved_searches_delete_own on public.saved_searches;
drop policy if exists saved_searches_select_own on public.saved_searches;
create policy saved_searches_select_own on public.saved_searches for select to authenticated using (user_id=auth.uid());
drop policy if exists saved_searches_insert_own on public.saved_searches;
create policy saved_searches_insert_own on public.saved_searches for insert to authenticated with check (user_id=auth.uid());
drop policy if exists saved_searches_delete_own on public.saved_searches;
create policy saved_searches_delete_own on public.saved_searches for delete to authenticated using (user_id=auth.uid());

-- Services: owners manage their own services; authenticated users can discover active services.
 drop policy if exists services_select_active on public.services;
 drop policy if exists services_select_own on public.services;
 drop policy if exists services_insert_own on public.services;
 drop policy if exists services_update_own on public.services;
 drop policy if exists services_delete_own on public.services;
drop policy if exists services_select_active on public.services;
create policy services_select_active on public.services for select to authenticated using (status='active' or user_id=auth.uid());
drop policy if exists services_insert_own on public.services;
create policy services_insert_own on public.services for insert to authenticated with check (user_id=auth.uid());
drop policy if exists services_update_own on public.services;
create policy services_update_own on public.services for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
drop policy if exists services_delete_own on public.services;
create policy services_delete_own on public.services for delete to authenticated using (user_id=auth.uid());

-- Wallets / transactions / withdrawals should already be protected by the main MAVORA SQL.
-- This migration intentionally does not expose bank account numbers or payment secrets to the browser.


-- ============================================================
-- MAVORA FINAL MARKET / IDENTITY / ALERTS LAYER
-- ============================================================
-- ============================================================
-- MAVORA FINAL BACKEND / NIGERIA MARKET + IDENTITY + ALERTS
-- Run AFTER your existing MAVORA foundation SQL.
-- No secret keys belong in this file.
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- 1) NOTIFICATIONS (SAFE BASE + DEEP LINKS)
-- ============================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  message text not null,
  is_read boolean not null default false,
  target_page text,
  target_id uuid,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.notifications.
alter table public.notifications add column if not exists id uuid default gen_random_uuid();
alter table public.notifications add column if not exists user_id uuid;
alter table public.notifications add column if not exists title text;
alter table public.notifications add column if not exists message text;
alter table public.notifications add column if not exists type text;
alter table public.notifications add column if not exists is_read boolean default false;
alter table public.notifications add column if not exists created_at timestamptz default now();
alter table public.notifications add column if not exists target_page text;
alter table public.notifications add column if not exists target_id uuid;
alter table public.notifications add column if not exists data jsonb default '{}'::jsonb;


alter table public.notifications add column if not exists target_page text;
alter table public.notifications add column if not exists target_id uuid;
alter table public.notifications add column if not exists data jsonb default '{}'::jsonb;
alter table public.notifications enable row level security;

drop policy if exists mavora_notifications_read_own on public.notifications;
drop policy if exists mavora_notifications_read_own on public.notifications;
create policy mavora_notifications_read_own on public.notifications
for select to authenticated using(user_id=auth.uid());

drop policy if exists mavora_notifications_update_own on public.notifications;
drop policy if exists mavora_notifications_update_own on public.notifications;
create policy mavora_notifications_update_own on public.notifications
for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

-- Keep INSERT server-side; the browser should not be allowed to forge platform alerts.
drop policy if exists mavora_notifications_insert_none on public.notifications;
drop policy if exists mavora_notifications_insert_none on public.notifications;
create policy mavora_notifications_insert_none on public.notifications
for insert to authenticated with check(false);

create index if not exists mavora_notifications_user_created_idx on public.notifications(user_id,created_at desc);
create index if not exists mavora_notifications_unread_idx on public.notifications(user_id,is_read,created_at desc);

create or replace function public.mavora_notify(
  p_user_id uuid,
  p_title text,
  p_message text,
  p_target_page text default null,
  p_target_id uuid default null,
  p_data jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path=public
as $$
declare v_id uuid;
begin
  if p_user_id is null then return null; end if;
  insert into public.notifications(user_id,title,message,target_page,target_id,data)
  values(p_user_id,left(coalesce(p_title,'MAVORA'),120),left(coalesce(p_message,''),2000),p_target_page,p_target_id,coalesce(p_data,'{}'::jsonb))
  returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.mavora_notify(uuid,text,text,text,uuid,jsonb) from public;
grant execute on function public.mavora_notify(uuid,text,text,text,uuid,jsonb) to authenticated;


-- ============================================================
-- 2) IDENTITY VERIFICATION + SELFIE/LIVENESS EVIDENCE
-- ============================================================
create table if not exists public.identity_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null,
  document_number text not null,
  document_path text not null,
  face_path text,
  face_status text not null default 'not_captured',
  liveness_status text not null default 'not_checked',
  status text not null default 'pending' check(status in ('pending','verified','rejected')),
  review_due_at timestamptz,
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.identity_verifications.
alter table public.identity_verifications add column if not exists id uuid default gen_random_uuid();
alter table public.identity_verifications add column if not exists user_id uuid;
alter table public.identity_verifications add column if not exists document_type text;
alter table public.identity_verifications add column if not exists document_number text;
alter table public.identity_verifications add column if not exists document_path text;
alter table public.identity_verifications add column if not exists face_path text;
alter table public.identity_verifications add column if not exists face_status text;
alter table public.identity_verifications add column if not exists liveness_status text;
alter table public.identity_verifications add column if not exists status text;
alter table public.identity_verifications add column if not exists review_due_at timestamptz default now();
alter table public.identity_verifications add column if not exists reviewed_at timestamptz default now();
alter table public.identity_verifications add column if not exists reviewed_by uuid;
alter table public.identity_verifications add column if not exists rejection_reason text;
alter table public.identity_verifications add column if not exists created_at timestamptz default now();
alter table public.identity_verifications add column if not exists updated_at timestamptz default now();


alter table public.identity_verifications add column if not exists face_path text;
alter table public.identity_verifications add column if not exists face_status text default 'not_captured';
alter table public.identity_verifications add column if not exists liveness_status text default 'not_checked';
alter table public.identity_verifications add column if not exists review_due_at timestamptz;
alter table public.identity_verifications add column if not exists reviewed_by uuid references public.profiles(id) on delete set null;
alter table public.identity_verifications add column if not exists updated_at timestamptz default now();
alter table public.identity_verifications enable row level security;

drop policy if exists mavora_identity_owner_read on public.identity_verifications;
drop policy if exists mavora_identity_owner_read on public.identity_verifications;
create policy mavora_identity_owner_read on public.identity_verifications
for select to authenticated using(user_id=auth.uid());

drop policy if exists mavora_identity_owner_insert on public.identity_verifications;
drop policy if exists mavora_identity_owner_insert on public.identity_verifications;
create policy mavora_identity_owner_insert on public.identity_verifications
for insert to authenticated with check(user_id=auth.uid());

drop policy if exists mavora_identity_staff_read on public.identity_verifications;
drop policy if exists mavora_identity_staff_read on public.identity_verifications;
create policy mavora_identity_staff_read on public.identity_verifications
for select to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator')));

create index if not exists mavora_identity_user_created_idx on public.identity_verifications(user_id,created_at desc);
create index if not exists mavora_identity_pending_idx on public.identity_verifications(status,created_at desc);

create or replace function public.mavora_review_identity_v2(
  p_verification_id uuid,
  p_status text,
  p_rejection_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_user uuid; v_phone boolean;
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator')) then
    raise exception 'Staff access required';
  end if;
  if p_status not in ('verified','rejected') then raise exception 'Invalid identity status'; end if;
  select user_id into v_user from public.identity_verifications where id=p_verification_id;
  if v_user is null then raise exception 'Identity verification not found'; end if;
  select coalesce(phone_verified,false) into v_phone from public.profiles where id=v_user;

  update public.identity_verifications
  set status=p_status,
      reviewed_at=now(),
      reviewed_by=auth.uid(),
      rejection_reason=case when p_status='rejected' then nullif(trim(coalesce(p_rejection_reason,'')),'') else null end,
      updated_at=now()
  where id=p_verification_id;

  update public.profiles
  set identity_verified=(p_status='verified'),
      identity_verified_at=case when p_status='verified' then now() else null end,
      updated_at=now()
  where id=v_user;

  if to_regclass('public.market_profiles') is not null then
    update public.market_profiles
    set verified_seller=(p_status='verified' and v_phone),
        verified_at=case when p_status='verified' and v_phone then now() else null end,
        updated_at=now()
    where user_id=v_user;
  end if;

  return jsonb_build_object('success',true,'status',p_status);
end;
$$;
revoke all on function public.mavora_review_identity_v2(uuid,text,text) from public;
grant execute on function public.mavora_review_identity_v2(uuid,text,text) to authenticated;


create or replace function public.mavora_unverify_identity_v2(p_verification_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_user uuid;
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='founder') then raise exception 'Founder access required'; end if;
  select user_id into v_user from public.identity_verifications where id=p_verification_id;
  if v_user is null then raise exception 'Identity verification not found'; end if;
  update public.identity_verifications set status='rejected',reviewed_at=now(),reviewed_by=auth.uid(),rejection_reason='Verification reverted by Founder',updated_at=now() where id=p_verification_id;
  update public.profiles set identity_verified=false,identity_verified_at=null,updated_at=now() where id=v_user;
  if to_regclass('public.market_profiles') is not null then update public.market_profiles set verified_seller=false,verified_at=null,updated_at=now() where user_id=v_user; end if;
  perform public.mavora_notify(v_user,'Identity verification changed','Your MAVORA identity verification was changed back to unverified by the Founder.','identity',p_verification_id,'{}'::jsonb);
  return jsonb_build_object('success',true);
end;
$$;
revoke all on function public.mavora_unverify_identity_v2(uuid) from public;
grant execute on function public.mavora_unverify_identity_v2(uuid) to authenticated;


-- ============================================================
-- 3) IDENTITY STORAGE POLICIES / OBJECT-NOT-FOUND FIX
-- ============================================================
insert into storage.buckets(id,name,public)
values('mavora-identity','mavora-identity',false)
on conflict(id) do update set public=false;

drop policy if exists mavora_identity_insert_own on storage.objects;
drop policy if exists mavora_identity_insert_own on storage.objects;
create policy mavora_identity_insert_own on storage.objects
for insert to authenticated
with check(bucket_id='mavora-identity' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists mavora_identity_owner_select on storage.objects;
drop policy if exists mavora_identity_owner_select on storage.objects;
create policy mavora_identity_owner_select on storage.objects
for select to authenticated
using(bucket_id='mavora-identity' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists mavora_identity_staff_select on storage.objects;
drop policy if exists mavora_identity_staff_select on storage.objects;
create policy mavora_identity_staff_select on storage.objects
for select to authenticated
using(bucket_id='mavora-identity' and exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator')));

-- Nearby work coordinates are stored only for distance matching; the exact coordinates should not be rendered publicly.
alter table public.jobs add column if not exists latitude double precision;
alter table public.jobs add column if not exists longitude double precision;
create index if not exists mavora_jobs_geo_idx on public.jobs(latitude,longitude) where latitude is not null and longitude is not null;

-- Keep the separate Market seller trust flag synchronized when Supabase Auth confirms a phone.
create or replace function public.sync_phone_verification()
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_confirmed timestamptz;
begin
  select phone_confirmed_at into v_confirmed from auth.users where id=auth.uid();
  update public.profiles set phone_verified=(v_confirmed is not null),phone_verified_at=v_confirmed,updated_at=now() where id=auth.uid();
  if to_regclass('public.market_profiles') is not null then
    update public.market_profiles set verified_seller=(coalesce((select identity_verified from public.profiles where id=auth.uid()),false) and v_confirmed is not null),verified_at=case when coalesce((select identity_verified from public.profiles where id=auth.uid()),false) and v_confirmed is not null then now() else null end,updated_at=now() where user_id=auth.uid();
  end if;
  return jsonb_build_object('success',true,'phone_verified',v_confirmed is not null);
end;
$$;
revoke all on function public.sync_phone_verification() from public;
grant execute on function public.sync_phone_verification() to authenticated;

-- ============================================================
-- 4) SEPARATE MAVORA MARKET ACCOUNT / PROFILE
-- ============================================================
create table if not exists public.market_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  display_name text not null,
  username text not null,
  state text,
  city text,
  verified_seller boolean not null default false,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.market_profiles.
alter table public.market_profiles add column if not exists user_id uuid;
alter table public.market_profiles add column if not exists display_name text;
alter table public.market_profiles add column if not exists username text;
alter table public.market_profiles add column if not exists state text;
alter table public.market_profiles add column if not exists city text;
alter table public.market_profiles add column if not exists verified_seller boolean default false;
alter table public.market_profiles add column if not exists verified_at timestamptz default now();
alter table public.market_profiles add column if not exists created_at timestamptz default now();
alter table public.market_profiles add column if not exists updated_at timestamptz default now();

create unique index if not exists market_profiles_username_unique on public.market_profiles(lower(username));
alter table public.market_profiles enable row level security;

drop policy if exists mavora_market_profile_public_read on public.market_profiles;
drop policy if exists mavora_market_profile_public_read on public.market_profiles;
create policy mavora_market_profile_public_read on public.market_profiles
for select to anon,authenticated using(true);

drop policy if exists mavora_market_profile_owner_write on public.market_profiles;
drop policy if exists mavora_market_profile_owner_write on public.market_profiles;
create policy mavora_market_profile_owner_write on public.market_profiles
for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());

-- ============================================================
-- 5) MARKET LISTINGS / MODERATION
-- ============================================================
create table if not exists public.market_listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null,
  price numeric(14,2) not null check(price>0),
  category text not null,
  condition text not null check(condition in ('New','Used','Refurbished')),
  state text,
  city text,
  image_paths jsonb not null default '[]'::jsonb,
  storage_paths jsonb not null default '[]'::jsonb,
  moderation_status text not null default 'pending' check(moderation_status in ('pending','approved','rejected')),
  moderation_reason text,
  seller_verified boolean not null default false,
  status text not null default 'active' check(status in ('active','reserved','sold','removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.market_listings.
alter table public.market_listings add column if not exists id uuid default gen_random_uuid();
alter table public.market_listings add column if not exists seller_id uuid;
alter table public.market_listings add column if not exists title text;
alter table public.market_listings add column if not exists description text;
alter table public.market_listings add column if not exists price numeric(14,2) default 0;
alter table public.market_listings add column if not exists category text;
alter table public.market_listings add column if not exists condition text;
alter table public.market_listings add column if not exists state text;
alter table public.market_listings add column if not exists city text;
alter table public.market_listings add column if not exists image_paths jsonb default '{}'::jsonb;
alter table public.market_listings add column if not exists storage_paths jsonb default '{}'::jsonb;
alter table public.market_listings add column if not exists moderation_status text;
alter table public.market_listings add column if not exists moderation_reason text;
alter table public.market_listings add column if not exists seller_verified boolean default false;
alter table public.market_listings add column if not exists status text;
alter table public.market_listings add column if not exists created_at timestamptz default now();
alter table public.market_listings add column if not exists updated_at timestamptz default now();

create index if not exists mavora_market_listing_search_idx on public.market_listings(moderation_status,status,created_at desc);
create index if not exists mavora_market_listing_location_idx on public.market_listings(state,city,created_at desc);
create index if not exists mavora_market_listing_seller_idx on public.market_listings(seller_id,created_at desc);
alter table public.market_listings enable row level security;

drop policy if exists mavora_market_listing_public_read on public.market_listings;
drop policy if exists mavora_market_listing_public_read on public.market_listings;
create policy mavora_market_listing_public_read on public.market_listings
for select to anon,authenticated
using((moderation_status='approved' and status in ('active','reserved')) or seller_id=auth.uid());

drop policy if exists mavora_market_listing_owner_update on public.market_listings;
drop policy if exists mavora_market_listing_owner_update on public.market_listings;
create policy mavora_market_listing_owner_update on public.market_listings
for update to authenticated using(seller_id=auth.uid()) with check(seller_id=auth.uid());

drop policy if exists mavora_market_listing_staff_manage on public.market_listings;
drop policy if exists mavora_market_listing_staff_manage on public.market_listings;
create policy mavora_market_listing_staff_manage on public.market_listings
for all to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator'))) with check(exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator')));

create or replace function public.mavora_create_market_listing(
  p_title text,
  p_description text,
  p_price numeric,
  p_category text,
  p_condition text,
  p_state text default null,
  p_city text default null,
  p_image_paths jsonb default '[]'::jsonb,
  p_storage_paths jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_phone boolean; v_identity boolean; v_market boolean; v_id uuid;
begin
  select coalesce(phone_verified,false),coalesce(identity_verified,false) into v_phone,v_identity from public.profiles where id=auth.uid();
  select exists(select 1 from public.market_profiles where user_id=auth.uid()) into v_market;
  if not v_market then return jsonb_build_object('success',false,'message','Create your separate MAVORA Market account first.'); end if;
  if not v_phone then return jsonb_build_object('success',false,'message','Verify your phone before selling on MAVORA Market.'); end if;
  if not v_identity then return jsonb_build_object('success',false,'message','Complete identity verification before selling on MAVORA Market.'); end if;
  if coalesce(length(trim(p_title)),0)<3 then return jsonb_build_object('success',false,'message','Item title is too short.'); end if;
  if coalesce(length(trim(p_description)),0)<15 then return jsonb_build_object('success',false,'message','Item description is too short.'); end if;
  insert into public.market_listings(seller_id,title,description,price,category,condition,state,city,image_paths,storage_paths,moderation_status,seller_verified)
  select auth.uid(),trim(p_title),trim(p_description),p_price,p_category,p_condition,p_state,p_city,coalesce(p_image_paths,'[]'::jsonb),coalesce(p_storage_paths,'[]'::jsonb),'pending',coalesce(mp.verified_seller,false)
  from public.market_profiles mp where mp.user_id=auth.uid()
  returning id into v_id;
  perform public.mavora_notify(auth.uid(),'Market listing submitted','Your item has been submitted to MAVORA moderation.','market',v_id,'{}'::jsonb);
  return jsonb_build_object('success',true,'listing_id',v_id,'status','pending');
end;
$$;
revoke all on function public.mavora_create_market_listing(text,text,numeric,text,text,text,text,jsonb,jsonb) from public;
grant execute on function public.mavora_create_market_listing(text,text,numeric,text,text,text,text,jsonb,jsonb) to authenticated;


create or replace function public.mavora_review_market_listing(
  p_listing_id uuid,
  p_status text,
  p_rejection_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_seller uuid; v_verified boolean;
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator')) then raise exception 'Staff access required'; end if;
  if p_status not in ('approved','rejected') then raise exception 'Invalid Market moderation status'; end if;
  select seller_id into v_seller from public.market_listings where id=p_listing_id;
  if v_seller is null then raise exception 'Market listing not found'; end if;
  select coalesce(verified_seller,false) into v_verified from public.market_profiles where user_id=v_seller;
  if p_status='approved' and not v_verified then return jsonb_build_object('success',false,'message','Seller is not fully verified. Verify the seller before approving the listing.'); end if;
  update public.market_listings set moderation_status=p_status,moderation_reason=case when p_status='rejected' then nullif(trim(coalesce(p_rejection_reason,'')),'') else null end,seller_verified=v_verified,updated_at=now() where id=p_listing_id;
  return jsonb_build_object('success',true,'status',p_status);
end;
$$;
revoke all on function public.mavora_review_market_listing(uuid,text,text) from public;
grant execute on function public.mavora_review_market_listing(uuid,text,text) to authenticated;


insert into storage.buckets(id,name,public)
values('mavora-market','mavora-market',true)
on conflict(id) do update set public=true;

drop policy if exists mavora_market_storage_insert on storage.objects;
create policy mavora_market_storage_insert on storage.objects for insert to authenticated with check(bucket_id='mavora-market' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists mavora_market_storage_delete on storage.objects;
create policy mavora_market_storage_delete on storage.objects for delete to authenticated using(bucket_id='mavora-market' and (storage.foldername(name))[1]=auth.uid()::text);

-- ============================================================
-- 6) MARKET NEGOTIATION MESSAGES (SEPARATE FROM WORK CHAT)
-- ============================================================
create table if not exists public.market_messages (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.market_listings(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check(length(trim(message)) between 1 and 4000),
  created_at timestamptz not null default now(),
  is_read boolean not null default false
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.market_messages.
alter table public.market_messages add column if not exists id uuid default gen_random_uuid();
alter table public.market_messages add column if not exists listing_id uuid;
alter table public.market_messages add column if not exists sender_id uuid;
alter table public.market_messages add column if not exists recipient_id uuid;
alter table public.market_messages add column if not exists message text;
alter table public.market_messages add column if not exists created_at timestamptz default now();
alter table public.market_messages add column if not exists is_read boolean default false;

alter table public.market_messages enable row level security;
create index if not exists mavora_market_messages_listing_idx on public.market_messages(listing_id,created_at asc);
create index if not exists mavora_market_messages_recipient_idx on public.market_messages(recipient_id,created_at desc);

drop policy if exists mavora_market_messages_read on public.market_messages;
create policy mavora_market_messages_read on public.market_messages for select to authenticated using(sender_id=auth.uid() or recipient_id=auth.uid());
drop policy if exists mavora_market_messages_insert on public.market_messages;
create policy mavora_market_messages_insert on public.market_messages for insert to authenticated with check(sender_id=auth.uid());
drop policy if exists mavora_market_messages_update_recipient on public.market_messages;
create policy mavora_market_messages_update_recipient on public.market_messages for update to authenticated using(recipient_id=auth.uid()) with check(recipient_id=auth.uid());

create or replace function public.mavora_send_market_message(p_listing_id uuid,p_recipient_id uuid,p_message text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_seller uuid; v_id uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if p_recipient_id is null or p_recipient_id=auth.uid() then return jsonb_build_object('success',false,'message','Invalid recipient'); end if;
  if length(trim(coalesce(p_message,'')))=0 then return jsonb_build_object('success',false,'message','Write a message first.'); end if;
  if length(p_message)>4000 then return jsonb_build_object('success',false,'message','Message is too long.'); end if;
  select seller_id into v_seller from public.market_listings where id=p_listing_id and status in ('active','reserved','sold') and moderation_status='approved';
  if v_seller is null then return jsonb_build_object('success',false,'message','This Market listing is no longer available.'); end if;
  if p_recipient_id<>v_seller and not exists(select 1 from public.market_messages mm where mm.listing_id=p_listing_id and ((mm.sender_id=auth.uid() and mm.recipient_id=p_recipient_id) or (mm.sender_id=p_recipient_id and mm.recipient_id=auth.uid()))) then
    return jsonb_build_object('success',false,'message','Market messages must stay within the listing conversation.');
  end if;
  if auth.uid()<>v_seller and p_recipient_id<>v_seller then
    return jsonb_build_object('success',false,'message','Buyer messages must be addressed to the listing seller.');
  end if;
  if exists(select 1 from public.message_user_blocks where blocker_id=p_recipient_id and blocked_id=auth.uid()) then return jsonb_build_object('success',false,'message','This user has blocked you.'); end if;
  if exists(select 1 from public.message_user_blocks where blocker_id=auth.uid() and blocked_id=p_recipient_id) then return jsonb_build_object('success',false,'message','Unblock this user before sending.'); end if;
  insert into public.market_messages(listing_id,sender_id,recipient_id,message) values(p_listing_id,auth.uid(),p_recipient_id,trim(p_message)) returning id into v_id;
  return jsonb_build_object('success',true,'message_id',v_id);
end;
$$;
revoke all on function public.mavora_send_market_message(uuid,uuid,text) from public;
grant execute on function public.mavora_send_market_message(uuid,uuid,text) to authenticated;


-- ============================================================
-- 7) MARKET ORDERS + PLATFORM EARNINGS
-- ============================================================
create table if not exists public.market_fee_settings (
  id integer primary key,
  seller_fee_percent numeric(6,3) not null default 5.000 check(seller_fee_percent>=0 and seller_fee_percent<=25),
  updated_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.market_fee_settings.
alter table public.market_fee_settings add column if not exists id integer default 0;
alter table public.market_fee_settings add column if not exists seller_fee_percent numeric(6,3) default 0;
alter table public.market_fee_settings add column if not exists updated_at timestamptz default now();

insert into public.market_fee_settings(id,seller_fee_percent) values(1,5.000) on conflict(id) do nothing;
alter table public.market_fee_settings enable row level security;
drop policy if exists mavora_market_fee_read on public.market_fee_settings;
create policy mavora_market_fee_read on public.market_fee_settings for select to anon,authenticated using(true);
drop policy if exists mavora_market_fee_staff_write on public.market_fee_settings;
create policy mavora_market_fee_staff_write on public.market_fee_settings for update to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role='founder')) with check(exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

create table if not exists public.market_orders (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.market_listings(id) on delete restrict,
  buyer_id uuid not null references public.profiles(id) on delete restrict,
  seller_id uuid not null references public.profiles(id) on delete restrict,
  agreed_price numeric(14,2) not null check(agreed_price>0),
  platform_fee numeric(14,2) not null default 0,
  seller_net numeric(14,2) not null default 0,
  status text not null default 'pending_payment' check(status in ('pending_payment','paid','completed','cancelled','disputed','refunded')),
  payment_reference text,
  seller_credited_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.market_orders.
alter table public.market_orders add column if not exists id uuid default gen_random_uuid();
alter table public.market_orders add column if not exists listing_id uuid;
alter table public.market_orders add column if not exists buyer_id uuid;
alter table public.market_orders add column if not exists seller_id uuid;
alter table public.market_orders add column if not exists agreed_price numeric(14,2) default 0;
alter table public.market_orders add column if not exists platform_fee numeric(14,2) default 0;
alter table public.market_orders add column if not exists seller_net numeric(14,2) default 0;
alter table public.market_orders add column if not exists status text;
alter table public.market_orders add column if not exists payment_reference text;
alter table public.market_orders add column if not exists seller_credited_at timestamptz default now();
alter table public.market_orders add column if not exists created_at timestamptz default now();
alter table public.market_orders add column if not exists updated_at timestamptz default now();

create index if not exists mavora_market_orders_buyer_idx on public.market_orders(buyer_id,created_at desc);
create index if not exists mavora_market_orders_seller_idx on public.market_orders(seller_id,created_at desc);
alter table public.market_orders enable row level security;

drop policy if exists mavora_market_orders_participant_read on public.market_orders;
create policy mavora_market_orders_participant_read on public.market_orders for select to authenticated using(buyer_id=auth.uid() or seller_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

drop policy if exists mavora_market_orders_buyer_insert on public.market_orders;
create policy mavora_market_orders_buyer_insert on public.market_orders for insert to authenticated with check(buyer_id=auth.uid());

drop policy if exists mavora_market_orders_participant_update on public.market_orders;
create policy mavora_market_orders_participant_update on public.market_orders for update to authenticated using(buyer_id=auth.uid() or seller_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='founder')) with check(buyer_id=auth.uid() or seller_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

create or replace function public.mavora_create_market_order(p_listing_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_seller uuid; v_price numeric; v_status text; v_pct numeric; v_fee numeric; v_net numeric; v_id uuid;
begin
  select seller_id,price,status into v_seller,v_price,v_status from public.market_listings where id=p_listing_id and moderation_status='approved';
  if v_seller is null then return jsonb_build_object('success',false,'message','Market item is not available.'); end if;
  if v_seller=auth.uid() then return jsonb_build_object('success',false,'message','You cannot buy your own item.'); end if;
  if v_status not in ('active','reserved') then return jsonb_build_object('success',false,'message','This item is not available.'); end if;
  select seller_fee_percent into v_pct from public.market_fee_settings where id=1;
  v_fee=round(v_price*coalesce(v_pct,5)/100,2); v_net=v_price-v_fee;
  insert into public.market_orders(listing_id,buyer_id,seller_id,agreed_price,platform_fee,seller_net)
  values(p_listing_id,auth.uid(),v_seller,v_price,v_fee,v_net) returning id into v_id;
  update public.market_listings set status='reserved',updated_at=now() where id=p_listing_id and status='active';
  perform public.mavora_notify(v_seller,'Market order started','A buyer started secure checkout for your item.','marketMessages',p_listing_id,jsonb_build_object('order_id',v_id));
  return jsonb_build_object('success',true,'order_id',v_id,'agreed_price',v_price,'platform_fee',v_fee,'seller_net',v_net);
end;
$$;
revoke all on function public.mavora_create_market_order(uuid) from public;
grant execute on function public.mavora_create_market_order(uuid) to authenticated;


-- Called only by the marketplace payment Edge Function after Paystack verification.
create or replace function public.mavora_settle_market_order(p_order_id uuid,p_reference text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_order public.market_orders%rowtype; v_updated int;
begin
  select * into v_order from public.market_orders where id=p_order_id for update;
  if v_order.id is null then raise exception 'Market order not found'; end if;
  if v_order.payment_reference is not null and v_order.payment_reference<>p_reference then raise exception 'Payment reference mismatch'; end if;
  if v_order.status in ('paid','completed') then return jsonb_build_object('success',true,'already_settled',true); end if;

  update public.market_orders set status='paid',payment_reference=p_reference,updated_at=now() where id=p_order_id;
  -- Put seller earnings into pending balance until the buyer confirms receipt.
  if v_order.seller_credited_at is null and to_regclass('public.wallets') is not null then
    if not exists(select 1 from public.wallets where user_id=v_order.seller_id) then raise exception 'Seller wallet is not initialized'; end if;
    update public.wallets set pending_balance=coalesce(pending_balance,0)+v_order.seller_net,updated_at=now() where user_id=v_order.seller_id;
    update public.market_orders set seller_credited_at=now(),updated_at=now() where id=p_order_id;
  end if;
  update public.market_listings set status='sold',updated_at=now() where id=v_order.listing_id;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata)
  values(null,'market_sale_settled','market_order',p_order_id,jsonb_build_object('gross',v_order.agreed_price,'platform_fee',v_order.platform_fee,'seller_net',v_order.seller_net,'reference',p_reference));
  perform public.mavora_notify(v_order.seller_id,'Market sale paid','Payment was verified. Your seller earnings were added to your MAVORA wallet.','wallet',p_order_id,jsonb_build_object('seller_net',v_order.seller_net,'platform_fee',v_order.platform_fee));
  perform public.mavora_notify(v_order.buyer_id,'Market payment confirmed','Your Market payment was confirmed. Keep the item/order evidence inside MAVORA.','market',v_order.listing_id,jsonb_build_object('order_id',p_order_id));
  return jsonb_build_object('success',true,'seller_net',v_order.seller_net,'platform_fee',v_order.platform_fee);
end;
$$;
revoke all on function public.mavora_settle_market_order(uuid,text) from public;
grant execute on function public.mavora_settle_market_order(uuid,text) to service_role;


-- Buyer confirms receipt: move seller earnings from pending to available exactly once.
create or replace function public.mavora_confirm_market_receipt(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_order public.market_orders%rowtype;
begin
  select * into v_order from public.market_orders where id=p_order_id for update;
  if v_order.id is null then raise exception 'Market order not found'; end if;
  if auth.uid()<>v_order.buyer_id then raise exception 'Buyer access required'; end if;
  if v_order.status<>'paid' then return jsonb_build_object('success',false,'message','This order is not awaiting receipt confirmation.'); end if;
  if to_regclass('public.wallets') is null then raise exception 'Wallet system is not initialized'; end if;
  if v_order.seller_credited_at is null then raise exception 'Seller earnings were not reserved'; end if;
  if not exists(select 1 from public.wallets where user_id=v_order.seller_id and coalesce(pending_balance,0)>=v_order.seller_net) then raise exception 'Seller pending balance is not available for release'; end if;
  update public.wallets set pending_balance=coalesce(pending_balance,0)-v_order.seller_net,available_balance=coalesce(available_balance,0)+v_order.seller_net,updated_at=now() where user_id=v_order.seller_id;
  update public.market_orders set status='completed',updated_at=now() where id=p_order_id;
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata) values(auth.uid(),'market_order_completed','market_order',p_order_id,jsonb_build_object('seller_net',v_order.seller_net,'platform_fee',v_order.platform_fee));
  perform public.mavora_notify(v_order.seller_id,'Market order completed','The buyer confirmed receipt. Your Market earnings are now available in your MAVORA wallet.','wallet',p_order_id,'{}'::jsonb);
  perform public.mavora_notify(v_order.buyer_id,'Market order completed','Thanks. The order is marked completed.','marketOrders',p_order_id,'{}'::jsonb);
  return jsonb_build_object('success',true,'seller_net',v_order.seller_net);
end;
$$;
revoke all on function public.mavora_confirm_market_receipt(uuid) from public;
grant execute on function public.mavora_confirm_market_receipt(uuid) to authenticated;


-- ============================================================
-- 8) MARKET DISPUTES
-- ============================================================
create table if not exists public.market_disputes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.market_orders(id) on delete cascade,
  raised_by uuid not null references public.profiles(id) on delete cascade,
  reason text not null,
  evidence text,
  status text not null default 'open' check(status in ('open','under_review','resolved','rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.market_disputes.
alter table public.market_disputes add column if not exists id uuid default gen_random_uuid();
alter table public.market_disputes add column if not exists order_id uuid;
alter table public.market_disputes add column if not exists raised_by uuid;
alter table public.market_disputes add column if not exists reason text;
alter table public.market_disputes add column if not exists evidence text;
alter table public.market_disputes add column if not exists status text;
alter table public.market_disputes add column if not exists created_at timestamptz default now();
alter table public.market_disputes add column if not exists updated_at timestamptz default now();

alter table public.market_disputes enable row level security;
create index if not exists mavora_market_disputes_order_idx on public.market_disputes(order_id,created_at desc);

drop policy if exists mavora_market_disputes_read on public.market_disputes;
create policy mavora_market_disputes_read on public.market_disputes for select to authenticated using(raised_by=auth.uid() or exists(select 1 from public.market_orders o where o.id=order_id and (o.buyer_id=auth.uid() or o.seller_id=auth.uid())) or exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator')));
drop policy if exists mavora_market_disputes_insert on public.market_disputes;
create policy mavora_market_disputes_insert on public.market_disputes for insert to authenticated with check(raised_by=auth.uid());
drop policy if exists mavora_market_disputes_staff_update on public.market_disputes;
create policy mavora_market_disputes_staff_update on public.market_disputes for update to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator'))) with check(exists(select 1 from public.profiles where id=auth.uid() and role in ('founder','admin','moderator')));

create or replace function public.mavora_open_market_dispute(p_order_id uuid,p_reason text,p_evidence text default null)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_order public.market_orders%rowtype; v_id uuid;
begin
  select * into v_order from public.market_orders where id=p_order_id;
  if v_order.id is null then return jsonb_build_object('success',false,'message','Market order not found.'); end if;
  if auth.uid()<>v_order.buyer_id and auth.uid()<>v_order.seller_id then return jsonb_build_object('success',false,'message','You are not a participant in this order.'); end if;
  if length(trim(coalesce(p_reason,'')))<5 then return jsonb_build_object('success',false,'message','Explain the problem before opening a dispute.'); end if;
  if exists(select 1 from public.market_disputes where order_id=p_order_id and status in ('open','under_review')) then return jsonb_build_object('success',false,'message','A dispute is already open for this order.'); end if;
  insert into public.market_disputes(order_id,raised_by,reason,evidence) values(p_order_id,auth.uid(),trim(p_reason),nullif(trim(coalesce(p_evidence,'')),'')) returning id into v_id;
  update public.market_orders set status='disputed',updated_at=now() where id=p_order_id;
  perform public.mavora_notify(case when auth.uid()=v_order.buyer_id then v_order.seller_id else v_order.buyer_id end,'Market order dispute opened','A dispute was opened for a Market order. MAVORA support can review the order evidence.','marketOrders',p_order_id,jsonb_build_object('dispute_id',v_id));
  perform public.mavora_notify(auth.uid(),'Dispute opened','Your Market dispute is now recorded for review.','marketOrders',p_order_id,jsonb_build_object('dispute_id',v_id));
  return jsonb_build_object('success',true,'dispute_id',v_id);
end;
$$;
revoke all on function public.mavora_open_market_dispute(uuid,text,text) from public;
grant execute on function public.mavora_open_market_dispute(uuid,text,text) to authenticated;

-- ============================================================
-- 8) IMPORTANT NOTIFICATION TRIGGERS FOR EXISTING WORK FLOWS
-- ============================================================
create or replace function public.mavora_job_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if tg_op='INSERT' then
    if new.state is not null then
      insert into public.notifications(user_id,title,message,target_page,target_id,data)
      select p.id,'New work near you',left('A new job was posted: '||coalesce(new.title,'Job'),2000),'jobs',new.id,jsonb_build_object('job_id',new.id)
      from public.profiles p
      where p.id<>new.client_id and p.state=new.state and coalesce(p.availability,'')<>'busy';
    end if;
    perform public.mavora_notify(new.client_id,'Job posted','Your job is now recorded on MAVORA.','myjobs',new.id,'{}'::jsonb);
  elsif tg_op='UPDATE' and new.status is distinct from old.status then
    if new.status='closed' then perform public.mavora_notify(new.client_id,'Job closed','Your MAVORA job was closed.','myjobs',new.id,'{}'::jsonb); end if;
  end if;
  return new;
end $$;

create or replace function public.mavora_application_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_client uuid; v_title text;
begin
  select client_id,title into v_client,v_title from public.jobs where id=new.job_id;
  if tg_op='INSERT' then
    perform public.mavora_notify(v_client,'New job application','Someone applied for your job: '||coalesce(v_title,'Job'),'myjobs',new.job_id,jsonb_build_object('application_id',new.id));
  elsif tg_op='UPDATE' then
    if new.status is distinct from old.status or new.work_status is distinct from old.work_status then
      perform public.mavora_notify(new.worker_id,'Application / work status updated','Your application for '||coalesce(v_title,'a job')||' has an updated status.','applications',new.job_id,jsonb_build_object('application_id',new.id,'status',new.status,'work_status',new.work_status));
    end if;
  end if;
  return new;
end $$;

create or replace function public.mavora_message_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  perform public.mavora_notify(new.recipient_id,'New MAVORA message','You received a new message.','messages',new.id,'{}'::jsonb);
  return new;
end $$;

-- Create triggers only when the corresponding existing MAVORA table is present.
do $$
begin
  if to_regclass('public.jobs') is not null then
    drop trigger if exists mavora_job_notification on public.jobs;
    create trigger mavora_job_notification after insert or update of status on public.jobs for each row execute function public.mavora_job_notification_trigger();
  end if;
  if to_regclass('public.applications') is not null then
    drop trigger if exists mavora_application_notification on public.applications;
    create trigger mavora_application_notification after insert or update of status,work_status on public.applications for each row execute function public.mavora_application_notification_trigger();
  end if;
  if to_regclass('public.messages') is not null then
    drop trigger if exists mavora_message_notification on public.messages;
    create trigger mavora_message_notification after insert on public.messages for each row execute function public.mavora_message_notification_trigger();
  end if;
  drop trigger if exists mavora_market_message_notification on public.market_messages;
  create trigger mavora_market_message_notification after insert on public.market_messages for each row execute function public.mavora_message_notification_trigger();
end $$;

create or replace function public.mavora_market_listing_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.moderation_status is distinct from old.moderation_status then
    perform public.mavora_notify(new.seller_id,case when new.moderation_status='approved' then 'Market item approved' else 'Market item rejected' end,case when new.moderation_status='approved' then 'Your item is live in MAVORA Market.' else 'Your item needs attention before it can go live.' end,'market',new.id,jsonb_build_object('status',new.moderation_status,'reason',new.moderation_reason));
  end if;
  return new;
end $$;
drop trigger if exists mavora_market_listing_notification on public.market_listings;
create trigger mavora_market_listing_notification after update of moderation_status on public.market_listings for each row execute function public.mavora_market_listing_notification_trigger();

create or replace function public.mavora_identity_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status is distinct from old.status then
    perform public.mavora_notify(new.user_id,case when new.status='verified' then 'Identity approved' else 'Identity review updated' end,case when new.status='verified' then 'Your identity was approved.' else 'Your identity review status changed. Open Identity Verification for details.' end,'identity',new.id,jsonb_build_object('status',new.status,'reason',new.rejection_reason));
  end if;
  return new;
end $$;
drop trigger if exists mavora_identity_notification on public.identity_verifications;
create trigger mavora_identity_notification after update of status on public.identity_verifications for each row execute function public.mavora_identity_notification_trigger();


-- Contracts/work/withdrawals/transactions should also generate alerts where those tables exist.
create or replace function public.mavora_contract_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if tg_op='UPDATE' and new.status is distinct from old.status then
    perform public.mavora_notify(new.client_id,'Contract status updated','Your MAVORA contract status changed to '||coalesce(new.status,'updated')||'.','workroom',new.id,'{}'::jsonb);
    perform public.mavora_notify(new.worker_id,'Contract status updated','Your MAVORA contract status changed to '||coalesce(new.status,'updated')||'.','workroom',new.id,'{}'::jsonb);
  end if;
  return new;
end $$;

create or replace function public.mavora_submission_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_client uuid; v_title text;
begin
  select c.client_id,j.title into v_client,v_title from public.contracts c join public.jobs j on j.id=c.job_id where c.id=new.contract_id;
  if v_client is not null then perform public.mavora_notify(v_client,'Work submitted','A worker submitted work for '||coalesce(v_title,'your job')||'.','work',new.contract_id,jsonb_build_object('submission_id',new.id)); end if;
  return new;
end $$;

create or replace function public.mavora_withdrawal_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status is distinct from old.status then perform public.mavora_notify(new.user_id,'Withdrawal update','Your withdrawal request status changed to '||coalesce(new.status,'updated')||'.','wallet',new.id,jsonb_build_object('status',new.status)); end if;
  return new;
end $$;

create or replace function public.mavora_transaction_notification_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  perform public.mavora_notify(new.user_id,'Wallet transaction','A wallet transaction was recorded on your MAVORA account.','wallet',new.id,jsonb_build_object('status',new.status,'amount',new.amount));
  return new;
end $$;

do $$
begin
  if to_regclass('public.contracts') is not null then
    drop trigger if exists mavora_contract_notification on public.contracts;
    create trigger mavora_contract_notification after update of status on public.contracts for each row execute function public.mavora_contract_notification_trigger();
  end if;
  if to_regclass('public.work_submissions') is not null then
    drop trigger if exists mavora_submission_notification on public.work_submissions;
    create trigger mavora_submission_notification after insert on public.work_submissions for each row execute function public.mavora_submission_notification_trigger();
  end if;
  if to_regclass('public.withdrawals') is not null then
    drop trigger if exists mavora_withdrawal_notification on public.withdrawals;
    create trigger mavora_withdrawal_notification after update of status on public.withdrawals for each row execute function public.mavora_withdrawal_notification_trigger();
  end if;
  if to_regclass('public.transactions') is not null then
    drop trigger if exists mavora_transaction_notification on public.transactions;
    create trigger mavora_transaction_notification after insert on public.transactions for each row execute function public.mavora_transaction_notification_trigger();
  end if;
end $$;

-- ============================================================
-- 9) TIMESTAMPS
-- ============================================================
create or replace function public.mavora_touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;

do $$
begin
  drop trigger if exists mavora_market_profile_touch on public.market_profiles;
  create trigger mavora_market_profile_touch before update on public.market_profiles for each row execute function public.mavora_touch_updated_at();
  drop trigger if exists mavora_market_listing_touch on public.market_listings;
  create trigger mavora_market_listing_touch before update on public.market_listings for each row execute function public.mavora_touch_updated_at();
  drop trigger if exists mavora_market_order_touch on public.market_orders;
  create trigger mavora_market_order_touch before update on public.market_orders for each row execute function public.mavora_touch_updated_at();
  drop trigger if exists mavora_identity_touch on public.identity_verifications;
  create trigger mavora_identity_touch before update on public.identity_verifications for each row execute function public.mavora_touch_updated_at();
end $$;

-- ============================================================
-- 10) FOUNDER REVENUE FUNCTION
-- ============================================================
create or replace function public.mavora_market_revenue()
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v jsonb;
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='founder') then raise exception 'Founder access required'; end if;
  select jsonb_build_object(
    'completed_orders',count(*) filter(where status in ('paid','completed')),
    'gross_sales',coalesce(sum(agreed_price) filter(where status in ('paid','completed')),0),
    'platform_revenue',coalesce(sum(platform_fee) filter(where status in ('paid','completed')),0),
    'seller_earnings',coalesce(sum(seller_net) filter(where status in ('paid','completed')),0)
  ) into v from public.market_orders;
  return v;
end;
$$;
revoke all on function public.mavora_market_revenue() from public;
grant execute on function public.mavora_market_revenue() to authenticated;

-- ============================================================
-- 11) CONFIGURATION CHECKS
-- ============================================================
-- select to_regclass('public.identity_verifications') as identity_verifications,
--        to_regclass('public.market_profiles') as market_profiles,
--        to_regclass('public.market_listings') as market_listings,
--        to_regclass('public.market_messages') as market_messages,
--        to_regclass('public.market_orders') as market_orders;
--
-- select * from public.mavora_market_revenue;
-- ============================================================


-- ============================================================
-- MAVORA GOVERNANCE / STAFF / MODERATION LAYER
-- ============================================================
-- MAVORA FINAL BACKEND COMPATIBILITY PATCH
-- Run AFTER the existing MAVORA SQL foundation/migrations.
-- Additive where possible. No API keys or secrets belong in this file.

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- 1. PROFILE FIELDS USED BY THE FINAL HTML
-- ------------------------------------------------------------
alter table public.profiles add column if not exists role_updated_at timestamptz;
alter table public.profiles add column if not exists phone_verified boolean default false;
alter table public.profiles add column if not exists phone_verified_at timestamptz;
alter table public.profiles add column if not exists identity_verified boolean default false;
alter table public.profiles add column if not exists identity_verified_at timestamptz;

-- ------------------------------------------------------------
-- 2. SHARED STAFF HELPER
-- ------------------------------------------------------------
create or replace function public.mavora_is_staff()
returns boolean
language sql
stable
security definer
set search_path=public
as $$
  select exists(
    select 1 from public.profiles
    where id=auth.uid()
      and role in ('founder','admin','moderator')
  );
$$;
revoke all on function public.mavora_is_staff() from public;
grant execute on function public.mavora_is_staff() to authenticated;

-- ------------------------------------------------------------
-- 3. STAFF APPLICATIONS + ROLE AUDIT
-- ------------------------------------------------------------
create table if not exists public.staff_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  requested_role text not null default 'moderator' check(requested_role in ('moderator','admin')),
  reason text not null,
  status text not null default 'pending' check(status in ('pending','approved','rejected')),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.staff_applications.
alter table public.staff_applications add column if not exists id uuid default gen_random_uuid();
alter table public.staff_applications add column if not exists user_id uuid;
alter table public.staff_applications add column if not exists requested_role text;
alter table public.staff_applications add column if not exists reason text;
alter table public.staff_applications add column if not exists status text;
alter table public.staff_applications add column if not exists reviewed_by uuid;
alter table public.staff_applications add column if not exists reviewed_at timestamptz default now();
alter table public.staff_applications add column if not exists created_at timestamptz default now();


create table if not exists public.staff_role_audit (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  target_user_id uuid references public.profiles(id) on delete set null,
  old_role text,
  new_role text,
  action text not null,
  created_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.staff_role_audit.
alter table public.staff_role_audit add column if not exists id uuid default gen_random_uuid();
alter table public.staff_role_audit add column if not exists actor_id uuid;
alter table public.staff_role_audit add column if not exists target_user_id uuid;
alter table public.staff_role_audit add column if not exists old_role text;
alter table public.staff_role_audit add column if not exists new_role text;
alter table public.staff_role_audit add column if not exists action text;
alter table public.staff_role_audit add column if not exists created_at timestamptz default now();


alter table public.staff_applications enable row level security;
alter table public.staff_role_audit enable row level security;

drop policy if exists staff_apps_owner_read on public.staff_applications;
drop policy if exists staff_apps_owner_read on public.staff_applications;
create policy staff_apps_owner_read on public.staff_applications
for select to authenticated
using(user_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

drop policy if exists staff_apps_owner_insert on public.staff_applications;
drop policy if exists staff_apps_owner_insert on public.staff_applications;
create policy staff_apps_owner_insert on public.staff_applications
for insert to authenticated
with check(user_id=auth.uid() and requested_role in ('moderator','admin'));

drop policy if exists staff_apps_founder_update on public.staff_applications;
drop policy if exists staff_apps_founder_update on public.staff_applications;
create policy staff_apps_founder_update on public.staff_applications
for update to authenticated
using(exists(select 1 from public.profiles where id=auth.uid() and role='founder'))
with check(exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

drop policy if exists staff_audit_founder_read on public.staff_role_audit;
drop policy if exists staff_audit_founder_read on public.staff_role_audit;
create policy staff_audit_founder_read on public.staff_role_audit
for select to authenticated
using(exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

-- Only the Founder may assign/remove staff roles. The Founder role itself is protected.
create or replace function public.manage_staff_role(
  p_target_user_id uuid,
  p_new_role text
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_old_role text;
begin
  if not exists(select 1 from public.profiles where id=auth.uid() and role='founder') then
    raise exception 'Founder access required';
  end if;

  if p_new_role not in ('user','moderator','admin') then
    raise exception 'Invalid staff role';
  end if;

  if p_target_user_id=auth.uid() then
    raise exception 'The Founder role is protected';
  end if;

  select role into v_old_role from public.profiles where id=p_target_user_id for update;
  if not found then raise exception 'Target user not found'; end if;
  if v_old_role='founder' then raise exception 'The Founder role is protected'; end if;

  update public.profiles
  set role=p_new_role, role_updated_at=now(), updated_at=now()
  where id=p_target_user_id;

  insert into public.staff_role_audit(actor_id,target_user_id,old_role,new_role,action)
  values(auth.uid(),p_target_user_id,v_old_role,p_new_role,'role_changed');

  return jsonb_build_object('success',true,'old_role',v_old_role,'new_role',p_new_role);
end;
$$;
revoke all on function public.manage_staff_role(uuid,text) from public;
grant execute on function public.manage_staff_role(uuid,text) to authenticated;

-- Safe first-Founder bootstrap: the caller can only promote their own authenticated account,
-- and only when no Founder exists yet.
create or replace function public.initialize_founder(p_email text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
begin
  if exists(select 1 from public.profiles where role='founder') then
    raise exception 'A Founder already exists';
  end if;

  if lower(trim(coalesce(p_email,'')))<>lower(coalesce(auth.email(),'')) then
    raise exception 'Founder email must match the signed-in account';
  end if;

  update public.profiles
  set role='founder', role_updated_at=now(), updated_at=now()
  where id=auth.uid();

  insert into public.staff_role_audit(actor_id,target_user_id,old_role,new_role,action)
  values(auth.uid(),auth.uid(),'user','founder','founder_initialized');

  return jsonb_build_object('success',true);
end;
$$;
revoke all on function public.initialize_founder(text) from public;
grant execute on function public.initialize_founder(text) to authenticated;

-- ------------------------------------------------------------
-- 4. IDENTITY VERIFICATION
-- ------------------------------------------------------------
create table if not exists public.identity_verifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  document_type text not null,
  document_number text not null,
  document_path text not null,
  status text not null default 'pending' check(status in ('pending','verified','rejected')),
  rejection_reason text,
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.identity_verifications.
alter table public.identity_verifications add column if not exists id uuid default gen_random_uuid();
alter table public.identity_verifications add column if not exists user_id uuid;
alter table public.identity_verifications add column if not exists document_type text;
alter table public.identity_verifications add column if not exists document_number text;
alter table public.identity_verifications add column if not exists document_path text;
alter table public.identity_verifications add column if not exists face_path text;
alter table public.identity_verifications add column if not exists face_status text;
alter table public.identity_verifications add column if not exists liveness_status text;
alter table public.identity_verifications add column if not exists status text;
alter table public.identity_verifications add column if not exists review_due_at timestamptz default now();
alter table public.identity_verifications add column if not exists reviewed_at timestamptz default now();
alter table public.identity_verifications add column if not exists reviewed_by uuid;
alter table public.identity_verifications add column if not exists rejection_reason text;
alter table public.identity_verifications add column if not exists created_at timestamptz default now();
alter table public.identity_verifications add column if not exists updated_at timestamptz default now();


create index if not exists identity_verifications_user_idx on public.identity_verifications(user_id,created_at desc);
create unique index if not exists identity_one_pending_per_user on public.identity_verifications(user_id) where status='pending';

alter table public.identity_verifications enable row level security;

drop policy if exists identity_owner_read on public.identity_verifications;
drop policy if exists identity_owner_read on public.identity_verifications;
create policy identity_owner_read on public.identity_verifications
for select to authenticated
using(user_id=auth.uid() or public.mavora_is_staff());

drop policy if exists identity_owner_insert on public.identity_verifications;
drop policy if exists identity_owner_insert on public.identity_verifications;
create policy identity_owner_insert on public.identity_verifications
for insert to authenticated
with check(user_id=auth.uid());

insert into storage.buckets(id,name,public)
values('mavora-identity','mavora-identity',false)
on conflict(id) do update set public=false;

drop policy if exists mavora_identity_insert_own on storage.objects;
drop policy if exists mavora_identity_insert_own on storage.objects;
create policy mavora_identity_insert_own on storage.objects
for insert to authenticated
with check(bucket_id='mavora-identity' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists mavora_identity_select_owner_staff on storage.objects;
drop policy if exists mavora_identity_select_owner_staff on storage.objects;
create policy mavora_identity_select_owner_staff on storage.objects
for select to authenticated
using(bucket_id='mavora-identity' and ((storage.foldername(name))[1]=auth.uid()::text or public.mavora_is_staff()));

create or replace function public.review_identity_verification(
  p_verification_id uuid,
  p_status text,
  p_rejection_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_user_id uuid;
begin
  if not public.mavora_is_staff() then raise exception 'Staff access required'; end if;
  if p_status not in ('verified','rejected') then raise exception 'Invalid verification status'; end if;

  select user_id into v_user_id
  from public.identity_verifications
  where id=p_verification_id
  for update;

  if not found then raise exception 'Identity verification not found'; end if;

  update public.identity_verifications
  set status=p_status,
      rejection_reason=case when p_status='rejected' then nullif(trim(p_rejection_reason),'') else null end,
      reviewed_by=auth.uid(),
      reviewed_at=now()
  where id=p_verification_id;

  update public.profiles
  set identity_verified=(p_status='verified'),
      identity_verified_at=case when p_status='verified' then now() else null end,
      updated_at=now()
  where id=v_user_id;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata)
  values(auth.uid(),'identity_reviewed','identity_verification',p_verification_id,
         jsonb_build_object('status',p_status,'user_id',v_user_id));

  return jsonb_build_object('success',true,'status',p_status);
end;
$$;
revoke all on function public.review_identity_verification(uuid,text,text) from public;
grant execute on function public.review_identity_verification(uuid,text,text) to authenticated;

-- ------------------------------------------------------------
-- 5. REVIEWS / RATINGS
-- ------------------------------------------------------------
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.jobs(id) on delete set null,
  reviewer_id uuid not null references public.profiles(id) on delete cascade,
  reviewee_id uuid not null references public.profiles(id) on delete cascade,
  rating integer not null check(rating between 1 and 5),
  review text,
  created_at timestamptz not null default now(),
  unique(job_id,reviewer_id,reviewee_id)
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.reviews.
alter table public.reviews add column if not exists id uuid default gen_random_uuid();
alter table public.reviews add column if not exists job_id uuid;
alter table public.reviews add column if not exists reviewer_id uuid;
alter table public.reviews add column if not exists reviewee_id uuid;
alter table public.reviews add column if not exists rating integer default 0;
alter table public.reviews add column if not exists review text;
alter table public.reviews add column if not exists created_at timestamptz default now();


alter table public.reviews enable row level security;
drop policy if exists reviews_read_all_auth on public.reviews;
create policy reviews_read_all_auth on public.reviews for select to authenticated using(true);
-- Ratings are inserted through the secure RPC below, not by the client directly.
drop policy if exists reviews_insert_direct on public.reviews;

create or replace function public.submit_rating(
  p_contract_id uuid,
  p_reviewee_id uuid,
  p_rating integer,
  p_review text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_job_id uuid;
  v_client_id uuid;
  v_worker_id uuid;
begin
  select job_id,client_id,worker_id into v_job_id,v_client_id,v_worker_id
  from public.contracts where id=p_contract_id and status='completed';
  if not found then raise exception 'Completed contract not found'; end if;
  if auth.uid() not in (v_client_id,v_worker_id) then raise exception 'Not authorized to rate this contract'; end if;
  if p_reviewee_id=auth.uid() or p_reviewee_id not in (v_client_id,v_worker_id) then raise exception 'Invalid reviewee'; end if;
  if p_rating<1 or p_rating>5 then raise exception 'Rating must be between 1 and 5'; end if;

  insert into public.reviews(job_id,reviewer_id,reviewee_id,rating,review)
  values(v_job_id,auth.uid(),p_reviewee_id,p_rating,nullif(trim(p_review),''));

  return jsonb_build_object('success',true);
exception when unique_violation then
  raise exception 'You already rated this user for this job';
end;
$$;
revoke all on function public.submit_rating(uuid,uuid,integer,text) from public;
grant execute on function public.submit_rating(uuid,uuid,integer,text) to authenticated;

create or replace function public.refresh_mavora_profile_rating()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  update public.profiles p
  set rating=coalesce((select round(avg(r.rating)::numeric,2) from public.reviews r where r.reviewee_id=coalesce(new.reviewee_id,old.reviewee_id)),0),
      updated_at=now()
  where p.id=coalesce(new.reviewee_id,old.reviewee_id);
  return coalesce(new,old);
end;
$$;

drop trigger if exists trg_refresh_mavora_profile_rating on public.reviews;
create trigger trg_refresh_mavora_profile_rating
after insert or update or delete on public.reviews
for each row execute function public.refresh_mavora_profile_rating();

-- ------------------------------------------------------------
-- 6. WORKFLOW RPC COMPATIBILITY
-- ------------------------------------------------------------
create or replace function public.request_work_revision(
  p_application_id uuid,
  p_note text
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_worker_id uuid;
begin
  select a.worker_id into v_worker_id
  from public.applications a
  join public.jobs j on j.id=a.job_id
  where a.id=p_application_id
    and j.client_id=auth.uid()
    and a.status='hired'
    and a.work_status='submitted'
  for update;

  if not found then raise exception 'This work is not ready for revision'; end if;
  if not length(trim(coalesce(p_note,'')))>0 then raise exception 'Revision note is required'; end if;

  update public.applications
  set work_status='revision_requested', revision_note=trim(p_note), updated_at=now()
  where id=p_application_id;

  insert into public.revision_requests(application_id,requester_id,note,status)
  values(p_application_id,auth.uid(),trim(p_note),'open');

  insert into public.notifications(user_id,message,target_page,target_id)
  values(v_worker_id,'The client requested a revision to your submitted work.','work',p_application_id);

  return jsonb_build_object('success',true);
end;
$$;
revoke all on function public.request_work_revision(uuid,text) from public;
grant execute on function public.request_work_revision(uuid,text) to authenticated;

create or replace function public.approve_work(p_application_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_worker_id uuid;
  v_job_id uuid;
  v_contract_id uuid;
begin
  select a.worker_id,a.job_id,c.id
  into v_worker_id,v_job_id,v_contract_id
  from public.applications a
  join public.jobs j on j.id=a.job_id
  left join public.contracts c on c.application_id=a.id
  where a.id=p_application_id
    and j.client_id=auth.uid()
    and a.status='hired'
    and a.work_status='submitted'
  for update;

  if not found then raise exception 'This work is not ready for approval'; end if;

  update public.applications
  set work_status='completed',completed_at=now(),updated_at=now()
  where id=p_application_id;

  update public.jobs set status='completed',updated_at=now() where id=v_job_id;

  if v_contract_id is not null then
    update public.contracts set status='completed',updated_at=now() where id=v_contract_id;
  end if;

  update public.profiles
  set completed_jobs=coalesce(completed_jobs,0)+1,updated_at=now()
  where id=v_worker_id;

  insert into public.notifications(user_id,message,target_page,target_id)
  values(v_worker_id,'Your work has been approved and the job is completed.','work',p_application_id);

  if v_contract_id is not null then
    begin
      insert into public.proof_of_work(user_id,contract_id,title,summary,status,verified_at)
      select v_worker_id,c.id,j.title,'Completed and approved MAVORA work.','verified',now()
      from public.contracts c join public.jobs j on j.id=c.job_id
      where c.id=v_contract_id
        and not exists(select 1 from public.proof_of_work p where p.contract_id=v_contract_id and p.status='verified');
    exception when others then
      null;
    end;
  end if;

  return jsonb_build_object('success',true,'contract_id',v_contract_id);
end;
$$;
revoke all on function public.approve_work(uuid) from public;
grant execute on function public.approve_work(uuid) to authenticated;

-- ------------------------------------------------------------
-- 7. BUSINESS TEAM RPC
-- ------------------------------------------------------------
create or replace function public.business_add_member(
  p_business_id uuid,
  p_member_email text,
  p_role text default 'member'
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_member_user uuid;
  v_id uuid;
begin
  if p_role not in ('member','manager','admin') then raise exception 'Invalid team role'; end if;
  if not exists(select 1 from public.business_profiles where id=p_business_id and owner_id=auth.uid()) then raise exception 'Business owner access required'; end if;
  if not regexp_like(trim(p_member_email),'^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$') then raise exception 'Enter a valid email'; end if;

  select id into v_member_user from public.profiles where lower(email)=lower(trim(p_member_email)) limit 1;

  insert into public.business_members(business_id,member_user_id,member_email,role,status)
  values(p_business_id,v_member_user,lower(trim(p_member_email)),p_role,case when v_member_user is null then 'invited' else 'active' end)
  returning id into v_id;

  return jsonb_build_object('success',true,'id',v_id,'matched_user',v_member_user is not null);
exception when unique_violation then
  raise exception 'That email is already on the team';
end;
$$;
revoke all on function public.business_add_member(uuid,text,text) from public;
grant execute on function public.business_add_member(uuid,text,text) to authenticated;

-- ------------------------------------------------------------
-- 8. MODERATION QUEUES
-- ------------------------------------------------------------
alter table public.reports enable row level security;
alter table public.disputes enable row level security;
alter table public.support_tickets enable row level security;

drop policy if exists reports_owner_or_staff_read on public.reports;
create policy reports_owner_or_staff_read on public.reports for select to authenticated
using(reporter_id=auth.uid() or public.mavora_is_staff());
drop policy if exists reports_owner_insert on public.reports;
create policy reports_owner_insert on public.reports for insert to authenticated with check(reporter_id=auth.uid());
drop policy if exists reports_staff_update on public.reports;
create policy reports_staff_update on public.reports for update to authenticated using(public.mavora_is_staff()) with check(public.mavora_is_staff());

drop policy if exists disputes_participant_or_staff_read on public.disputes;
create policy disputes_participant_or_staff_read on public.disputes for select to authenticated
using(opened_by=auth.uid() or public.mavora_is_staff() or exists(select 1 from public.applications a join public.jobs j on j.id=a.job_id where a.id=application_id and (a.worker_id=auth.uid() or j.client_id=auth.uid())));
drop policy if exists disputes_owner_insert on public.disputes;
create policy disputes_owner_insert on public.disputes for insert to authenticated with check(opened_by=auth.uid());
drop policy if exists disputes_staff_update on public.disputes;
create policy disputes_staff_update on public.disputes for update to authenticated using(public.mavora_is_staff()) with check(public.mavora_is_staff());

drop policy if exists support_owner_or_staff_read on public.support_tickets;
create policy support_owner_or_staff_read on public.support_tickets for select to authenticated
using(user_id=auth.uid() or public.mavora_is_staff());
drop policy if exists support_owner_insert on public.support_tickets;
create policy support_owner_insert on public.support_tickets for insert to authenticated with check(user_id=auth.uid());
drop policy if exists support_staff_update on public.support_tickets;
create policy support_staff_update on public.support_tickets for update to authenticated using(public.mavora_is_staff()) with check(public.mavora_is_staff());

create or replace function public.moderate_queue_item(
  p_type text,
  p_id uuid,
  p_status text,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.mavora_is_staff() then raise exception 'Staff access required'; end if;

  if p_type='report' then
    update public.reports set status=p_status where id=p_id;
    if not found then raise exception 'Report not found'; end if;
  elsif p_type='support' then
    update public.support_tickets set status=p_status,updated_at=now() where id=p_id;
    if not found then raise exception 'Support ticket not found'; end if;
  elsif p_type='dispute' then
    update public.disputes set status=p_status,resolution=nullif(trim(p_note),'') ,updated_at=now() where id=p_id;
    if not found then raise exception 'Dispute not found'; end if;
  else
    raise exception 'Invalid queue type';
  end if;

  insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata)
  values(auth.uid(),'moderation_action',p_type,p_id,jsonb_build_object('status',p_status,'note',p_note));

  return jsonb_build_object('success',true);
end;
$$;
revoke all on function public.moderate_queue_item(text,uuid,text,text) from public;
grant execute on function public.moderate_queue_item(text,uuid,text,text) to authenticated;

-- ------------------------------------------------------------
-- 9. FOUNDER FINANCE / SECURITY READ ACCESS
-- ------------------------------------------------------------
alter table public.transactions enable row level security;
alter table public.withdrawals enable row level security;

drop policy if exists transactions_founder_read on public.transactions;
create policy transactions_founder_read on public.transactions for select to authenticated
using(user_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

drop policy if exists withdrawals_founder_read on public.withdrawals;
create policy withdrawals_founder_read on public.withdrawals for select to authenticated
using(user_id=auth.uid() or exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

drop policy if exists audit_logs_founder_read on public.audit_logs;
create policy audit_logs_founder_read on public.audit_logs for select to authenticated
using(exists(select 1 from public.profiles where id=auth.uid() and role='founder'));

-- ------------------------------------------------------------
-- 10. STORAGE + NOTIFICATION SAFETY
-- ------------------------------------------------------------
insert into storage.buckets(id,name,public)
values('mavora-work','mavora-work',false)
on conflict(id) do update set public=false;

-- ------------------------------------------------------------
-- 11. FINAL HEALTH CHECK QUERIES (READ ONLY)
-- Run these separately if you want to verify the backend.
-- ------------------------------------------------------------
-- select to_regclass('public.staff_applications') as staff_applications,
--        to_regclass('public.identity_verifications') as identity_verifications,
--        to_regclass('public.reviews') as reviews,
--        to_regclass('public.business_members') as business_members;
--
-- select proname from pg_proc
-- where proname in ('manage_staff_role','initialize_founder','review_identity_verification',
--                   'submit_rating','request_work_revision','approve_work',
--                   'business_add_member','moderate_queue_item')
-- order by proname;

-- END MAVORA FINAL BACKEND PATCH


-- ============================================================
-- MAVORA KYC REVIEW ADDON
-- ============================================================
-- ============================================================
-- MAVORA KYC REVIEW ADD-ON
-- Additive migration for the Sellora-style onboarding sequence:
-- verified account -> email -> phone -> identity document -> staff review
--
-- This DOES NOT remove existing identity rows or change the existing
-- verified/rejected status values. It adds an explicit staff-review
-- start timestamp so the user-facing status can move from:
-- Pending Review -> Under Review -> Verified / Rejected.
--
-- Run this in the Supabase SQL Editor after the existing MAVORA backend SQL.
-- ============================================================

-- 1) Add an explicit review-start timestamp.
alter table public.identity_verifications
  add column if not exists review_started_at timestamptz;

-- 2) Keep the 24-48 hour review guidance backed by a server timestamp.
--    If a new verification is inserted without a due time, set a 48-hour
--    target. This is a review target, NOT automatic approval.
create or replace function public.mavora_identity_set_review_window()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  if new.review_due_at is null then
    new.review_due_at := now() + interval '48 hours';
  end if;
  return new;
end;
$$;

revoke all on function public.mavora_identity_set_review_window() from public;
grant execute on function public.mavora_identity_set_review_window() to authenticated;

drop trigger if exists mavora_identity_set_review_window on public.identity_verifications;
drop trigger if exists mavora_identity_set_review_window on public.identity_verifications;
create trigger mavora_identity_set_review_window
before insert on public.identity_verifications
for each row
execute function public.mavora_identity_set_review_window();

-- 3) Staff action that changes a pending request to "Under Review".
create or replace function public.mavora_start_identity_review(
  p_verification_id uuid,
  p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_user uuid;
  v_started timestamptz;
  v_due timestamptz;
begin
  if not exists (
    select 1
    from public.profiles
    where id=auth.uid()
      and role in ('founder','admin','moderator')
  ) then
    raise exception 'Staff access required';
  end if;

  select user_id,review_started_at,review_due_at
    into v_user,v_started,v_due
  from public.identity_verifications
  where id=p_verification_id;

  if v_user is null then
    raise exception 'Identity verification not found';
  end if;

  if exists (
    select 1 from public.identity_verifications
    where id=p_verification_id and status <> 'pending'
  ) then
    return jsonb_build_object('success',false,'message','This identity request is no longer pending.');
  end if;

  update public.identity_verifications
  set review_started_at=coalesce(review_started_at,now()),
      review_due_at=coalesce(review_due_at,v_due,now()+interval '48 hours'),
      updated_at=now()
  where id=p_verification_id;

  -- Notify the owner without exposing document details.
  perform public.mavora_notify(
    v_user,
    'KYC review started',
    'An authorized MAVORA staff member has started reviewing your submitted identity document.',
    'identity',
    p_verification_id,
    jsonb_build_object('review_due_at',coalesce(v_due,now()+interval '48 hours'))
  );

  return jsonb_build_object(
    'success',true,
    'status','under_review',
    'review_started_at',now(),
    'review_due_at',coalesce(v_due,now()+interval '48 hours')
  );
end;
$$;

revoke all on function public.mavora_start_identity_review(uuid,text) from public;
grant execute on function public.mavora_start_identity_review(uuid,text) to authenticated;

-- 4) Fast staff-queue lookup.
create index if not exists mavora_identity_review_queue_idx
on public.identity_verifications(status,review_started_at,created_at desc);

-- ============================================================
-- Verification query (safe to run after the migration)
-- ============================================================
-- select id,status,review_started_at,review_due_at,created_at,reviewed_at
-- from public.identity_verifications
-- order by created_at desc
-- limit 20;

-- ============================================================
-- FINAL COMPATIBILITY / FRONTEND DEPENDENCY FIXES
-- These are the pieces found by comparing MAVORA_ROUNDED_FINAL.html
-- against the consolidated backend.
-- ============================================================

-- Profile fields used by the final HTML.
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists gender text;
alter table public.profiles add column if not exists profile_visibility text default 'public';
alter table public.profiles add column if not exists business_mode boolean default false;
alter table public.profiles add column if not exists role_updated_at timestamptz;
alter table public.profiles add column if not exists phone_verified boolean default false;
alter table public.profiles add column if not exists phone_verified_at timestamptz;
alter table public.profiles add column if not exists identity_verified boolean default false;
alter table public.profiles add column if not exists identity_verified_at timestamptz;

-- Final HTML reads these workflow fields.
alter table public.applications add column if not exists completed_at timestamptz;
alter table public.jobs add column if not exists hired_worker_id uuid references public.profiles(id) on delete set null;

-- Services are discoverable and manageable by their owner.
alter table public.services enable row level security;
drop policy if exists services_select_active on public.services;
drop policy if exists services_select_own on public.services;
drop policy if exists services_insert_own on public.services;
drop policy if exists services_update_own on public.services;
drop policy if exists services_delete_own on public.services;
drop policy if exists services_select_active on public.services;
create policy services_select_active on public.services for select to authenticated using(status='active' or user_id=auth.uid());
drop policy if exists services_insert_own on public.services;
create policy services_insert_own on public.services for insert to authenticated with check(user_id=auth.uid());
drop policy if exists services_update_own on public.services;
create policy services_update_own on public.services for update to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
drop policy if exists services_delete_own on public.services;
create policy services_delete_own on public.services for delete to authenticated using(user_id=auth.uid());

-- Ensure wallets exist for every existing profile.
insert into public.wallets(user_id)
select p.id from public.profiles p
where not exists(select 1 from public.wallets w where w.user_id=p.id);

-- ============================================================
-- PAYMENT / HIRING COMPATIBILITY
-- ============================================================

-- Worker selection must create a pending-payment contract first.
-- Payment is not considered complete until pay_job_from_wallet succeeds.
create or replace function public.choose_worker(p_job_id uuid,p_application_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_job public.jobs%rowtype;
  v_app public.applications%rowtype;
  v_contract uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select * into v_job from public.jobs where id=p_job_id for update;
  if not found then raise exception 'Job not found'; end if;
  if v_job.client_id<>auth.uid() then raise exception 'Only the client can choose a worker'; end if;
  if v_job.status not in ('open','awaiting_payment') then raise exception 'This job is not available for hiring'; end if;

  select * into v_app
  from public.applications
  where id=p_application_id and job_id=p_job_id and status='pending'
  for update;
  if not found then raise exception 'Application not found or already processed'; end if;

  if exists(select 1 from public.contracts where job_id=p_job_id and status in ('pending_payment','pending','active')) then
    raise exception 'Job already has an active contract';
  end if;

  update public.applications
  set status='not_selected',updated_at=now()
  where job_id=p_job_id and status='pending' and id<>p_application_id;

  update public.applications
  set status='hired',work_status='not_started',updated_at=now()
  where id=p_application_id;

  insert into public.contracts(job_id,application_id,client_id,worker_id,agreed_price,deadline,status,terms_snapshot)
  values(p_job_id,p_application_id,auth.uid(),v_app.worker_id,v_app.proposed_price,v_job.deadline,'pending_payment',
         jsonb_build_object('job_title',v_job.title,'description',v_job.description,'budget',v_job.budget,'agreed_price',v_app.proposed_price))
  returning id into v_contract;

  update public.jobs
  set status='awaiting_payment',hired_worker_id=v_app.worker_id,updated_at=now()
  where id=p_job_id;

  perform public.mavora_notify(v_app.worker_id,'Worker selected','You were selected for "'||coalesce(v_job.title,'MAVORA work')||'". Payment must be secured before work starts.','work',p_application_id,jsonb_build_object('contract_id',v_contract));
  perform public.mavora_notify(auth.uid(),'Worker selected','The worker was selected. Secure the agreed payment before work starts.','myjobs',p_job_id,jsonb_build_object('contract_id',v_contract));

  return jsonb_build_object('success',true,'application_id',p_application_id,'contract_id',v_contract,'payment_amount',v_app.proposed_price,'agreed_price',v_app.proposed_price);
end;
$$;
revoke all on function public.choose_worker(uuid,uuid) from public;
grant execute on function public.choose_worker(uuid,uuid) to authenticated;

-- Secure wallet payment for a hired job. This holds the agreed amount until approval.
create or replace function public.pay_job_from_wallet(p_application_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_app public.applications%rowtype;
  v_job public.jobs%rowtype;
  v_contract public.contracts%rowtype;
  v_balance numeric;
  v_amount numeric;
  v_ref text;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;

  select * into v_app from public.applications where id=p_application_id and status='hired' for update;
  if not found then raise exception 'Hired application not found'; end if;

  select * into v_job from public.jobs where id=v_app.job_id for update;
  if not found or v_job.client_id<>auth.uid() then raise exception 'Only the job client can pay'; end if;

  select * into v_contract from public.contracts where application_id=p_application_id for update;
  if not found then raise exception 'Contract not found'; end if;
  if v_contract.status not in ('pending_payment','pending') then
    return jsonb_build_object('success',false,'message','This job is not awaiting payment.');
  end if;

  v_amount:=greatest(0,coalesce(v_contract.agreed_price,v_app.proposed_price,0));
  if v_amount<=0 then raise exception 'Invalid payment amount'; end if;

  select available_balance into v_balance from public.wallets where user_id=auth.uid() for update;
  if coalesce(v_balance,0)<v_amount then
    return jsonb_build_object('success',false,'reason','insufficient_balance','message','Insufficient wallet balance.','required_amount',v_amount,'available_balance',coalesce(v_balance,0),'shortfall',v_amount-coalesce(v_balance,0));
  end if;

  v_ref:='JOB-'||p_application_id::text||'-'||extract(epoch from clock_timestamp())::bigint;

  update public.wallets
  set available_balance=available_balance-v_amount,
      held_balance=coalesce(held_balance,0)+v_amount,
      updated_at=now()
  where user_id=auth.uid();

  update public.contracts
  set status='active',start_at=coalesce(start_at,now()),updated_at=now()
  where id=v_contract.id;

  update public.jobs set status='in_progress',updated_at=now() where id=v_job.id;
  update public.applications set work_status='in_progress',updated_at=now() where id=p_application_id;

  insert into public.transactions(user_id,type,amount,status,reference,provider,metadata)
  values(auth.uid(),'job_payment',v_amount,'paid',v_ref,'mavora_wallet',jsonb_build_object('application_id',p_application_id,'contract_id',v_contract.id,'held',true));

  perform public.mavora_notify(v_app.worker_id,'Payment secured','The client secured the agreed payment. You can start/continue the work.','work',p_application_id,jsonb_build_object('contract_id',v_contract.id,'amount',v_amount));

  return jsonb_build_object('success',true,'amount',v_amount,'reference',v_ref,'contract_id',v_contract.id);
end;
$$;
revoke all on function public.pay_job_from_wallet(uuid) from public;
grant execute on function public.pay_job_from_wallet(uuid) to authenticated;

-- Request revision compatibility used by the final HTML.
create or replace function public.request_revision(p_application_id uuid,p_note text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
begin
  return public.request_work_revision(p_application_id,p_note);
end;
$$;
revoke all on function public.request_revision(uuid,text) from public;
grant execute on function public.request_revision(uuid,text) to authenticated;

-- Final work approval releases the held job payment exactly once.
create or replace function public.approve_work(p_application_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_app public.applications%rowtype;
  v_job public.jobs%rowtype;
  v_contract public.contracts%rowtype;
  v_amount numeric;
  v_already boolean:=false;
begin
  select * into v_app from public.applications where id=p_application_id for update;
  if not found then raise exception 'Application not found'; end if;
  select * into v_job from public.jobs where id=v_app.job_id for update;
  if not found or v_job.client_id<>auth.uid() then raise exception 'Client access required'; end if;
  select * into v_contract from public.contracts where application_id=p_application_id for update;
  if not found then raise exception 'Contract not found'; end if;

  if v_contract.status='completed' and v_app.work_status='completed' then
    v_already:=true;
    return jsonb_build_object('success',true,'already_completed',true,'contract_id',v_contract.id);
  end if;
  if v_app.status<>'hired' or v_app.work_status<>'submitted' then raise exception 'This work is not ready for approval'; end if;

  v_amount:=coalesce(v_contract.agreed_price,0);

  if coalesce(v_amount,0)>0 then
    if exists(select 1 from public.wallets where user_id=v_job.client_id and coalesce(held_balance,0)>=v_amount) then
      update public.wallets set held_balance=held_balance-v_amount,updated_at=now() where user_id=v_job.client_id;
      update public.wallets set available_balance=available_balance+v_amount,updated_at=now() where user_id=v_app.worker_id;
      insert into public.transactions(user_id,type,amount,status,reference,provider,metadata)
      values(v_app.worker_id,'job_earnings',v_amount,'paid','EARN-'||p_application_id::text||'-'||extract(epoch from clock_timestamp())::bigint,'mavora_wallet',jsonb_build_object('application_id',p_application_id,'contract_id',v_contract.id));
    else
      raise exception 'Held payment is not available for this job';
    end if;
  end if;

  update public.applications set work_status='completed',completed_at=now(),updated_at=now() where id=p_application_id;
  update public.contracts set status='completed',updated_at=now() where id=v_contract.id;
  update public.jobs set status='completed',updated_at=now() where id=v_job.id;
  update public.profiles set completed_jobs=coalesce(completed_jobs,0)+1,updated_at=now() where id=v_app.worker_id;

  begin
    insert into public.proof_of_work(user_id,contract_id,title,summary,status,verified_at)
    values(v_app.worker_id,v_contract.id,v_job.title,'Completed and approved MAVORA work.','verified',now())
    on conflict do nothing;
  exception when others then null;
  end;

  perform public.mavora_notify(v_app.worker_id,'Work approved','Your work was approved and the held payment was released to your MAVORA wallet.','work',p_application_id,jsonb_build_object('amount',v_amount));
  return jsonb_build_object('success',true,'contract_id',v_contract.id,'amount',v_amount,'already_completed',v_already);
end;
$$;
revoke all on function public.approve_work(uuid) from public;
grant execute on function public.approve_work(uuid) to authenticated;

-- ============================================================
-- KYC / STAFF COMPATIBILITY
-- ============================================================

-- The final HTML calls this exact moderation wrapper in some moderator paths.
create or replace function public.mavora_moderation_action(p_report_id uuid,p_action text,p_note text default null)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
begin
  if not public.mavora_is_staff() then raise exception 'Staff access required'; end if;
  if p_action not in ('reviewing','resolved','dismissed','removed') then raise exception 'Invalid moderation action'; end if;
  return public.moderate_queue_item('report',p_report_id,p_action,nullif(trim(coalesce(p_note,'')),''));
end;
$$;
revoke all on function public.mavora_moderation_action(uuid,text,text) from public;
grant execute on function public.mavora_moderation_action(uuid,text,text) to authenticated;

-- KYC review status uses review_started_at + review_due_at; no automatic approval.
alter table public.identity_verifications add column if not exists review_started_at timestamptz;
alter table public.identity_verifications add column if not exists review_due_at timestamptz;
alter table public.identity_verifications add column if not exists updated_at timestamptz default now();

create or replace function public.mavora_identity_set_review_window()
returns trigger
language plpgsql
security definer
set search_path=public
as $$
begin
  if new.review_due_at is null then new.review_due_at:=now()+interval '48 hours'; end if;
  return new;
end;
$$;
revoke all on function public.mavora_identity_set_review_window() from public;
grant execute on function public.mavora_identity_set_review_window() to authenticated;
drop trigger if exists mavora_identity_set_review_window on public.identity_verifications;
create trigger mavora_identity_set_review_window before insert on public.identity_verifications for each row execute function public.mavora_identity_set_review_window();

create or replace function public.mavora_start_identity_review(p_verification_id uuid,p_note text default null)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_user uuid; v_due timestamptz;
begin
  if not public.mavora_is_staff() then raise exception 'Staff access required'; end if;
  select user_id,review_due_at into v_user,v_due from public.identity_verifications where id=p_verification_id;
  if v_user is null then raise exception 'Identity verification not found'; end if;
  if exists(select 1 from public.identity_verifications where id=p_verification_id and status<>'pending') then
    return jsonb_build_object('success',false,'message','This identity request is no longer pending.');
  end if;
  update public.identity_verifications
  set review_started_at=coalesce(review_started_at,now()),review_due_at=coalesce(review_due_at,now()+interval '48 hours'),updated_at=now()
  where id=p_verification_id;
  perform public.mavora_notify(v_user,'KYC review started','An authorized MAVORA staff member has started reviewing your submitted identity document.','identity',p_verification_id,jsonb_build_object('review_due_at',coalesce(v_due,now()+interval '48 hours')));
  return jsonb_build_object('success',true,'status','under_review','review_started_at',now(),'review_due_at',coalesce(v_due,now()+interval '48 hours'));
end;
$$;
revoke all on function public.mavora_start_identity_review(uuid,text) from public;
grant execute on function public.mavora_start_identity_review(uuid,text) to authenticated;
create index if not exists mavora_identity_review_queue_idx on public.identity_verifications(status,review_started_at,created_at desc);

-- Fix the proof-of-work RPC from the earlier foundation: it must use MAVORA roles, not a missing is_admin column.
create or replace function public.create_verified_proof_of_work(p_contract_id uuid)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_worker uuid; v_job uuid; v_title text; v_id uuid;
begin
  select c.worker_id,c.job_id,j.title into v_worker,v_job,v_title
  from public.contracts c join public.jobs j on j.id=c.job_id
  where c.id=p_contract_id and c.status='completed';
  if v_worker is null then raise exception 'Completed contract not found'; end if;
  if auth.uid()<>v_worker and not public.mavora_is_staff() then raise exception 'Not authorized'; end if;
  if exists(select 1 from public.proof_of_work where contract_id=p_contract_id and status='verified') then return jsonb_build_object('success',true,'existing',true); end if;
  insert into public.proof_of_work(user_id,contract_id,title,summary,status,verified_at)
  values(v_worker,p_contract_id,v_title,'Completed and approved MAVORA work.','verified',now()) returning id into v_id;
  return jsonb_build_object('success',true,'id',v_id);
end;
$$;
revoke all on function public.create_verified_proof_of_work(uuid) from public;
grant execute on function public.create_verified_proof_of_work(uuid) to authenticated;

-- ============================================================
-- EXPLICIT TABLE GRANTS
-- RLS remains the access-control layer. These grants make the API
-- endpoints usable after Supabase's newer explicit-grant behavior.
-- ============================================================

grant select,insert,update,delete on public.profiles to authenticated;
grant select,insert,update,delete on public.jobs to authenticated;
grant select,insert,update,delete on public.applications to authenticated;
grant select,insert,update,delete on public.contracts to authenticated;
grant select,insert,update,delete on public.work_files to authenticated;
grant select,insert,update,delete on public.messages to authenticated;
grant select,update on public.notifications to authenticated;
grant select,insert,update,delete on public.wallets to authenticated;
grant select,insert,update,delete on public.transactions to authenticated;
grant select,insert,update,delete on public.withdrawals to authenticated;
grant select,insert,update,delete on public.saved_jobs to authenticated;
grant select,insert,update,delete on public.saved_searches to authenticated;
grant select,insert,update,delete on public.revision_requests to authenticated;
grant select,insert,update,delete on public.disputes to authenticated;
grant select,insert,update on public.reports to authenticated;
grant select,insert,update on public.support_tickets to authenticated;
grant select,insert,update,delete on public.services to authenticated;
grant select,insert,update,delete on public.portfolio_projects to authenticated;
grant select,insert,update,delete on public.proof_of_work to authenticated;
grant select,insert,update,delete on public.skill_verifications to authenticated;
grant select,insert,update,delete on public.business_profiles to authenticated;
grant select,insert,update,delete on public.business_members to authenticated;
grant select on public.reviews to authenticated;
grant select,insert,update on public.staff_applications to authenticated;
grant select on public.staff_role_audit to authenticated;
grant select on public.work_passports to authenticated;
grant select,insert,update,delete on public.job_events to authenticated;
grant select,insert,update,delete on public.contract_milestones to authenticated;
grant select,insert,update,delete on public.work_submissions to authenticated;
grant select,insert,update,delete on public.work_revisions to authenticated;
grant select,insert,update,delete on public.recurring_jobs to authenticated;
grant select,insert,update,delete on public.contract_team_members to authenticated;
grant select on public.client_reliability to authenticated;
grant select on public.audit_logs to authenticated;

-- Market API tables.
grant select on public.market_profiles to anon,authenticated;
grant select,insert,update,delete on public.market_profiles to authenticated;
grant select,insert,update,delete on public.market_listings to authenticated;
grant select on public.market_listings to anon;
grant select,insert,update,delete on public.market_messages to authenticated;
grant select,insert,update,delete on public.market_orders to authenticated;
grant select on public.market_fee_settings to anon,authenticated;
grant select,update on public.market_fee_settings to authenticated;
grant select,insert,update,delete on public.market_disputes to authenticated;

-- ============================================================
-- FINAL HEALTH CHECK (read only)
-- ============================================================
select to_regclass('public.profiles') as profiles,
       to_regclass('public.jobs') as jobs,
       to_regclass('public.applications') as applications,
       to_regclass('public.contracts') as contracts,
       to_regclass('public.wallets') as wallets,
       to_regclass('public.identity_verifications') as identity_verifications,
       to_regclass('public.market_profiles') as market_profiles,
       to_regclass('public.market_listings') as market_listings,
       to_regclass('public.market_messages') as market_messages,
       to_regclass('public.market_orders') as market_orders,
       to_regclass('public.staff_applications') as staff_applications,
       to_regclass('public.reviews') as reviews,
       to_regclass('public.business_members') as business_members;

select proname
from pg_proc
where proname in (
  'apply_for_job','choose_worker','pay_job_from_wallet','request_revision','request_work_revision','approve_work',
  'mavora_create_market_listing','mavora_create_market_order','mavora_confirm_market_receipt',
  'mavora_open_market_dispute','mavora_review_identity_v2','mavora_start_identity_review',
  'mavora_moderation_action','moderate_queue_item','manage_staff_role','initialize_founder',
  'business_add_member','submit_rating','create_verified_proof_of_work','save_my_profile'
)
order by proname;

-- ============================================================
-- END MAVORA MASTER SQL
-- ============================================================


-- ============================================================
-- MAVORA FINAL COMPLETE ROUNDUP / SECURITY + PRODUCT LAYER
-- ============================================================
-- Additive migration. This section keeps prior MAVORA features and adds:
-- messaging workflow, private message attachments, presence, job alerts,
-- share events, milestones, work timeline events, customer care threads,
-- hardened role/payment/application/job writes, and public-safe sharing helpers.
-- No API keys, provider secrets, service_role keys or private credentials belong here.

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- A. PROFILE PRIVACY / PRESENCE / SAFE ROLE STORAGE
-- ------------------------------------------------------------
alter table public.profiles add column if not exists last_seen_at timestamptz;
alter table public.profiles add column if not exists phone text;

-- Users must use the existing save_my_profile()/server-side workflows rather than
-- changing their own role, verification, rating or financial identity in the browser.
revoke insert,update,delete on public.profiles from authenticated;
grant select on public.profiles to authenticated;

-- Keep only non-sensitive profile discovery fields broadly readable. Email is not
-- exposed through normal PostgREST profile reads; auth.users remains the email source.
revoke select on public.profiles from anon,authenticated;
grant select(id,full_name,username,professional_title,skills,about,state,lga,city,area,availability,service_radius_km,nearby_enabled,role,identity_status,rating,completed_jobs,created_at,updated_at,phone_verified,phone_verified_at,identity_verified,identity_verified_at,profile_visibility,business_mode,role_updated_at,avatar_url,gender,last_seen_at) on public.profiles to authenticated;

-- ------------------------------------------------------------
-- B. JOB DISCOVERY SAFETY + PUBLIC READS
-- ------------------------------------------------------------
alter table public.jobs add column if not exists visibility text default 'public';
alter table public.jobs add column if not exists status text default 'open';
alter table public.jobs add column if not exists deadline timestamptz;

alter table public.jobs enable row level security;
drop policy if exists mavora_jobs_public_anon on public.jobs;
create policy mavora_jobs_public_anon on public.jobs
for select to anon
using(status='open' and coalesce(visibility,'public')='public');

drop policy if exists mavora_jobs_public_auth on public.jobs;
create policy mavora_jobs_public_auth on public.jobs
for select to authenticated
using(
  (status='open' and coalesce(visibility,'public')='public')
  or client_id=auth.uid()
  or public.mavora_is_staff()
);

-- The browser may edit only ordinary job content/coordinates for its own jobs.
-- State transitions remain in change_job_status(), and hiring remains in choose_worker().
revoke update on public.jobs from authenticated;
grant update(title,description,category,budget,job_mode,experience_level,state,lga,city,area,delivery_details,deadline,visibility,latitude,longitude,updated_at) on public.jobs to authenticated;
grant insert on public.jobs to authenticated;

-- ------------------------------------------------------------
-- C. APPLICATION / CONTRACT / FINANCE DIRECT-WRITE HARDENING
-- ------------------------------------------------------------
revoke insert,update,delete on public.applications from authenticated;
grant select on public.applications to authenticated;

revoke insert,update,delete on public.contracts from authenticated;
grant select on public.contracts to authenticated;

revoke insert,update,delete on public.wallets from authenticated;
grant select on public.wallets to authenticated;
revoke insert,update,delete on public.transactions from authenticated;
grant select on public.transactions to authenticated;
revoke insert,update,delete on public.withdrawals from authenticated;
grant select on public.withdrawals to authenticated;

-- Notifications are server-created. The browser may only read/mark its own.
revoke insert,delete on public.notifications from authenticated;

-- ------------------------------------------------------------
-- D. MESSAGE SCHEMA / BLOCKS / SETTINGS / PRESENCE
-- ------------------------------------------------------------
alter table public.messages add column if not exists edited_at timestamptz;
alter table public.messages add column if not exists deleted_at timestamptz;
alter table public.messages add column if not exists reply_to_id uuid references public.messages(id) on delete set null;
alter table public.messages add column if not exists attachment_path text;
alter table public.messages add column if not exists attachment_name text;
alter table public.messages add column if not exists attachment_type text;
alter table public.messages add column if not exists attachment_size bigint;

create index if not exists mavora_messages_pair_created_idx on public.messages(least(sender_id,recipient_id),greatest(sender_id,recipient_id),created_at desc);
create index if not exists mavora_messages_reply_idx on public.messages(reply_to_id);

create table if not exists public.message_user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(blocker_id,blocked_id),
  check(blocker_id<>blocked_id)
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.message_user_blocks.
alter table public.message_user_blocks add column if not exists blocker_id uuid;
alter table public.message_user_blocks add column if not exists blocked_id uuid;
alter table public.message_user_blocks add column if not exists created_at timestamptz default now();

alter table public.message_user_blocks enable row level security;
drop policy if exists mavora_message_blocks_select_own on public.message_user_blocks;
create policy mavora_message_blocks_select_own on public.message_user_blocks for select to authenticated using(blocker_id=auth.uid());
drop policy if exists mavora_message_blocks_insert_own on public.message_user_blocks;
create policy mavora_message_blocks_insert_own on public.message_user_blocks for insert to authenticated with check(blocker_id=auth.uid() and blocked_id<>auth.uid());
drop policy if exists mavora_message_blocks_delete_own on public.message_user_blocks;
create policy mavora_message_blocks_delete_own on public.message_user_blocks for delete to authenticated using(blocker_id=auth.uid());

create table if not exists public.message_conversation_settings (
  user_id uuid not null references public.profiles(id) on delete cascade,
  other_user_id uuid not null references public.profiles(id) on delete cascade,
  muted boolean not null default false,
  archived boolean not null default false,
  pinned boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key(user_id,other_user_id),
  check(user_id<>other_user_id)
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.message_conversation_settings.
alter table public.message_conversation_settings add column if not exists user_id uuid;
alter table public.message_conversation_settings add column if not exists other_user_id uuid;
alter table public.message_conversation_settings add column if not exists muted boolean default false;
alter table public.message_conversation_settings add column if not exists archived boolean default false;
alter table public.message_conversation_settings add column if not exists pinned boolean default false;
alter table public.message_conversation_settings add column if not exists updated_at timestamptz default now();

alter table public.message_conversation_settings enable row level security;
drop policy if exists mavora_message_settings_all_own on public.message_conversation_settings;
create policy mavora_message_settings_all_own on public.message_conversation_settings
for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid() and other_user_id<>auth.uid());

-- Never permit direct client message inserts/updates/deletes; use the RPCs below.
revoke insert,update,delete on public.messages from authenticated;
grant select on public.messages to authenticated;

create or replace function public.mavora_send_message(
  p_recipient_id uuid,
  p_message text,
  p_job_id uuid default null,
  p_contract_id uuid default null,
  p_reply_to_id uuid default null,
  p_attachment_path text default null,
  p_attachment_name text default null,
  p_attachment_type text default null,
  p_attachment_size bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_id uuid;
  v_text text;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if p_recipient_id is null or p_recipient_id=auth.uid() then raise exception 'Invalid recipient'; end if;
  if not exists(select 1 from public.profiles where id=p_recipient_id) then raise exception 'Recipient not found'; end if;
  if exists(select 1 from public.message_user_blocks where blocker_id=p_recipient_id and blocked_id=auth.uid()) then raise exception 'This user has blocked you'; end if;
  if exists(select 1 from public.message_user_blocks where blocker_id=auth.uid() and blocked_id=p_recipient_id) then raise exception 'Unblock this user before sending'; end if;
  v_text=left(trim(coalesce(p_message,'')),5000);
  if length(v_text)=0 then raise exception 'Message is empty'; end if;
  if p_job_id is not null and not exists(
    select 1 from public.jobs j where j.id=p_job_id and (j.client_id=auth.uid() or exists(select 1 from public.applications a where a.job_id=j.id and a.worker_id=auth.uid()))
  ) then raise exception 'You are not connected to this job'; end if;
  if p_contract_id is not null and not exists(
    select 1 from public.contracts c where c.id=p_contract_id and auth.uid() in (c.client_id,c.worker_id)
  ) then raise exception 'You are not connected to this contract'; end if;
  if p_reply_to_id is not null and not exists(
    select 1 from public.messages m where m.id=p_reply_to_id and ((m.sender_id=auth.uid() and m.recipient_id=p_recipient_id) or (m.sender_id=p_recipient_id and m.recipient_id=auth.uid()))
  ) then raise exception 'Invalid reply target'; end if;
  if p_attachment_path is not null and split_part(p_attachment_path,'/',1)<>auth.uid()::text then raise exception 'Invalid attachment path'; end if;
  if p_attachment_size is not null and p_attachment_size>10*1024*1024 then raise exception 'Attachment is too large'; end if;
  insert into public.messages(sender_id,recipient_id,job_id,contract_id,message,is_read,reply_to_id,attachment_path,attachment_name,attachment_type,attachment_size)
  values(auth.uid(),p_recipient_id,p_job_id,p_contract_id,v_text,false,p_reply_to_id,p_attachment_path,p_attachment_name,p_attachment_type,p_attachment_size)
  returning id into v_id;
  return jsonb_build_object('success',true,'message_id',v_id);
end;
$$;
revoke all on function public.mavora_send_message(uuid,text,uuid,uuid,uuid,text,text,text,bigint) from public;
grant execute on function public.mavora_send_message(uuid,text,uuid,uuid,uuid,text,text,text,bigint) to authenticated;

create or replace function public.mavora_edit_message(p_message_id uuid,p_message text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_count integer;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if length(trim(coalesce(p_message,'')))=0 then raise exception 'Message cannot be empty'; end if;
  update public.messages set message=left(trim(p_message),5000),edited_at=now()
  where id=p_message_id and sender_id=auth.uid() and deleted_at is null and created_at>=now()-interval '1 hour';
  get diagnostics v_count = row_count;
  if v_count=0 then raise exception 'Message cannot be edited'; end if;
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.mavora_edit_message(uuid,text) from public;
grant execute on function public.mavora_edit_message(uuid,text) to authenticated;

create or replace function public.mavora_delete_message(p_message_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_count integer;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  update public.messages set deleted_at=now(),edited_at=null,attachment_path=null,attachment_name=null,attachment_type=null,attachment_size=null
  where id=p_message_id and sender_id=auth.uid() and deleted_at is null;
  get diagnostics v_count = row_count;
  if v_count=0 then raise exception 'Message not found or not owned by you'; end if;
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.mavora_delete_message(uuid) from public;
grant execute on function public.mavora_delete_message(uuid) to authenticated;

create or replace function public.mavora_mark_messages_read(p_sender_id uuid)
returns integer language plpgsql security definer set search_path=public as $$
declare v_count integer;
begin
  update public.messages set is_read=true
  where recipient_id=auth.uid() and sender_id=p_sender_id and is_read=false;
  get diagnostics v_count = row_count;
  return v_count;
end; $$;
revoke all on function public.mavora_mark_messages_read(uuid) from public;
grant execute on function public.mavora_mark_messages_read(uuid) to authenticated;

create or replace function public.mavora_unread_message_count()
returns bigint language sql security definer set search_path=public as $$
  select count(*) from public.messages where recipient_id=auth.uid() and is_read=false and deleted_at is null;
$$;
revoke all on function public.mavora_unread_message_count() from public;
grant execute on function public.mavora_unread_message_count() to authenticated;

create or replace function public.mavora_block_message_user(p_user_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  if p_user_id is null or p_user_id=auth.uid() then raise exception 'Invalid user'; end if;
  insert into public.message_user_blocks(blocker_id,blocked_id) values(auth.uid(),p_user_id) on conflict do nothing;
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.mavora_block_message_user(uuid) from public;
grant execute on function public.mavora_block_message_user(uuid) to authenticated;

create or replace function public.mavora_unblock_message_user(p_user_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  delete from public.message_user_blocks where blocker_id=auth.uid() and blocked_id=p_user_id;
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.mavora_unblock_message_user(uuid) from public;
grant execute on function public.mavora_unblock_message_user(uuid) to authenticated;

create or replace function public.mavora_report_message(p_message_id uuid,p_reason text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_sender uuid; v_recipient uuid;
begin
  select sender_id,recipient_id into v_sender,v_recipient from public.messages where id=p_message_id;
  if v_sender is null then raise exception 'Message not found'; end if;
  if auth.uid() not in (v_sender,v_recipient) then raise exception 'Not authorized'; end if;
  insert into public.reports(reporter_id,target_type,target_id,reason,status) values(auth.uid(),'message',p_message_id,left(trim(coalesce(p_reason,'Message reported')),1000),'open');
  return jsonb_build_object('success',true,'message','Message reported to MAVORA.');
end; $$;
revoke all on function public.mavora_report_message(uuid,text) from public;
grant execute on function public.mavora_report_message(uuid,text) to authenticated;

create or replace function public.mavora_report_user(p_user_id uuid,p_reason text default 'User reported')
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  if p_user_id is null or p_user_id=auth.uid() then raise exception 'Invalid user'; end if;
  insert into public.reports(reporter_id,target_type,target_id,reason,status) values(auth.uid(),'user',p_user_id,left(trim(p_reason),1000),'open');
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.mavora_report_user(uuid,text) from public;
grant execute on function public.mavora_report_user(uuid,text) to authenticated;

create or replace function public.mavora_touch_presence()
returns timestamptz language plpgsql security definer set search_path=public as $$
declare v_now timestamptz:=now();
begin
  if auth.uid() is null then return null; end if;
  update public.profiles set last_seen_at=v_now where id=auth.uid();
  return v_now;
end; $$;
revoke all on function public.mavora_touch_presence() from public;
grant execute on function public.mavora_touch_presence() to authenticated;

-- ------------------------------------------------------------
-- E. PRIVATE MESSAGE ATTACHMENT STORAGE
-- ------------------------------------------------------------
insert into storage.buckets(id,name,public) values('mavora-message','mavora-message',false)
on conflict(id) do update set public=false;

drop policy if exists mavora_message_storage_insert_own on storage.objects;
create policy mavora_message_storage_insert_own on storage.objects
for insert to authenticated
with check(bucket_id='mavora-message' and (storage.foldername(name))[1]=auth.uid()::text);

drop policy if exists mavora_message_storage_select_participant on storage.objects;
create policy mavora_message_storage_select_participant on storage.objects
for select to authenticated
using(bucket_id='mavora-message' and exists(
  select 1 from public.messages m
  where m.attachment_path=name and (m.sender_id=auth.uid() or m.recipient_id=auth.uid())
));

-- ------------------------------------------------------------
-- F. JOB ALERTS / SAVED SEARCH ALERTS
-- ------------------------------------------------------------
create table if not exists public.job_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  saved_search_id uuid not null references public.saved_searches(id) on delete cascade,
  is_enabled boolean not null default true,
  frequency text not null default 'instant' check(frequency in ('instant','daily','weekly')),
  last_sent_at timestamptz,
  created_at timestamptz not null default now(),
  unique(user_id,saved_search_id)
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.job_alerts.
alter table public.job_alerts add column if not exists id uuid default gen_random_uuid();
alter table public.job_alerts add column if not exists user_id uuid;
alter table public.job_alerts add column if not exists saved_search_id uuid;
alter table public.job_alerts add column if not exists is_enabled boolean default false;
alter table public.job_alerts add column if not exists frequency text;
alter table public.job_alerts add column if not exists last_sent_at timestamptz default now();
alter table public.job_alerts add column if not exists created_at timestamptz default now();

alter table public.job_alerts enable row level security;
drop policy if exists mavora_job_alerts_all_own on public.job_alerts;
create policy mavora_job_alerts_all_own on public.job_alerts for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create index if not exists mavora_job_alerts_user_idx on public.job_alerts(user_id,is_enabled);

create or replace function public.mavora_job_matches_saved_search(p_job public.jobs,p_filters jsonb,p_query text)
returns boolean language plpgsql immutable as $$
declare v_min numeric; v_max numeric; v_category text; v_state text; v_mode text; v_exp text;
begin
  if coalesce(trim(p_query),'')<>'' and position(lower(trim(p_query)) in lower(coalesce(p_job.title,'')||' '||coalesce(p_job.description,'')||' '||coalesce(p_job.category,'')))=0 then return false; end if;
  v_min=nullif(p_filters->>'min_budget','')::numeric; v_max=nullif(p_filters->>'max_budget','')::numeric;
  if v_min is null then v_min=nullif(p_filters->>'minBudget','')::numeric; end if;
  if v_min is null then v_min=nullif(p_filters->>'budget','')::numeric; end if;
  if v_max is null then v_max=nullif(p_filters->>'maxBudget','')::numeric; end if;
  v_category=nullif(trim(coalesce(p_filters->>'category','')),'');
  v_state=nullif(trim(coalesce(p_filters->>'state',p_filters->>'jobState','')),'');
  v_mode=nullif(trim(coalesce(p_filters->>'job_mode',p_filters->>'mode',p_filters->>'type','')),'');
  v_exp=nullif(trim(coalesce(p_filters->>'experience_level',p_filters->>'experience','')),'');
  if v_min is not null and p_job.budget<v_min then return false; end if;
  if v_max is not null and p_job.budget>v_max then return false; end if;
  if v_category is not null and v_category not in ('','All') and lower(coalesce(p_job.category,''))<>lower(v_category) then return false; end if;
  if v_state is not null and v_state not in ('','All','Other') and lower(coalesce(p_job.state,''))<>lower(v_state) then return false; end if;
  if v_mode is not null and v_mode not in ('','All') and lower(coalesce(p_job.job_mode,''))<>lower(v_mode) then return false; end if;
  if v_exp is not null and v_exp not in ('','Any level','All') and lower(coalesce(p_job.experience_level,''))<>lower(v_exp) then return false; end if;
  return true;
exception when others then return false;
end; $$;
revoke all on function public.mavora_job_matches_saved_search(public.jobs,jsonb,text) from public;

create or replace function public.mavora_job_alert_trigger()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status='open' and coalesce(new.visibility,'public')='public' then
    insert into public.notifications(user_id,title,message,type,target_page,target_id,data)
    select ja.user_id,
           'New job alert',
           left('A new job matches your saved search: '||coalesce(new.title,'MAVORA job'),250),
           'job_alert','jobs',new.id,jsonb_build_object('saved_search_id',ss.id)
    from public.saved_searches ss
    join public.job_alerts ja on ja.saved_search_id=ss.id and ja.user_id=ss.user_id
    where ja.is_enabled and public.mavora_job_matches_saved_search(new,coalesce(ss.filters,'{}'::jsonb),coalesce(ss.query,''))
      and ja.frequency='instant'
      and new.client_id<>ja.user_id;
    update public.job_alerts ja set last_sent_at=now()
    where ja.is_enabled and ja.frequency='instant'
      and exists(select 1 from public.saved_searches ss where ss.id=ja.saved_search_id and public.mavora_job_matches_saved_search(new,coalesce(ss.filters,'{}'::jsonb),coalesce(ss.query,'')));
  end if;
  return new;
end; $$;
revoke all on function public.mavora_job_alert_trigger() from public;

drop trigger if exists mavora_job_alert_trigger on public.jobs;
create trigger mavora_job_alert_trigger after insert on public.jobs for each row execute function public.mavora_job_alert_trigger();

-- ------------------------------------------------------------
-- G. SHARE EVENTS / SHAREABLE LINKS
-- ------------------------------------------------------------
create table if not exists public.share_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete set null,
  object_type text not null check(object_type in ('job','listing','profile','portfolio','service')),
  object_id uuid not null,
  created_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.share_events.
alter table public.share_events add column if not exists id uuid default gen_random_uuid();
alter table public.share_events add column if not exists user_id uuid;
alter table public.share_events add column if not exists object_type text;
alter table public.share_events add column if not exists object_id uuid;
alter table public.share_events add column if not exists created_at timestamptz default now();

alter table public.share_events enable row level security;
drop policy if exists mavora_share_events_own_read on public.share_events;
create policy mavora_share_events_own_read on public.share_events for select to authenticated using(user_id=auth.uid());
create index if not exists mavora_share_events_object_idx on public.share_events(object_type,object_id,created_at desc);

create or replace function public.mavora_record_share(p_object_type text,p_object_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  if p_object_type not in ('job','listing','profile','portfolio','service') then raise exception 'Invalid shared object'; end if;
  insert into public.share_events(user_id,object_type,object_id) values(auth.uid(),p_object_type,p_object_id);
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.mavora_record_share(text,uuid) from public;
grant execute on function public.mavora_record_share(text,uuid) to authenticated;

-- ------------------------------------------------------------
-- H. MILESTONES / DELIVERABLE SUBMISSIONS / WORK TIMELINE
-- ------------------------------------------------------------
create table if not exists public.contract_events (
  id uuid primary key default gen_random_uuid(),
  contract_id uuid not null references public.contracts(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  event_type text not null,
  message text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.contract_events.
alter table public.contract_events add column if not exists id uuid default gen_random_uuid();
alter table public.contract_events add column if not exists contract_id uuid;
alter table public.contract_events add column if not exists actor_id uuid;
alter table public.contract_events add column if not exists event_type text;
alter table public.contract_events add column if not exists message text;
alter table public.contract_events add column if not exists metadata jsonb default '{}'::jsonb;
alter table public.contract_events add column if not exists created_at timestamptz default now();

alter table public.contract_events enable row level security;
drop policy if exists mavora_contract_events_read_related on public.contract_events;
create policy mavora_contract_events_read_related on public.contract_events for select to authenticated using(
  exists(select 1 from public.contracts c where c.id=contract_id and (c.client_id=auth.uid() or c.worker_id=auth.uid()))
  or public.mavora_is_staff()
);
create index if not exists mavora_contract_events_idx on public.contract_events(contract_id,created_at asc);

revoke insert,update,delete on public.contract_milestones from authenticated;
grant select on public.contract_milestones to authenticated;

create or replace function public.mavora_create_milestone(p_contract_id uuid,p_title text,p_description text default null,p_amount numeric default 0,p_due_at timestamptz default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_job uuid;
begin
  select job_id into v_job from public.contracts where id=p_contract_id and client_id=auth.uid() and status in ('pending','active');
  if v_job is null then raise exception 'Contract not found or not allowed'; end if;
  if length(trim(coalesce(p_title,'')))<2 then raise exception 'Milestone title is required'; end if;
  if coalesce(p_amount,0)<0 then raise exception 'Invalid milestone amount'; end if;
  insert into public.contract_milestones(contract_id,title,description,amount,due_at,status,sort_order)
  values(p_contract_id,left(trim(p_title),160),nullif(left(trim(coalesce(p_description,'')),4000),''),coalesce(p_amount,0),p_due_at,'pending',coalesce((select max(sort_order)+1 from public.contract_milestones where contract_id=p_contract_id),0))
  returning id into v_id;
  insert into public.contract_events(contract_id,actor_id,event_type,message,metadata) values(p_contract_id,auth.uid(),'milestone_created','Milestone created',jsonb_build_object('milestone_id',v_id));
  return jsonb_build_object('success',true,'milestone_id',v_id);
end; $$;
revoke all on function public.mavora_create_milestone(uuid,text,text,numeric,timestamptz) from public;
grant execute on function public.mavora_create_milestone(uuid,text,text,numeric,timestamptz) to authenticated;

create or replace function public.mavora_submit_milestone(p_milestone_id uuid,p_message text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_contract uuid;
begin
  select cm.contract_id into v_contract from public.contract_milestones cm join public.contracts c on c.id=cm.contract_id where cm.id=p_milestone_id and c.worker_id=auth.uid();
  if v_contract is null then raise exception 'Milestone not found or not allowed'; end if;
  update public.contract_milestones set status='submitted',updated_at=now() where id=p_milestone_id and status in ('pending','funded','revision');
  if not found then raise exception 'Milestone cannot be submitted in its current state'; end if;
  insert into public.work_submissions(contract_id,worker_id,message,status,submitted_at)
  values(v_contract,auth.uid(),left(trim(coalesce(p_message,'')),6000),'submitted',now());
  insert into public.contract_events(contract_id,actor_id,event_type,message,metadata) values(v_contract,auth.uid(),'milestone_submitted',left(trim(p_message),1000),jsonb_build_object('milestone_id',p_milestone_id));
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.mavora_submit_milestone(uuid,text) from public;
grant execute on function public.mavora_submit_milestone(uuid,text) to authenticated;

create or replace function public.mavora_review_milestone(p_milestone_id uuid,p_action text,p_note text default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_contract uuid; v_worker uuid; v_client uuid; v_new_status text;
begin
  select c.id,c.worker_id,c.client_id into v_contract,v_worker,v_client from public.contract_milestones cm join public.contracts c on c.id=cm.contract_id where cm.id=p_milestone_id;
  if v_contract is null then raise exception 'Milestone not found'; end if;
  if auth.uid()<>v_client then raise exception 'Client access required'; end if;
  if p_action not in ('approve','revision') then raise exception 'Invalid milestone action'; end if;
  v_new_status=case when p_action='approve' then 'approved' else 'revision' end;
  update public.contract_milestones set status=v_new_status,updated_at=now() where id=p_milestone_id and status in ('submitted','revision');
  if not found then raise exception 'Milestone cannot be reviewed in its current state'; end if;
  insert into public.contract_events(contract_id,actor_id,event_type,message,metadata) values(v_contract,auth.uid(),case when p_action='approve' then 'milestone_approved' else 'milestone_revision_requested' end,nullif(trim(p_note),''),jsonb_build_object('milestone_id',p_milestone_id));
  if p_action='approve' then perform public.mavora_notify(v_worker,'Milestone approved','Your MAVORA milestone was approved.','workroom',v_contract,jsonb_build_object('milestone_id',p_milestone_id));
  else perform public.mavora_notify(v_worker,'Milestone revision requested','The client requested a revision on a MAVORA milestone.','workroom',v_contract,jsonb_build_object('milestone_id',p_milestone_id)); end if;
  return jsonb_build_object('success',true,'status',v_new_status);
end; $$;
revoke all on function public.mavora_review_milestone(uuid,text,text) from public;
grant execute on function public.mavora_review_milestone(uuid,text,text) to authenticated;

-- ------------------------------------------------------------
-- I. CUSTOMER CARE / SUPPORT CONVERSATIONS
-- ------------------------------------------------------------
alter table public.support_tickets add column if not exists priority text default 'normal';
alter table public.support_tickets add column if not exists assigned_to uuid references public.profiles(id) on delete set null;
alter table public.support_tickets add column if not exists closed_at timestamptz;

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id) on delete cascade,
  sender_role text not null check(sender_role in ('user','staff')),
  message text not null check(length(trim(message)) between 1 and 4000),
  created_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.support_messages.
alter table public.support_messages add column if not exists id uuid default gen_random_uuid();
alter table public.support_messages add column if not exists ticket_id uuid;
alter table public.support_messages add column if not exists sender_user_id uuid;
alter table public.support_messages add column if not exists sender_role text;
alter table public.support_messages add column if not exists message text;
alter table public.support_messages add column if not exists created_at timestamptz default now();

alter table public.support_messages enable row level security;
drop policy if exists mavora_support_messages_read on public.support_messages;
create policy mavora_support_messages_read on public.support_messages for select to authenticated using(
  exists(select 1 from public.support_tickets st where st.id=ticket_id and st.user_id=auth.uid()) or public.mavora_is_staff()
);
revoke insert,update,delete on public.support_messages from authenticated;
grant select on public.support_messages to authenticated;
create index if not exists mavora_support_messages_ticket_idx on public.support_messages(ticket_id,created_at asc);

create or replace function public.mavora_support_reply(p_ticket_id uuid,p_message text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_owner uuid; v_staff boolean; v_status text;
begin
  select user_id,status into v_owner,v_status from public.support_tickets where id=p_ticket_id for update;
  if v_owner is null then raise exception 'Support ticket not found'; end if;
  v_staff=public.mavora_is_staff();
  if not v_staff and v_owner<>auth.uid() then raise exception 'Not authorized'; end if;
  if length(trim(coalesce(p_message,'')))=0 then raise exception 'Reply cannot be empty'; end if;
  insert into public.support_messages(ticket_id,sender_user_id,sender_role,message) values(p_ticket_id,auth.uid(),case when v_staff then 'staff' else 'user' end,left(trim(p_message),4000));
  update public.support_tickets set status=case when v_staff then 'waiting_user' else 'in_progress' end,updated_at=now(),closed_at=null where id=p_ticket_id;
  if v_staff then perform public.mavora_notify(v_owner,'MAVORA Support replied','There is a new reply on your support ticket.','support',p_ticket_id,'{}'::jsonb); end if;
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.mavora_support_reply(uuid,text) from public;
grant execute on function public.mavora_support_reply(uuid,text) to authenticated;

create or replace function public.mavora_support_set_status(p_ticket_id uuid,p_status text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_owner uuid;
begin
  select user_id into v_owner from public.support_tickets where id=p_ticket_id;
  if v_owner is null then raise exception 'Support ticket not found'; end if;
  if not public.mavora_is_staff() and not(v_owner=auth.uid() and p_status='closed') then raise exception 'Not authorized'; end if;
  if p_status not in ('open','in_progress','waiting_user','pending','resolved','closed') then raise exception 'Invalid support status'; end if;
  update public.support_tickets set status=p_status,closed_at=case when p_status in ('resolved','closed') then now() else null end,updated_at=now() where id=p_ticket_id;
  return jsonb_build_object('success',true,'status',p_status);
end; $$;
revoke all on function public.mavora_support_set_status(uuid,text) from public;
grant execute on function public.mavora_support_set_status(uuid,text) to authenticated;

-- ------------------------------------------------------------
-- J. APPLICATION EDIT / WITHDRAW COMPATIBILITY
-- ------------------------------------------------------------
create or replace function public.edit_application(p_application_id uuid,p_proposed_price numeric,p_proposal text,p_delivery_time text default null,p_questions text default null)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  update public.applications a set proposed_price=p_proposed_price,proposal=p_proposal,delivery_time=p_delivery_time,questions=p_questions,updated_at=now()
  from public.jobs j
  where a.id=p_application_id and a.job_id=j.id and a.worker_id=auth.uid() and a.status='pending' and j.status='open';
  if not found then raise exception 'Application cannot be edited'; end if;
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.edit_application(uuid,numeric,text,text,text) from public;
grant execute on function public.edit_application(uuid,numeric,text,text,text) to authenticated;

create or replace function public.withdraw_application(p_application_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
begin
  update public.applications set status='withdrawn',updated_at=now() where id=p_application_id and worker_id=auth.uid() and status='pending';
  if not found then raise exception 'Application cannot be withdrawn'; end if;
  return jsonb_build_object('success',true);
end; $$;
revoke all on function public.withdraw_application(uuid) from public;
grant execute on function public.withdraw_application(uuid) to authenticated;

-- ------------------------------------------------------------
-- K. MARKET MESSAGE WRITE HARDENING (KEEP MARKET CHAT SEPARATE)
-- ------------------------------------------------------------
revoke insert,update,delete on public.market_messages from authenticated;
grant select on public.market_messages to authenticated;

-- ------------------------------------------------------------
-- L. FOUNDER BOOTSTRAP: EXPLICIT SERVER-ENFORCED ALLOWLIST
-- ------------------------------------------------------------
create table if not exists public.mavora_platform_security (
  id boolean primary key default true check(id=true),
  bootstrap_email text,
  founder_initialized_at timestamptz,
  bootstrap_locked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Compatibility: add any MAVORA columns missing from an older installation of public.mavora_platform_security.
alter table public.mavora_platform_security add column if not exists id boolean default false;
alter table public.mavora_platform_security add column if not exists bootstrap_email text;
alter table public.mavora_platform_security add column if not exists founder_initialized_at timestamptz default now();
alter table public.mavora_platform_security add column if not exists bootstrap_locked boolean default false;
alter table public.mavora_platform_security add column if not exists created_at timestamptz default now();
alter table public.mavora_platform_security add column if not exists updated_at timestamptz default now();

alter table public.mavora_platform_security enable row level security;
drop policy if exists mavora_platform_security_no_client_read on public.mavora_platform_security;
create policy mavora_platform_security_no_client_read on public.mavora_platform_security for select to authenticated using(false);
revoke all on public.mavora_platform_security from anon,authenticated;

insert into public.mavora_platform_security(id) values(true) on conflict(id) do nothing;

-- FIRST-TIME PRIVATE SETUP (run once in the Supabase SQL Editor, replacing the value):
-- update public.mavora_platform_security set bootstrap_email='YOUR-FOUNDER-ACCOUNT-EMAIL' where id=true;
-- Do not put the founder email in the public frontend or repository.

create or replace function public.mavora_set_bootstrap_email(p_email text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_existing text; v_locked boolean; v_founder boolean;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select bootstrap_email,bootstrap_locked into v_existing,v_locked from public.mavora_platform_security where id=true for update;
  if exists(select 1 from public.profiles where id=auth.uid() and role='founder') then
    if v_locked then return jsonb_build_object('success',true,'locked',true); end if;
    update public.mavora_platform_security set bootstrap_email=lower(trim(p_email)),updated_at=now() where id=true;
    return jsonb_build_object('success',true,'locked',false);
  end if;
  if exists(select 1 from public.profiles where role='founder') then raise exception 'Founder already exists'; end if;
  raise exception 'Founder configuration can only be changed by the existing Founder';
end; $$;
revoke all on function public.mavora_set_bootstrap_email(text) from public;

create or replace function public.initialize_founder(p_email text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_bootstrap text; v_done timestamptz; v_locked boolean; v_uid uuid:=auth.uid();
begin
  if v_uid is null then raise exception 'Not authenticated'; end if;
  select bootstrap_email,founder_initialized_at,bootstrap_locked into v_bootstrap,v_done,v_locked from public.mavora_platform_security where id=true for update;
  if v_done is not null or v_locked then raise exception 'Founder initialization is already locked'; end if;
  if exists(select 1 from public.profiles where role='founder') then raise exception 'Founder already exists'; end if;
  if v_bootstrap is null or lower(trim(p_email))<>lower(trim(v_bootstrap)) or lower(coalesce(auth.email(),''))<>lower(trim(v_bootstrap)) then raise exception 'Founder bootstrap email is not authorized'; end if;
  update public.profiles set role='founder',role_updated_at=now(),updated_at=now() where id=v_uid;
  if not found then raise exception 'Profile not found'; end if;
  update public.mavora_platform_security set founder_initialized_at=now(),bootstrap_locked=true,updated_at=now() where id=true;
  insert into public.staff_role_audit(actor_id,target_user_id,old_role,new_role,action) values(v_uid,v_uid,'user','founder','founder_initialized');
  insert into public.audit_logs(actor_id,action,entity_type,entity_id,metadata) values(v_uid,'founder_initialized','profile',v_uid,jsonb_build_object('one_time',true));
  return jsonb_build_object('success',true,'locked',true);
end; $$;
revoke all on function public.initialize_founder(text) from public;
grant execute on function public.initialize_founder(text) to authenticated;

-- ------------------------------------------------------------
-- M. PAYMENT-SAFETY DEFAULTS / DIRECT WRITE DENIAL
-- ------------------------------------------------------------
revoke insert,update,delete on public.transactions from authenticated;
revoke insert,update,delete on public.wallets from authenticated;
revoke insert,update,delete on public.withdrawals from authenticated;

-- Market orders contain payment state and seller credits; browser never writes them directly.
revoke insert,update,delete on public.market_orders from authenticated;
grant select on public.market_orders to authenticated;

-- Payment state should be changed only by trusted provider/webhook settlement functions.
-- Existing Edge Functions such as payment-verification / mavora-paystack-webhook remain the
-- trusted provider boundary. This SQL intentionally never contains Paystack credentials.

-- ------------------------------------------------------------
-- N. KYC / STORAGE HARDENING
-- ------------------------------------------------------------
insert into storage.buckets(id,name,public) values('mavora-identity','mavora-identity',false)
on conflict(id) do update set public=false;

-- Replace broad/duplicate identity object policies with one owner-upload + owner/staff-read model.
drop policy if exists mavora_identity_insert_own on storage.objects;
create policy mavora_identity_insert_own on storage.objects for insert to authenticated
with check(bucket_id='mavora-identity' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists mavora_identity_select_owner_staff on storage.objects;
create policy mavora_identity_select_owner_staff on storage.objects for select to authenticated
using(bucket_id='mavora-identity' and ((storage.foldername(name))[1]=auth.uid()::text or public.mavora_is_staff()));
drop policy if exists mavora_identity_owner_select on storage.objects;
drop policy if exists mavora_identity_staff_select on storage.objects;

revoke insert,update,delete on public.identity_verifications from authenticated;
grant select on public.identity_verifications to authenticated;

-- Direct client writes to workflow/audit records are denied; secure RPCs and triggers own these changes.
revoke insert,update,delete on public.revision_requests from authenticated;
grant select on public.revision_requests to authenticated;
revoke insert,update,delete on public.work_files from authenticated;
grant select on public.work_files to authenticated;
revoke insert,update,delete on public.job_events from authenticated;
grant select on public.job_events to authenticated;
revoke insert,update,delete on public.proof_of_work from authenticated;
grant select on public.proof_of_work to authenticated;
revoke insert,update,delete on public.skill_verifications from authenticated;
grant select on public.skill_verifications to authenticated;
revoke insert,update,delete on public.work_submissions from authenticated;
grant select on public.work_submissions to authenticated;
revoke insert,update,delete on public.work_revisions from authenticated;
grant select on public.work_revisions to authenticated;
revoke update,delete on public.support_tickets from authenticated;
grant insert,select on public.support_tickets to authenticated;
revoke update,delete on public.reports from authenticated;
grant insert,select on public.reports to authenticated;
revoke update,delete on public.disputes from authenticated;
grant insert,select on public.disputes to authenticated;
revoke insert,update,delete on public.market_fee_settings from authenticated;
grant select on public.market_fee_settings to authenticated;

-- Portfolio owners can create/edit portfolio content but cannot self-mark it as verified.
revoke insert,update on public.portfolio_projects from authenticated;
grant insert(user_id,title,description,public_url,cover_file_path,created_at,updated_at) on public.portfolio_projects to authenticated;
grant update(title,description,public_url,cover_file_path,updated_at) on public.portfolio_projects to authenticated;

-- ------------------------------------------------------------
-- O. STAFF VISIBILITY FOR PRIVATE QUEUES
-- ------------------------------------------------------------
drop policy if exists mavora_applications_staff_read on public.applications;
create policy mavora_applications_staff_read on public.applications for select to authenticated using(public.mavora_is_staff());
drop policy if exists mavora_contracts_staff_read on public.contracts;
create policy mavora_contracts_staff_read on public.contracts for select to authenticated using(public.mavora_is_staff());
drop policy if exists mavora_support_staff_read on public.support_tickets;
create policy mavora_support_staff_read on public.support_tickets for select to authenticated using(public.mavora_is_staff());
drop policy if exists mavora_disputes_staff_read on public.disputes;
create policy mavora_disputes_staff_read on public.disputes for select to authenticated using(public.mavora_is_staff());
drop policy if exists mavora_reports_staff_read on public.reports;
create policy mavora_reports_staff_read on public.reports for select to authenticated using(public.mavora_is_staff());

-- ------------------------------------------------------------
-- P. SAFE ACTIVITY / PERFORMANCE INDEXES
-- ------------------------------------------------------------
create index if not exists mavora_profiles_last_seen_idx on public.profiles(last_seen_at desc);
create index if not exists mavora_support_status_idx on public.support_tickets(status,created_at desc);
create index if not exists mavora_application_status_idx on public.applications(status,created_at desc);
create index if not exists mavora_contract_status_idx on public.contracts(status,created_at desc);

-- ------------------------------------------------------------
-- Q. COMPLETE HEALTH / SECURITY CHECKS (READ-ONLY)
-- ------------------------------------------------------------
-- 1) Tables and RLS status
-- select schemaname,tablename,rowsecurity
-- from pg_tables where schemaname='public' order by tablename;
--
-- 2) Effective function privileges
-- select routine_schema,routine_name,privilege_type
-- from information_schema.routine_privileges
-- where routine_schema='public' order by routine_name,privilege_type;
--
-- 3) Founder bootstrap state (does not reveal email)
-- select founder_initialized_at,bootstrap_locked from public.mavora_platform_security where id=true;
--
-- 4) Sensitive storage buckets
-- select id,name,public from storage.buckets where name in ('mavora-identity','mavora-message','mavora-work');
--
-- 5) Security advisor should still be run in Supabase Dashboard -> Database -> Advisors.

-- ============================================================
-- END MAVORA FINAL COMPLETE ROUNDUP
-- ============================================================
