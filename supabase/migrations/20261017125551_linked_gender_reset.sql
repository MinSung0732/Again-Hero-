-- Independent linked-account gender allowance. Clients cannot grant/reset it.
create function private.profile_gender_policy() returns jsonb
language sql immutable set search_path='' as $$
 select '{"linked_changes":1,"values":["male","female"]}'::jsonb;
$$;
revoke all on function private.profile_gender_policy() from public,anon;
grant execute on function private.profile_gender_policy() to authenticated;

alter table public.player_profiles
 add column gender_changes_remaining integer not null default 0 check(gender_changes_remaining>=0),
 add column last_gender_operation uuid,
 add column last_gender_value text;
update public.player_profiles p set gender_changes_remaining=(private.profile_gender_policy()->>'linked_changes')::integer
 where exists(select 1 from account_private.registrations r where r.user_id=p.user_id and r.guest_id is not null);

-- Guest import inserts its registration first. Existing replay never inserts a profile.
create function private.grant_linked_gender_reset() returns trigger
language plpgsql set search_path='' as $$
begin
 new.gender_changes_remaining:=case when exists(select 1 from account_private.registrations r where r.user_id=new.user_id and r.guest_id is not null)
  then (private.profile_gender_policy()->>'linked_changes')::integer else 0 end;
 return new;
end $$;
revoke all on function private.grant_linked_gender_reset() from public,anon,authenticated;
create trigger profile_linked_gender_reset before insert on public.player_profiles
 for each row execute function private.grant_linked_gender_reset();

create or replace function private.nickname_operation(operation text,chosen_name text default null,chosen_gender text default null,operation_id uuid default null) returns jsonb
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
  'required',saved.prologue_required,'completed',saved.prologue_completed,'nickname_changes_remaining',saved.nickname_changes_remaining,'gender_changes_remaining',saved.gender_changes_remaining));
end $$;

-- Reuse the existing authenticated read/row lock/device fence before mutation.
create function private.change_player_gender(chosen_gender text,operation_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb; saved public.player_profiles; owner_id uuid:=auth.uid();
begin
 result:=private.nickname_operation('read');
 if result->>'ok' is distinct from 'true' then return result; end if;
 if chosen_gender is null or not (private.profile_gender_policy()->'values' ? chosen_gender) or operation_id is null then
  return jsonb_build_object('ok',false,'error','invalid'); end if;
 select * into saved from public.player_profiles where user_id=owner_id for update;
 if saved.last_gender_operation=operation_id then
  if saved.last_gender_value is distinct from chosen_gender then return jsonb_build_object('ok',false,'error','operation_reused'); end if;
 else
  if saved.nickname is null or saved.gender_changes_remaining<=0 then return jsonb_build_object('ok',false,'error','locked'); end if;
  if saved.gender=chosen_gender then return jsonb_build_object('ok',false,'error','unchanged'); end if;
  update public.player_profiles set gender=chosen_gender,gender_changes_remaining=gender_changes_remaining-1,
   last_gender_operation=operation_id,last_gender_value=chosen_gender where user_id=owner_id;
 end if;
 return private.nickname_operation('read');
end $$;
revoke all on function private.change_player_gender(text,uuid) from public,anon;
grant execute on function private.change_player_gender(text,uuid) to authenticated;
create function public.change_player_gender(chosen_gender text,operation_id uuid) returns jsonb
language sql security invoker set search_path='' as $$ select private.change_player_gender(chosen_gender,operation_id); $$;
revoke all on function public.change_player_gender(text,uuid) from public,anon;
grant execute on function public.change_player_gender(text,uuid) to authenticated;
