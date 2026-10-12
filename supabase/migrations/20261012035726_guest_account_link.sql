-- Guest linkage is one authenticated transaction. Existing accounts never merge.
create table account_private.registrations (
 user_id uuid primary key references auth.users(id) on delete cascade,
 guest_id uuid unique,
 registered_at timestamptz not null default now()
);
alter table account_private.registrations enable row level security;
revoke all on account_private.registrations from public, anon, authenticated;
-- Even a zero-wallet/stage-one account predating this feature is registered.
insert into account_private.registrations(user_id) select id from auth.users;

create function account_private.register_game_account() returns void
language plpgsql security definer set search_path='' as $$
declare owner_id uuid:=auth.uid();
begin
 if owner_id is null or not account_private.is_active() then raise exception 'active authentication required' using errcode='42501'; end if;
 perform 1 from auth.users where id=owner_id for update;
 insert into account_private.registrations(user_id) values(owner_id) on conflict(user_id) do nothing;
end $$;
revoke all on function account_private.register_game_account() from public,anon;
grant execute on function account_private.register_game_account() to authenticated;

create or replace function public.read_game_save() returns jsonb
language plpgsql security invoker set search_path='' as $$
declare saved public.account_save_snapshots; legacy public.player_progress;
begin
 perform account_private.register_game_account();
 select * into saved from public.account_save_snapshots where user_id=auth.uid();
 if found then return jsonb_build_object('found',true,'revision',saved.revision,'payload',saved.payload); end if;
 select * into legacy from public.player_progress where user_id=auth.uid();
 if found then return jsonb_build_object('found',true,'revision',0,'legacy',true,'payload',
  jsonb_build_object('stage_progress.cfg',jsonb_build_object('progress',jsonb_build_object('current_stage_id',legacy.current_stage_id,'highest_unlocked_stage',legacy.highest_unlocked_stage),
   'meta',jsonb_build_object('research_points',legacy.research_points),'research',coalesce(legacy.research_levels,'{}'::jsonb)))); end if;
 return jsonb_build_object('found',false,'revision',0);
end $$;

