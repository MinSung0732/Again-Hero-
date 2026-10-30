begin;

create table public.public_uids (
 user_id uuid primary key references auth.users(id) on delete cascade,
 public_uid integer not null unique check (public_uid between 10000000 and 99999999)
);
alter table public.public_uids enable row level security;
create policy public_uid_owner_read on public.public_uids for select to authenticated using (user_id = auth.uid());
grant select on public.public_uids to authenticated;

create function private.issue_public_uid(p_user_id uuid) returns integer
language plpgsql security definer set search_path = '' as $$
declare result integer;
begin
 loop
  select public_uid into result from public.public_uids where user_id = p_user_id;
  if found then return result; end if;
  begin
   insert into public.public_uids(user_id, public_uid)
   values (p_user_id, 10000000 + floor(random() * 90000000)::integer)
   on conflict (user_id) do nothing returning public_uid into result;
   if found then return result; end if;
  exception when unique_violation then
   null;
  end;
 end loop;
end $$;
revoke all on function private.issue_public_uid(uuid) from public, anon, authenticated;

create function public.ensure_public_uid() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare owner_id uuid := auth.uid();
begin
 if owner_id is null then raise exception 'authentication required' using errcode = '42501'; end if;
 return jsonb_build_object('ok', true, 'public_uid', private.issue_public_uid(owner_id));
end $$;
revoke all on function public.ensure_public_uid() from public, anon;
grant execute on function public.ensure_public_uid() to authenticated;

create function private.issue_public_uid_on_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
 perform private.issue_public_uid(new.user_id);
 return new;
end $$;
create trigger profile_public_uid after insert on public.player_profiles
for each row execute function private.issue_public_uid_on_profile();
select private.issue_public_uid(id) from auth.users;

create or replace function public.get_my_ranked_profile() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare owner_id uuid := auth.uid();
begin
 if owner_id is null then raise exception 'authentication required' using errcode = '42501'; end if;
 insert into public.ranked_profiles(user_id,role,mmr)
 select owner_id,r.role,s.initial_mmr from private.ranked_settings s cross join (values ('demon'),('hero')) r(role)
 where s.singleton on conflict(user_id,role) do nothing;
 return jsonb_build_object('demon',private.ranked_state(owner_id,'demon'),'hero',private.ranked_state(owner_id,'hero'),
  'weekly_reward_tier',private.ranked_weekly_best(owner_id)->>'tier', 'public_uid',private.issue_public_uid(owner_id));
end $$;
commit;
