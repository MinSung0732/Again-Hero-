-- Canonical snapshots, fenced device sessions and idempotent save receipts.
-- Additive schema: existing saves/guest ownership/tutorial ledgers are retained.
begin;
create table private.cloud_devices (
 user_id uuid primary key references auth.users(id) on delete cascade,
 session_nonce uuid not null,
 auth_session_id uuid not null,
 updated_at timestamptz not null default now()
);
create table private.cloud_claims (
 user_id uuid not null references auth.users(id) on delete cascade,
 session_nonce uuid not null,
 primary key(user_id,session_nonce)
);
create table private.cloud_receipts (
 user_id uuid not null references auth.users(id) on delete cascade,
 operation_id uuid not null,
 fingerprint text not null,
 response jsonb not null,
 created_at timestamptz not null default now(),
 primary key(user_id,operation_id)
);
alter table private.cloud_devices enable row level security;
alter table private.cloud_claims enable row level security;
alter table private.cloud_receipts enable row level security;
revoke all on private.cloud_devices, private.cloud_claims, private.cloud_receipts from public,anon,authenticated;

-- Used by legacy invoker snapshot writes too: a claimed account cannot be
-- changed from an old client/device without the current nonce + Auth session.
create function private.cloud_device_allowed() returns boolean
language sql stable security definer set search_path='' as $$
 select not exists(select 1 from private.cloud_devices where user_id=auth.uid()) or exists(
 select 1 from private.cloud_devices d join auth.sessions s on s.id=d.auth_session_id and s.user_id=d.user_id
 where d.user_id=auth.uid()
 and d.session_nonce::text=coalesce(nullif(current_setting('request.headers',true),''),'{}')::jsonb->>'x-game-session'
 and d.auth_session_id::text=auth.jwt()->>'session_id');
$$;
revoke all on function private.cloud_device_allowed() from public,anon;
grant execute on function private.cloud_device_allowed() to authenticated;
create policy cloud_device_fence on public.account_save_snapshots as restrictive for all to authenticated
 using ((select private.cloud_device_allowed())) with check ((select private.cloud_device_allowed()));
create policy cloud_device_fence on public.player_progress as restrictive for all to authenticated
 using ((select private.cloud_device_allowed())) with check ((select private.cloud_device_allowed()));