create function account_private.link_guest_save(guest_id uuid,guest_payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 owner_id uuid:=auth.uid(); linked account_private.registrations;
 snapshot public.account_save_snapshots; profile jsonb; tutorial jsonb;
 tutorial_status text; claimed boolean; guest_name text; gender text;
 file_entry record; section_entry record; sanitized jsonb;
begin
 if owner_id is null or not account_private.is_active() or not exists(select 1 from auth.sessions s
  where s.user_id=owner_id and s.id::text=auth.jwt()->>'session_id') then
  return jsonb_build_object('ok',false,'error','inactive'); end if;
 -- The normal-login registration path takes the same lock.
 perform 1 from auth.users where id=owner_id for update;
 select * into linked from account_private.registrations r where r.user_id=owner_id;
 if found then
  if linked.guest_id=link_guest_save.guest_id then
   select * into snapshot from public.account_save_snapshots where user_id=owner_id;
   if found then return jsonb_build_object('ok',true,'revision',snapshot.revision,'payload',snapshot.payload,'replayed',true); end if;
  end if;
  return jsonb_build_object('ok',false,'error','already_registered');
 end if;
 if exists(select 1 from account_private.registrations r where r.guest_id=link_guest_save.guest_id) then
  return jsonb_build_object('ok',false,'error','guest_already_linked'); end if;
 if exists(select 1 from public.account_save_snapshots where user_id=owner_id)
  or exists(select 1 from public.player_profiles where user_id=owner_id)
  or exists(select 1 from public.account_tutorials where user_id=owner_id) then
  return jsonb_build_object('ok',false,'error','already_registered'); end if;
 if guest_id is null or guest_payload is null or jsonb_typeof(guest_payload)<>'object' or octet_length(guest_payload::text)>1000000
  or guest_payload #>> '{stage_progress.cfg,guest_identity,id}' is distinct from guest_id::text then
  return jsonb_build_object('ok',false,'error','invalid_save'); end if;
 for file_entry in select * from jsonb_each(guest_payload) loop
  if file_entry.key not in ('stage_progress.cfg','monster_collection.cfg','team_loadout.cfg','demon_skill_loadout.cfg','shop_summon_history.cfg')
   or jsonb_typeof(file_entry.value)<>'object' then return jsonb_build_object('ok',false,'error','invalid_save'); end if;
  for section_entry in select * from jsonb_each(file_entry.value) loop
   if jsonb_typeof(section_entry.value)<>'object' then return jsonb_build_object('ok',false,'error','invalid_save'); end if;
  end loop;
 end loop;
 profile:=coalesce(guest_payload #> '{stage_progress.cfg,player_profile,value}','{}'::jsonb);
 tutorial:=coalesce(guest_payload #> '{stage_progress.cfg,guest_tutorial}','{}'::jsonb);
 guest_name:=coalesce(profile->>'nickname',''); gender:=coalesce(profile->>'gender','male');
 tutorial_status:=coalesce(tutorial->>'status','pending'); claimed:=coalesce(tutorial->'claimed','false'::jsonb)='true'::jsonb;
 if jsonb_typeof(profile)<>'object' or jsonb_typeof(tutorial)<>'object' or gender not in ('male','female')
  or (guest_name<>'' and guest_name!~'^[가-힣A-Za-z0-9]{1,6}$')
  or tutorial_status not in ('pending','active','skipped','completed')
  or jsonb_typeof(coalesce(tutorial->'claimed','false'::jsonb))<>'boolean'
  or claimed is distinct from (tutorial_status in ('skipped','completed'))
  or (claimed and (guest_name='' or profile->'completed' is distinct from 'true'::jsonb)) then
  return jsonb_build_object('ok',false,'error','invalid_save'); end if;
 if guest_name<>'' and exists(select 1 from public.player_profiles p where p.nickname=guest_name) then guest_name:=''; end if;
 -- Unique guest_id also protects simultaneous imports into different accounts.
 begin
  insert into account_private.registrations(user_id,guest_id) values(owner_id,link_guest_save.guest_id);
  if guest_name<>'' then
   begin
    insert into public.player_profiles(user_id,nickname,gender,prologue_required,prologue_completed)
     values(owner_id,guest_name,gender,true,coalesce(profile->'completed','false'::jsonb)='true'::jsonb);
   exception when unique_violation then guest_name:=''; end;
  end if;
  sanitized:=guest_payload #- '{stage_progress.cfg,guest_identity}' #- '{stage_progress.cfg,guest_tutorial}' #- '{stage_progress.cfg,player_profile}';
  insert into public.account_save_snapshots(user_id,revision,payload) values(owner_id,1,sanitized) returning * into snapshot;
  insert into public.account_tutorials(user_id,status,reward_claimed,reward_gold)
   values(owner_id,tutorial_status,claimed,case when claimed then 1000 else 0 end);
 exception when unique_violation then
  -- The exception subtransaction rolls back every partial registration/save.
  return jsonb_build_object('ok',false,'error',case when exists(select 1 from public.player_profiles p where p.nickname=guest_name) then 'nickname_taken' else 'guest_already_linked' end);
 end;
 return jsonb_build_object('ok',true,'revision',snapshot.revision,'payload',snapshot.payload);
end $$;
revoke all on function account_private.link_guest_save(uuid,jsonb) from public,anon;
grant execute on function account_private.link_guest_save(uuid,jsonb) to authenticated;
create function public.link_guest_save(guest_id uuid,guest_payload jsonb) returns jsonb
language sql security invoker set search_path='' as $$ select account_private.link_guest_save(guest_id,guest_payload); $$;
revoke all on function public.link_guest_save(uuid,jsonb) from public,anon;
grant execute on function public.link_guest_save(uuid,jsonb) to authenticated;
