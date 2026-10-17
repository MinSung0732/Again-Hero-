-- Server-side name policy; client catalog parity is tested before deployment.
create function private.nickname_policy() returns jsonb
language sql immutable set search_path='' as $$
 select '{"minimum":2,"maximum":6,"characters":"가-힣A-Za-z0-9","linked_renames":1,"random_attempts":64,"prefixes":["새벽","붉은","검은","달빛","별빛","고요","은빛","심연","황혼","푸른"]}'::jsonb;
$$;
revoke all on function private.nickname_policy() from public,anon;
grant execute on function private.nickname_policy() to authenticated;

create function private.nickname_valid(value text) returns boolean
language sql immutable set search_path='' as $$
 select value is not null and value ~ ('^['||(private.nickname_policy()->>'characters')||']{'||(private.nickname_policy()->>'minimum')||','||(private.nickname_policy()->>'maximum')||'}$')
 and value !~ E'[\\n\\r]';
$$;
revoke all on function private.nickname_valid(text) from public,anon;
grant execute on function private.nickname_valid(text) to authenticated;

alter table public.player_profiles
 add column nickname_changes_remaining integer not null default 0 check(nickname_changes_remaining>=0),
 add column last_nickname_operation uuid,
 add column last_nickname_value text;

-- Preserve existing names/progress. Old one-character names can be corrected once.
update public.player_profiles p set nickname_changes_remaining=(private.nickname_policy()->>'linked_renames')::integer
where char_length(p.nickname)<(private.nickname_policy()->>'minimum')::integer
or exists(select 1 from account_private.registrations r where r.user_id=p.user_id and r.guest_id is not null);

create function private.enforce_new_nickname() returns trigger
language plpgsql set search_path='' as $$
begin
 if new.nickname is not null and (tg_op='INSERT' or new.nickname is distinct from old.nickname)
 and not private.nickname_valid(new.nickname) then
  raise exception 'invalid nickname' using errcode='23514';
 end if;
 return new;
end $$;
revoke all on function private.enforce_new_nickname() from public,anon,authenticated;
create trigger profile_nickname_policy before insert or update of nickname on public.player_profiles
 for each row execute function private.enforce_new_nickname();

create function private.random_player_nickname() returns text
language plpgsql volatile set search_path='' as $$
declare policy jsonb:=private.nickname_policy(); prefixes jsonb; candidate text;
begin
 prefixes:=policy->'prefixes';
 candidate:=(prefixes->>floor(random()*jsonb_array_length(prefixes))::integer);
 return candidate||substr(replace(gen_random_uuid()::text,'-',''),1,(policy->>'maximum')::integer-char_length(candidate));
end $$;
revoke all on function private.random_player_nickname() from public,anon,authenticated;

create function private.nickname_operation(operation text,chosen_name text default null,chosen_gender text default null,operation_id uuid default null) returns jsonb
language plpgsql security definer set search_path='' as $$
declare owner_id uuid:=auth.uid(); saved public.player_profiles; available boolean;
begin
 if owner_id is null or not account_private.is_active() or not exists(select 1 from auth.sessions where user_id=owner_id and id::text=auth.jwt()->>'session_id') then
  return jsonb_build_object('ok',false,'error','inactive'); end if;
 perform 1 from auth.users where id=owner_id for update;
 if not private.cloud_device_allowed() then return jsonb_build_object('session_replaced',true); end if;
 if operation not in ('read','check','register','rename','complete') then return jsonb_build_object('ok',false,'error','invalid'); end if;
 if operation in ('check','register','rename') and not private.nickname_valid(chosen_name) then
  return jsonb_build_object('ok',false,'error','invalid'); end if;
 if operation='check' then
  available:=not exists(select 1 from public.player_profiles where lower(nickname)=lower(chosen_name) and user_id<>owner_id);
  return jsonb_build_object('ok',true,'available',available,'rules',private.nickname_policy());
 end if;
 insert into public.player_profiles(user_id) values(owner_id) on conflict(user_id) do nothing;
 select * into saved from public.player_profiles where user_id=owner_id for update;
 if operation='register' then
  if chosen_gender is null or chosen_gender not in ('male','female') then return jsonb_build_object('ok',false,'error','invalid'); end if;
  if saved.nickname is not null and (saved.nickname<>chosen_name or saved.gender<>chosen_gender) then
   return jsonb_build_object('ok',false,'error','locked'); end if;
  if saved.nickname is null then
   begin
    update public.player_profiles set nickname=chosen_name,gender=chosen_gender,prologue_required=true,prologue_completed=false where user_id=owner_id returning * into saved;
   exception when unique_violation then return jsonb_build_object('ok',false,'error','duplicate'); end;
  end if;
 elsif operation='rename' then
  if operation_id is null then return jsonb_build_object('ok',false,'error','invalid'); end if;
  if saved.last_nickname_operation=operation_id then
   if saved.last_nickname_value is distinct from chosen_name then return jsonb_build_object('ok',false,'error','operation_reused'); end if;
  else
   if saved.nickname is null or saved.nickname_changes_remaining<=0 then return jsonb_build_object('ok',false,'error','locked'); end if;
   if lower(saved.nickname)=lower(chosen_name) then return jsonb_build_object('ok',false,'error','unchanged'); end if;
   begin
    update public.player_profiles set nickname=chosen_name,nickname_changes_remaining=nickname_changes_remaining-1,
     last_nickname_operation=operation_id,last_nickname_value=chosen_name where user_id=owner_id returning * into saved;
   exception when unique_violation then return jsonb_build_object('ok',false,'error','duplicate'); end;
  end if;
 elsif operation='complete' then
  if saved.nickname is null then return jsonb_build_object('ok',false,'error','missing_profile'); end if;
  update public.player_profiles set prologue_completed=true where user_id=owner_id returning * into saved;
 end if;
 return jsonb_build_object('ok',true,'profile',jsonb_build_object('nickname',coalesce(saved.nickname,''),'gender',saved.gender,
  'required',saved.prologue_required,'completed',saved.prologue_completed,'nickname_changes_remaining',saved.nickname_changes_remaining));
