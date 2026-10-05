-- Additive deployment: existing saved accounts keep their progress and skip onboarding.
create schema if not exists private;
create table public.player_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nickname text check (nickname is null or nickname ~ '^[가-힣A-Za-z0-9]{1,6}$'),
  gender text not null default 'male' check (gender in ('male','female')),
  prologue_required boolean not null default true,
  prologue_completed boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index player_profiles_nickname_unique on public.player_profiles (lower(nickname)) where nickname is not null;
alter table public.player_profiles enable row level security;
revoke all on public.player_profiles from anon, authenticated;
grant select on public.player_profiles to authenticated;
create policy own_profile_read on public.player_profiles for select to authenticated using (user_id = (select auth.uid()));
insert into public.player_profiles(user_id,prologue_required,prologue_completed)
select user_id,false,true from public.account_save_snapshots
union select user_id,false,true from public.player_progress
on conflict (user_id) do nothing;

-- Cross-account uniqueness is exposed only as a collision result, never a user list.
create function private.player_profile_operation(operation text, chosen_name text default null, chosen_gender text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare owner_id uuid := auth.uid(); saved public.player_profiles;
begin
  if owner_id is null then raise exception 'authentication required'; end if;
  if operation not in ('read','register','complete') then raise exception 'invalid operation'; end if;
  insert into public.player_profiles(user_id) values(owner_id) on conflict (user_id) do nothing;
  select * into saved from public.player_profiles where user_id=owner_id for update;
  if operation='register' then
    if chosen_name is null or chosen_name !~ '^[가-힣A-Za-z0-9]{1,6}$' or chosen_gender is null or chosen_gender not in ('male','female') then
      return jsonb_build_object('ok',false,'error','invalid');
    end if;
    if saved.nickname is not null and (saved.nickname<>chosen_name or saved.gender<>chosen_gender) then
      return jsonb_build_object('ok',false,'error','locked');
    end if;
    if saved.nickname is null then
      begin
        update public.player_profiles set nickname=chosen_name,gender=chosen_gender,prologue_required=true,prologue_completed=false
        where user_id=owner_id returning * into saved;
      exception when unique_violation then
        return jsonb_build_object('ok',false,'error','duplicate');
      end;
    end if;
  elsif operation='complete' then
    if saved.nickname is null then return jsonb_build_object('ok',false,'error','missing_profile'); end if;
    update public.player_profiles set prologue_completed=true where user_id=owner_id returning * into saved;
  end if;
  return jsonb_build_object('ok',true,'profile',jsonb_build_object('nickname',coalesce(saved.nickname,''),'gender',saved.gender,'required',saved.prologue_required,'completed',saved.prologue_completed));
end $$;
revoke all on function private.player_profile_operation(text,text,text) from public,anon;
grant usage on schema private to authenticated;
grant execute on function private.player_profile_operation(text,text,text) to authenticated;
create function public.read_player_profile() returns jsonb language sql security invoker set search_path='' as $$ select private.player_profile_operation('read'); $$;
create function public.register_player_profile(chosen_name text,chosen_gender text) returns jsonb language sql security invoker set search_path='' as $$ select private.player_profile_operation('register',chosen_name,chosen_gender); $$;
create function public.complete_player_prologue() returns jsonb language sql security invoker set search_path='' as $$ select private.player_profile_operation('complete'); $$;
revoke all on function public.read_player_profile(),public.register_player_profile(text,text),public.complete_player_prologue() from public,anon;
grant execute on function public.read_player_profile(),public.register_player_profile(text,text),public.complete_player_prologue() to authenticated;