create function private.cloud_sync_operation(action text, session_nonce uuid, operation_id uuid,
 expected_revision bigint, new_payload jsonb, tutorial_action text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 owner_id uuid:=auth.uid(); auth_session uuid; device private.cloud_devices;
 saved public.account_save_snapshots; receipt private.cloud_receipts;
 result jsonb; fingerprint text;
begin
 if owner_id is null then raise exception 'authentication required' using errcode='42501'; end if;
 if session_nonce is null or action is null or action not in ('claim','read','check','save','tutorial') then
  return jsonb_build_object('error','invalid_request'); end if;
 if not account_private.is_active() then return jsonb_build_object('inactive',true); end if;
 auth_session:=nullif(auth.jwt()->>'session_id','')::uuid;
 if auth_session is null or not exists(select 1 from auth.sessions where id=auth_session and user_id=owner_id) then
  return jsonb_build_object('reauthenticate',true); end if;
 -- Shared account lock, then snapshot/tutorial locks: takeover and writes
 -- cannot pass one another between checking the lease and committing data.
 perform account_private.register_game_account();
 select * into device from private.cloud_devices where user_id=owner_id;
 if action='claim' then
  if exists(select 1 from private.cloud_claims c where c.user_id=owner_id and c.session_nonce=cloud_sync_operation.session_nonce) then
   if device.session_nonce is distinct from session_nonce or device.auth_session_id is distinct from auth_session then
    return jsonb_build_object('session_replaced',true); end if;
  else
   insert into private.cloud_claims values(owner_id,session_nonce);
   insert into private.cloud_devices values(owner_id,session_nonce,auth_session,now())
    on conflict(user_id) do update set session_nonce=excluded.session_nonce,auth_session_id=excluded.auth_session_id,updated_at=now();
  end if;
  return jsonb_build_object('ok',true);
 end if;
 if device.session_nonce is distinct from session_nonce or device.auth_session_id is distinct from auth_session then
  return jsonb_build_object('session_replaced',true); end if;
 if action='check' then return jsonb_build_object('ok',true); end if;
 if action='read' then
  result:=public.read_game_save();
  select * into receipt from private.cloud_receipts r where r.user_id=owner_id and r.operation_id=cloud_sync_operation.operation_id;
  return result || jsonb_build_object('acknowledged_revision',receipt.response->'revision');
 end if;
 if action='tutorial' then return private.tutorial_operation(tutorial_action,expected_revision); end if;
 if operation_id is null or expected_revision is null or expected_revision<0 or new_payload is null or jsonb_typeof(new_payload)<>'object'
 or octet_length(new_payload::text)>1000000 or exists(select 1 from jsonb_object_keys(new_payload) k where k not in
 ('stage_progress.cfg','monster_collection.cfg','team_loadout.cfg','demon_skill_loadout.cfg','shop_summon_history.cfg'))
 or exists(select 1 from jsonb_each(new_payload) f where jsonb_typeof(f.value)<>'object') then
  return jsonb_build_object('error','invalid_save'); end if;
 fingerprint:=md5(expected_revision::text || ':' || new_payload::text);
 select * into receipt from private.cloud_receipts r where r.user_id=owner_id and r.operation_id=cloud_sync_operation.operation_id;
 if found then
  if receipt.fingerprint<>fingerprint then return jsonb_build_object('error','operation_reused'); end if;
  return receipt.response;
 end if;
 select * into saved from public.account_save_snapshots where user_id=owner_id for update;
 if coalesce(saved.revision,0)<>expected_revision then return jsonb_build_object('conflict',true); end if;
 if saved.user_id is null then
  insert into public.account_save_snapshots(user_id,payload) values(owner_id,new_payload) returning * into saved;
 else
  update public.account_save_snapshots set payload=new_payload,revision=revision+1,updated_at=now()
  where user_id=owner_id returning * into saved;
 end if;
 result:=jsonb_build_object('ok',true,'revision',saved.revision);
 insert into private.cloud_receipts values(owner_id,operation_id,fingerprint,result,now());
 -- CAS still protects an exceptionally old retry after receipt expiry.
 delete from private.cloud_receipts where user_id=owner_id and created_at<now()-interval '30 days';
 return result;
end;
$$;
revoke all on function private.cloud_sync_operation(text,uuid,uuid,bigint,jsonb,text) from public,anon;
grant execute on function private.cloud_sync_operation(text,uuid,uuid,bigint,jsonb,text) to authenticated;
create function public.cloud_sync(action text,session_nonce uuid,operation_id uuid default null,
 expected_revision bigint default 0,new_payload jsonb default null,tutorial_action text default null) returns jsonb
language sql security invoker set search_path='' as $$
 select private.cloud_sync_operation(action,session_nonce,operation_id,expected_revision,new_payload,tutorial_action);
$$;
revoke all on function public.cloud_sync(text,uuid,uuid,bigint,jsonb,text) from public,anon;
grant execute on function public.cloud_sync(text,uuid,uuid,bigint,jsonb,text) to authenticated;

-- Legacy public tutorial RPC also needs the fence: its private implementation
-- is SECURITY DEFINER and deliberately bypasses snapshot RLS.
-- Apply the minimal guard without replacing its existing reward ledger logic.
do $$
declare definition text;
begin
 select pg_get_functiondef('private.tutorial_operation(text,bigint)'::regprocedure) into definition;
 definition:=replace(definition, E'begin\n', E'begin\n  if not private.cloud_device_allowed() then return jsonb_build_object(''session_replaced'',true); end if;\n');
 execute definition;
end $$;
commit;
