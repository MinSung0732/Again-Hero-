-- Qualify the purge variable against storage.objects.owner_id.
create or replace function account_private.purge_expired_withdrawals() returns integer
language plpgsql security definer set search_path = '' as $$
declare withdrawn_user_id uuid; deleted_count integer := 0;
begin
  if not pg_try_advisory_xact_lock(20261011, 30) then return 0; end if;
  for withdrawn_user_id in select w.user_id from account_private.withdrawals w
    where w.delete_after <= now() order by w.delete_after limit 500 for update skip locked loop
    -- The current project has no Storage uploads. Never delete its metadata
    -- directly if uploads are introduced: remove binaries via Storage API first.
    if exists(select 1 from storage.objects o where o.owner_id = withdrawn_user_id::text) then continue; end if;
    delete from auth.users where id = withdrawn_user_id;
    if found then deleted_count := deleted_count + 1; end if;
  end loop;
  return deleted_count;
end $$;
revoke all on function account_private.purge_expired_withdrawals() from public, anon, authenticated;