end $$;
revoke all on function private.nickname_operation(text,text,text,uuid) from public,anon;
grant execute on function private.nickname_operation(text,text,text,uuid) to authenticated;

create or replace function private.player_profile_operation(operation text,chosen_name text default null,chosen_gender text default null) returns jsonb
language sql security invoker set search_path='' as $$ select private.nickname_operation(operation,chosen_name,chosen_gender); $$;

create function public.check_player_nickname(chosen_name text) returns jsonb
language sql security invoker set search_path='' as $$ select private.nickname_operation('check',chosen_name); $$;
create function public.rename_player_nickname(chosen_name text,operation_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.nickname_operation('rename',chosen_name,null,operation_id); $$;
revoke all on function public.check_player_nickname(text), public.rename_player_nickname(text,uuid) from public,anon;
grant execute on function public.check_player_nickname(text), public.rename_player_nickname(text,uuid) to authenticated;

-- Preserve atomic guest import/replay/rewards, allocate a unique name on collision.
create or replace function account_private.link_guest_save(guest_id uuid,guest_payload jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
 owner_id uuid:=auth.uid(); linked account_private.registrations;
 snapshot public.account_save_snapshots; profile jsonb; tutorial jsonb;
 tutorial_status text; claimed boolean; guest_name text; gender text;
 file_entry record; section_entry record; sanitized jsonb; attempts integer;
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
 if not private.nickname_valid(guest_name) then guest_name:=private.random_player_nickname(); end if;
 tutorial_status:=coalesce(tutorial->>'status','pending'); claimed:=coalesce(tutorial->'claimed','false'::jsonb)='true'::jsonb;
 if jsonb_typeof(profile)<>'object' or jsonb_typeof(tutorial)<>'object' or gender not in ('male','female')
  or (guest_name<>'' and guest_name!~'^[가-힣A-Za-z0-9]{1,6}$')
  or tutorial_status not in ('pending','active','skipped','completed')
  or jsonb_typeof(coalesce(tutorial->'claimed','false'::jsonb))<>'boolean'
  or claimed is distinct from (tutorial_status in ('skipped','completed'))
  or (claimed and (guest_name='' or profile->'completed' is distinct from 'true'::jsonb)) then
  return jsonb_build_object('ok',false,'error','invalid_save'); end if;
 if exists(select 1 from public.player_profiles p where lower(p.nickname)=lower(guest_name)) then guest_name:=''; end if;
 -- Unique guest_id also protects simultaneous imports into different accounts.
 begin
  insert into account_private.registrations(user_id,guest_id) values(owner_id,link_guest_save.guest_id);
  if guest_name<>'' then
   begin
    insert into public.player_profiles(user_id,nickname,gender,prologue_required,prologue_completed,nickname_changes_remaining)
     values(owner_id,guest_name,gender,false,true,(private.nickname_policy()->>'linked_renames')::integer);
   exception when unique_violation then guest_name:=''; end;
  end if;
  if guest_name='' then
   for attempts in 1..(private.nickname_policy()->>'random_attempts')::integer loop
    begin
     guest_name:=private.random_player_nickname();
     insert into public.player_profiles(user_id,nickname,gender,prologue_required,prologue_completed,nickname_changes_remaining)
      values(owner_id,guest_name,gender,false,true,(private.nickname_policy()->>'linked_renames')::integer);
     exit;
    exception when unique_violation then guest_name:=''; end;
   end loop;
   if guest_name='' then raise exception 'nickname allocation exhausted'; end if;
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
