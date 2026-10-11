-- Run as postgres in a single transaction. Only random synthetic accounts are
-- touched; ALL fixtures and deletions are rolled back, including on assertion.
begin;
create temporary table withdrawal_fixture(id uuid, session_id uuid, deadline timestamptz);
grant all on withdrawal_fixture to authenticated, anon;
insert into withdrawal_fixture values(gen_random_uuid(), gen_random_uuid(), null);
insert into auth.users(id, email, raw_app_meta_data, raw_user_meta_data)
select id, id::text || '@withdrawal-test.invalid', '{}'::jsonb, '{}'::jsonb from withdrawal_fixture;
insert into auth.sessions(id, user_id) select session_id,id from withdrawal_fixture;
insert into auth.refresh_tokens(token,user_id,session_id,revoked)
select gen_random_uuid()::text,id::text,session_id,false from withdrawal_fixture;
insert into public.account_save_snapshots(user_id,revision,payload)
select id,1,'{}'::jsonb from withdrawal_fixture;
select set_config('request.jwt.claims', jsonb_build_object('sub',id,'role','authenticated','session_id',session_id)::text,true) from withdrawal_fixture;
set local role authenticated;
do $$ begin
  assert (public.account_lifecycle_status()->>'active')::boolean, 'active account rejected';
  assert (select count(*) = 1 from public.profiles), 'own profile read failed';
  assert (public.read_game_save()->>'found')::boolean, 'active snapshot unavailable';
end $$;
-- A JWT without a live session must not withdraw an account.
select set_config('request.jwt.claims', jsonb_build_object('sub',id,'role','authenticated','session_id',gen_random_uuid())::text,true) from withdrawal_fixture;
do $$ begin
  begin perform public.request_account_withdrawal(); raise exception 'missing live session accepted';
  exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claims', jsonb_build_object('sub',id,'role','authenticated','session_id',session_id)::text,true) from withdrawal_fixture;
update withdrawal_fixture set deadline = (public.request_account_withdrawal()->>'delete_after')::timestamptz;
do $$ begin
  assert (public.account_lifecycle_status()->>'inactive')::boolean, 'withdrawal not inactive';
  assert (select deadline = now() + interval '720 hours' from withdrawal_fixture), 'retention not 30 days';
  assert (public.request_account_withdrawal()->>'delete_after')::timestamptz = (select deadline from withdrawal_fixture), 'retry changed deadline';
  assert (select count(*) = 0 from public.profiles), 'old JWT can read profile';
  assert (select count(*) = 0 from public.account_save_snapshots), 'old JWT can read snapshot';
  assert not (public.read_game_save()->>'found')::boolean, 'old JWT can read through RPC';
  begin
    insert into public.account_save_snapshots(user_id,revision,payload) select id,2,'{}'::jsonb from withdrawal_fixture;
    raise exception 'old JWT can insert';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
do $$ begin
  assert (select count(*) = 1 from auth.users where id in (select id from withdrawal_fixture)), 'user deleted immediately';
  assert (select count(*) = 1 from public.account_save_snapshots where user_id in (select id from withdrawal_fixture)), 'data deleted immediately';
  assert (select count(*) = 0 from auth.sessions where user_id in (select id from withdrawal_fixture)), 'sessions retained';
  assert (select count(*) = 0 from auth.refresh_tokens where user_id in (select id::text from withdrawal_fixture)), 'refresh retained';
  assert (select banned_until > now() + interval '720 hours' from auth.users where id in (select id from withdrawal_fixture)), 'sign-in not banned';
  assert account_private.purge_expired_withdrawals() = 0, 'early purge';
end $$;
set local role authenticated;
do $$ declare changed integer; begin
  update public.profiles set nickname = 'forbidden' where user_id in (select id from withdrawal_fixture);
  get diagnostics changed = row_count;
  assert changed = 0, 'old JWT can update';
  delete from public.profiles where user_id in (select id from withdrawal_fixture);
  get diagnostics changed = row_count;
  assert changed = 0, 'old JWT can delete';
  begin perform account_private.purge_expired_withdrawals(); raise exception 'client can purge';
  exception when insufficient_privilege then null; end;
  begin perform count(*) from account_private.withdrawals; raise exception 'client can read retention table';
  exception when insufficient_privilege then null; end;
end $$;
set local role anon;
do $$ begin
  begin perform public.request_account_withdrawal(); raise exception 'anon can withdraw';
  exception when insufficient_privilege then null; end;
  begin perform public.account_lifecycle_status(); raise exception 'anon can read status';
  exception when insufficient_privilege then null; end;
end $$;
reset role;
-- Age only the synthetic fixture. Never age or delete real accounts.
update account_private.withdrawals set requested_at=now()-interval '721 hours',delete_after=now()-interval '1 hour'
where user_id in (select id from withdrawal_fixture);
do $$ begin
  assert account_private.purge_expired_withdrawals() = 1, 'expired synthetic account not purged';
  assert (select count(*) = 0 from auth.users where id in (select id from withdrawal_fixture)), 'auth user retained';
  assert (select count(*) = 0 from public.profiles where user_id in (select id from withdrawal_fixture)), 'profile cascade failed';
  assert (select count(*) = 0 from public.player_progress where user_id in (select id from withdrawal_fixture)), 'progress cascade failed';
  assert (select count(*) = 0 from public.account_save_snapshots where user_id in (select id from withdrawal_fixture)), 'snapshot cascade failed';
  assert (select count(*) = 0 from account_private.withdrawals where user_id in (select id from withdrawal_fixture)), 'retention cascade failed';
end $$;
set local role authenticated;
do $$ begin
  assert not (public.account_lifecycle_status()->>'active')::boolean, 'purged old JWT became active';
end $$;
reset role;
select 'ACCOUNT_WITHDRAWAL: PASS (30 assertions, synthetic fixtures rolled back)' as result;
rollback;
