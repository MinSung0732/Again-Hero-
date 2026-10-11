-- Server-authoritative retention. No game/user rows are deleted on withdrawal.
create schema if not exists account_private;
revoke all on schema account_private from public, anon, authenticated;
grant usage on schema account_private to authenticated;

create table account_private.withdrawals (
  user_id uuid primary key references auth.users(id) on delete cascade,
  requested_at timestamptz not null default now(),
  delete_after timestamptz not null default (now() + interval '720 hours'),
  constraint withdrawal_retention check (delete_after = requested_at + interval '720 hours')
);
create index withdrawals_delete_after_idx on account_private.withdrawals(delete_after);
alter table account_private.withdrawals enable row level security;
revoke all on account_private.withdrawals from public, anon, authenticated;

create function account_private.is_active() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists(select 1 from auth.users u where u.id = (select auth.uid())
    and u.deleted_at is null and (u.banned_until is null or u.banned_until <= now()))
    and not exists(select 1 from account_private.withdrawals w where w.user_id = (select auth.uid()));
$$;
revoke all on function account_private.is_active() from public, anon;
grant execute on function account_private.is_active() to authenticated;

-- Restrictive policies compose with existing ownership policies, including
-- direct PostgREST access and SECURITY INVOKER game RPCs with an old JWT.
do $$
declare t text;
begin
  foreach t in array array['profiles','player_progress','monster_collection','team_loadout',
      'account_save_snapshots','player_profiles','account_tutorials'] loop
    execute format('create policy active_account_required on public.%I as restrictive for all to authenticated using ((select account_private.is_active())) with check ((select account_private.is_active()))', t);
  end loop;
end $$;

create function account_private.lifecycle_status() returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare owner_id uuid := auth.uid(); deadline timestamptz;
begin
  if owner_id is null then raise exception 'authentication required' using errcode = '42501'; end if;
  select delete_after into deadline from account_private.withdrawals where user_id = owner_id;
  return jsonb_build_object('active', account_private.is_active(),
    'inactive', not account_private.is_active(), 'delete_after', deadline);
end $$;
revoke all on function account_private.lifecycle_status() from public, anon;
grant execute on function account_private.lifecycle_status() to authenticated;
create function public.account_lifecycle_status() returns jsonb
language sql security invoker set search_path = '' as $$ select account_private.lifecycle_status(); $$;
revoke all on function public.account_lifecycle_status() from public, anon;
grant execute on function public.account_lifecycle_status() to authenticated;

create function account_private.request_withdrawal() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare owner_id uuid := auth.uid(); deadline timestamptz; requested timestamptz := now();
begin
  if owner_id is null then raise exception 'authentication required' using errcode = '42501'; end if;
  -- Serialize repeat/device requests on the auth PK, without accepting any caller ID.
  perform 1 from auth.users where id = owner_id for update;
  if not found then raise exception 'account not found' using errcode = '42501'; end if;
  select delete_after into deadline from account_private.withdrawals where user_id = owner_id;
  if deadline is not null then
    return jsonb_build_object('ok', true, 'inactive', true, 'delete_after', deadline);
  end if;
  -- A signed JWT alone is insufficient for this sensitive action.
  if not account_private.is_active() or not exists(select 1 from auth.sessions s
    where s.user_id = owner_id and s.id::text = auth.jwt()->>'session_id') then
    raise exception 'live session required' using errcode = '42501';
  end if;
  deadline := requested + interval '720 hours';
  insert into account_private.withdrawals(user_id, requested_at, delete_after)
    values(owner_id, requested, deadline);
  -- Auth ban + session revocation and inactivity are one transaction. Auth keeps
  -- the user/identities for the retention window; game rows remain untouched.
  update auth.users set banned_until = greatest(coalesce(banned_until, requested), requested + interval '100 years'),
    updated_at = requested where id = owner_id;
  -- Indexed session FK cascades refresh tokens; do not scan refresh_tokens by
  -- its legacy varchar user_id (the available index starts with instance_id).
  delete from auth.sessions where user_id = owner_id;
  return jsonb_build_object('ok', true, 'inactive', true, 'delete_after', deadline);
end $$;
revoke all on function account_private.request_withdrawal() from public, anon;
grant execute on function account_private.request_withdrawal() to authenticated;
create function public.request_account_withdrawal() returns jsonb
language sql security invoker set search_path = '' as $$ select account_private.request_withdrawal(); $$;
revoke all on function public.request_account_withdrawal() from public, anon;
grant execute on function public.request_account_withdrawal() to authenticated;

create function account_private.purge_expired_withdrawals() returns integer
language plpgsql security definer set search_path = '' as $$
declare owner_id uuid; deleted_count integer := 0;
begin
  if not pg_try_advisory_xact_lock(20261011, 30) then return 0; end if;
  for owner_id in select w.user_id from account_private.withdrawals w
    where w.delete_after <= now() order by w.delete_after limit 500 for update skip locked loop
    -- The current project has no Storage uploads. Never delete its metadata
    -- directly if uploads are introduced: remove binaries via Storage API first.
    if exists(select 1 from storage.objects o where o.owner_id = owner_id::text) then continue; end if;
    delete from auth.users where id = owner_id;
    if found then deleted_count := deleted_count + 1; end if;
  end loop;
  return deleted_count;
end $$;
revoke all on function account_private.purge_expired_withdrawals() from public, anon, authenticated;

create extension if not exists pg_cron;
select cron.schedule('purge-withdrawn-accounts', '*/10 * * * *',
  'select account_private.purge_expired_withdrawals();');
comment on table account_private.withdrawals is 'Inactive accounts retained exactly 720 hours before scheduled hard deletion; no client access.';
