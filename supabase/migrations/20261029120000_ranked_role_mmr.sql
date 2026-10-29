-- Existing profiles are test data: reset both roles to initial MMR and zero wins/losses.
-- Rollback requires an explicit policy for merging two role histories; do not drop a role blindly.
begin;
alter table public.ranked_profiles add column role text;
alter table public.ranked_profiles drop constraint ranked_profiles_pkey;
update public.ranked_profiles set role='demon', mmr=(select initial_mmr from private.ranked_settings where singleton), wins=0, losses=0, updated_at=now();
insert into public.ranked_profiles(user_id,role,mmr,wins,losses)
 select user_id,'hero',mmr,0,0 from public.ranked_profiles where role='demon';
alter table public.ranked_profiles alter column role set not null;
alter table public.ranked_profiles add constraint ranked_profiles_role_check check (role in ('demon','hero'));
alter table public.ranked_profiles add primary key (user_id, role);
drop index public.ranked_profiles_order;
create index ranked_profiles_order on public.ranked_profiles (role, mmr desc, user_id);

create function private.ranked_state(p_user uuid, p_role text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare p public.ranked_profiles; rank_number bigint; tier text;
begin
 select * into p from public.ranked_profiles where user_id=p_user and role=p_role;
 if not found then return '{}'::jsonb; end if;
 select 1+count(*) into rank_number from public.ranked_profiles q
 where q.role=p_role and (q.mmr>p.mmr or (q.mmr=p.mmr and q.user_id<p_user));
 select t.tier_id into tier from private.ranked_thresholds t
 where t.minimum_mmr<=p.mmr order by t.minimum_mmr desc limit 1;
 if tier='demon_lord' and rank_number<=(select hero_top_count from private.ranked_settings) then tier:='hero'; end if;
 return jsonb_build_object('mmr',p.mmr,'wins',p.wins,'losses',p.losses,'server_rank',rank_number,'tier',tier);
end $$;
revoke all on function private.ranked_state(uuid,text) from public, anon, authenticated;

-- Tier outranks MMR: a role with the hero title beats an unqualified demon lord.
create function private.ranked_weekly_best(p_user uuid) returns jsonb
language sql security definer set search_path='' as $$
 select state from (select private.ranked_state(p_user, r.role) as state
 from (values ('demon'),('hero')) as r(role)) s
 where state <> '{}'::jsonb
 order by (state->>'tier'='hero') desc, (state->>'mmr')::integer desc limit 1
$$;
revoke all on function private.ranked_weekly_best(uuid) from public, anon, authenticated;

create or replace function public.record_ranked_result(
 p_match_id text, p_demon_user uuid, p_hero_user uuid, p_winner text,
 p_reason text, p_margin_demon numeric, p_margin_hero numeric
) returns jsonb language plpgsql security definer set search_path='' as $$
declare existing jsonb; demon_before integer; hero_before integer; locked_user uuid; locked_role text;
 demon_delta integer; hero_delta integer; win_rule private.ranked_scoring;
 loss_rule private.ranked_scoring; settings private.ranked_settings; result jsonb;
begin
 if p_match_id is null or length(p_match_id) not between 1 and 128 then raise exception 'invalid match id' using errcode='22023'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_match_id,0));
 select deltas into existing from public.ranked_matches where match_id=p_match_id;
 if found then return existing; end if;
 if p_demon_user is null or p_hero_user is null or p_demon_user=p_hero_user
 or p_winner is null or p_winner not in ('demon','hero') or p_reason is null or length(p_reason) not between 1 and 128
 or p_margin_demon is null or p_margin_hero is null or p_margin_demon not between 0 and 1 or p_margin_hero not between 0 and 1 then
  raise exception 'invalid ranked result' using errcode='22023';
 end if;
 select * into settings from private.ranked_settings;
 for locked_user, locked_role in select v.user_id,v.role from (values (p_demon_user,'demon'),(p_hero_user,'hero')) v(user_id,role) order by v.user_id, v.role loop
  insert into public.ranked_profiles(user_id,role,mmr) values(locked_user,locked_role,settings.initial_mmr) on conflict(user_id,role) do nothing;
  perform 1 from public.ranked_profiles where user_id=locked_user and role=locked_role for update;
 end loop;
 select mmr into demon_before from public.ranked_profiles where user_id=p_demon_user and role='demon';
 select mmr into hero_before from public.ranked_profiles where user_id=p_hero_user and role='hero';
 select * into win_rule from private.ranked_scoring where outcome='win';
 select * into loss_rule from private.ranked_scoring where outcome='loss';
 demon_delta:=case when p_winner='demon' then pg_catalog.round(win_rule.base+win_rule.margin_scale*p_margin_demon)::integer else -pg_catalog.round(loss_rule.base+loss_rule.margin_scale*p_margin_demon)::integer end;
 hero_delta:=case when p_winner='hero' then pg_catalog.round(win_rule.base+win_rule.margin_scale*p_margin_hero)::integer else -pg_catalog.round(loss_rule.base+loss_rule.margin_scale*p_margin_hero)::integer end;
 update public.ranked_profiles set mmr=greatest(settings.minimum_mmr,mmr+demon_delta), wins=wins+(p_winner='demon')::integer,losses=losses+(p_winner='hero')::integer,updated_at=now() where user_id=p_demon_user and role='demon';
 update public.ranked_profiles set mmr=greatest(settings.minimum_mmr,mmr+hero_delta), wins=wins+(p_winner='hero')::integer,losses=losses+(p_winner='demon')::integer,updated_at=now() where user_id=p_hero_user and role='hero';
 result:=jsonb_build_object('demon',private.ranked_state(p_demon_user,'demon') || jsonb_build_object('previous_mmr',demon_before,'delta',greatest(settings.minimum_mmr,demon_before+demon_delta)-demon_before),
  'hero',private.ranked_state(p_hero_user,'hero') || jsonb_build_object('previous_mmr',hero_before,'delta',greatest(settings.minimum_mmr,hero_before+hero_delta)-hero_before));
 insert into public.ranked_matches(match_id,demon_user,hero_user,winner,reason,deltas) values(p_match_id,p_demon_user,p_hero_user,p_winner,p_reason,result);
 return result;
end $$;
revoke all on function public.record_ranked_result(text,uuid,uuid,text,text,numeric,numeric) from public, anon, authenticated;
grant execute on function public.record_ranked_result(text,uuid,uuid,text,text,numeric,numeric) to service_role;

create or replace function public.get_my_ranked_profile() returns jsonb
language plpgsql security definer set search_path='' as $$
declare owner_id uuid:=auth.uid();
begin
 if owner_id is null then raise exception 'authentication required' using errcode='42501'; end if;
 insert into public.ranked_profiles(user_id,role,mmr)
 select owner_id,r.role,s.initial_mmr from private.ranked_settings s cross join (values ('demon'),('hero')) r(role)
 where s.singleton on conflict(user_id,role) do nothing;
 return jsonb_build_object('demon',private.ranked_state(owner_id,'demon'),'hero',private.ranked_state(owner_id,'hero'),
  'weekly_reward_tier',private.ranked_weekly_best(owner_id)->>'tier');
end $$;
revoke all on function public.get_my_ranked_profile() from public, anon;
grant execute on function public.get_my_ranked_profile() to authenticated;
drop function private.ranked_state(uuid);
commit;
