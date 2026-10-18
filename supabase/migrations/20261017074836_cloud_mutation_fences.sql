begin;
-- Serialize legacy REST/invoker writes before row locks, using the same Auth
-- account lock as claim/save. No table privileges are expanded.
create function private.cloud_mutation_fence() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is not null then
  perform 1 from auth.users where id=auth.uid() for update;
  if not private.cloud_device_allowed() then
   raise exception 'game session replaced' using errcode='42501';
  end if;
 end if;
 return null;
end;
$$;
revoke all on function private.cloud_mutation_fence() from public,anon,authenticated;
create trigger cloud_snapshot_mutation_fence before insert or update or delete on public.account_save_snapshots
 for each statement execute function private.cloud_mutation_fence();
create trigger cloud_progress_mutation_fence before insert or update or delete on public.player_progress
 for each statement execute function private.cloud_mutation_fence();
-- Existing SECURITY DEFINER profile/withdrawal RPCs bypass RLS. Keep their
-- business rules and add the same lock + device check at their entry point.
do $$
declare signature text; definition text;
begin
 foreach signature in array array['private.player_profile_operation(text,text,text)','account_private.request_withdrawal()'] loop
  select pg_get_functiondef(signature::regprocedure) into definition;
  definition:=regexp_replace(definition, E'begin\n', E'begin\n  if auth.uid() is not null then\n    perform 1 from auth.users where id=auth.uid() for update;\n    if not private.cloud_device_allowed() then return jsonb_build_object(''session_replaced'',true); end if;\n  end if;\n','i');
  execute definition;
 end loop;
end $$;
commit;
