-- Server-authoritative ranked results. Deploy together with protocol 8 clients/server.
begin;
create table public.ranked_profiles (
 user_id uuid primary key references auth.users(id) on delete cascade,
 mmr integer not null default 1000 check (mmr >= 0),
 wins integer not null default 0 check (wins >= 0),
 losses integer not null default 0 check (losses >= 0),
 updated_at timestamptz not null default now()
);
create index ranked_profiles_order on public.ranked_profiles (mmr desc, user_id);
create table public.ranked_matches (
 match_id text primary key check (length(match_id) between 1 and 128),
 demon_user uuid not null references auth.users(id) on delete cascade,
 hero_user uuid not null references auth.users(id) on delete cascade,
 winner text not null check (winner in ('demon','hero')),
 reason text not null,
 deltas jsonb not null,
 created_at timestamptz not null default now(),
 check (demon_user <> hero_user)
);
create table private.ranked_thresholds (
 minimum_mmr integer primary key,
 tier_id text not null unique
);
insert into private.ranked_thresholds values
 (0,'bronze_1'),(1100,'bronze_2'),(1200,'bronze_3'),(1300,'bronze_4'),
 (1400,'silver_1'),(1500,'silver_2'),(1600,'silver_3'),(1700,'silver_4'),
 (1800,'gold_1'),(1900,'gold_2'),(2000,'gold_3'),(2100,'gold_4'),
 (2200,'diamond_1'),(2300,'diamond_2'),(2400,'diamond_3'),(2500,'diamond_4'),(2600,'demon_lord');
create table private.ranked_scoring (
 outcome text primary key check (outcome in ('win','loss')),
 base integer not null,
 margin_scale integer not null
);
insert into private.ranked_scoring values ('win',10,20),('loss',10,15);
create table private.ranked_settings (
 singleton boolean primary key default true check (singleton),
 initial_mmr integer not null,
 minimum_mmr integer not null,
 hero_top_count integer not null
);
insert into private.ranked_settings values(true,1000,0,100);
alter table public.ranked_profiles enable row level security;
alter table public.ranked_matches enable row level security;
alter table private.ranked_thresholds enable row level security;
alter table private.ranked_scoring enable row level security;
alter table private.ranked_settings enable row level security;
revoke all on public.ranked_profiles, public.ranked_matches, private.ranked_thresholds, private.ranked_scoring, private.ranked_settings from public, anon, authenticated;

create function private.ranked_state(p_user uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare p public.ranked_profiles; rank_number bigint; tier text;
begin
 select * into p from public.ranked_profiles where user_id=p_user;
 if not found then return '{}'::jsonb; end if;
 select 1+count(*) into rank_number from public.ranked_profiles q
 where q.mmr>p.mmr or (q.mmr=p.mmr and q.user_id<p_user);
 select t.tier_id into tier from private.ranked_thresholds t
 where t.minimum_mmr<=p.mmr order by t.minimum_mmr desc limit 1;
 if tier='demon_lord' and rank_number<=(select hero_top_count from private.ranked_settings) then tier:='hero'; end if;
 return jsonb_build_object('mmr',p.mmr,'wins',p.wins,'losses',p.losses,
  'server_rank',rank_number,'tier',tier);
end $$;
revoke all on function private.ranked_state(uuid) from public, anon, authenticated;

create function public.record_ranked_result(
 p_match_id text, p_demon_user uuid, p_hero_user uuid, p_winner text,
 p_reason text, p_margin_demon numeric, p_margin_hero numeric
) returns jsonb language plpgsql security definer set search_path='' as $$
declare existing jsonb; demon_before integer; hero_before integer; locked_user uuid;
 demon_delta integer; hero_delta integer; win_rule private.ranked_scoring;
 loss_rule private.ranked_scoring; settings private.ranked_settings; result jsonb;
begin
 if p_match_id is null or length(p_match_id) not between 1 and 128 then
  raise exception 'invalid match id' using errcode='22023';
 end if;
 -- The match lock serializes retries, including calls arriving before first insert.
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p_match_id,0));
 select deltas into existing from public.ranked_matches where match_id=p_match_id;
 if found then return existing; end if;
 if p_demon_user is null or p_hero_user is null or p_demon_user=p_hero_user
 or p_winner is null or p_winner not in ('demon','hero') or p_reason is null or length(p_reason) not between 1 and 128
 or p_margin_demon is null or p_margin_hero is null
 or p_margin_demon not between 0 and 1 or p_margin_hero not between 0 and 1 then
  raise exception 'invalid ranked result' using errcode='22023';
 end if;
 select * into settings from private.ranked_settings;
 -- Insert and lock one account at a time in stable order to prevent deadlocks.
 for locked_user in select x.user_id from unnest(array[p_demon_user,p_hero_user]) as x(user_id) order by x.user_id loop
  insert into public.ranked_profiles(user_id,mmr) values(locked_user,settings.initial_mmr) on conflict(user_id) do nothing;
  perform 1 from public.ranked_profiles where user_id=locked_user for update;
 end loop;
 select mmr into demon_before from public.ranked_profiles where user_id=p_demon_user;
 select mmr into hero_before from public.ranked_profiles where user_id=p_hero_user;
 select * into win_rule from private.ranked_scoring where outcome='win';
 select * into loss_rule from private.ranked_scoring where outcome='loss';
 demon_delta:=case when p_winner='demon' then pg_catalog.round(win_rule.base+win_rule.margin_scale*p_margin_demon)::integer
  else -pg_catalog.round(loss_rule.base+loss_rule.margin_scale*p_margin_demon)::integer end;
 hero_delta:=case when p_winner='hero' then pg_catalog.round(win_rule.base+win_rule.margin_scale*p_margin_hero)::integer
  else -pg_catalog.round(loss_rule.base+loss_rule.margin_scale*p_margin_hero)::integer end;
 update public.ranked_profiles set mmr=greatest(settings.minimum_mmr,mmr+demon_delta),
 wins=wins+(p_winner='demon')::integer,losses=losses+(p_winner='hero')::integer,updated_at=now()
 where user_id=p_demon_user;
 update public.ranked_profiles set mmr=greatest(settings.minimum_mmr,mmr+hero_delta),
 wins=wins+(p_winner='hero')::integer,losses=losses+(p_winner='demon')::integer,updated_at=now()
 where user_id=p_hero_user;
 result:=jsonb_build_object('demon',private.ranked_state(p_demon_user) || jsonb_build_object('previous_mmr',demon_before,'delta',greatest(settings.minimum_mmr,demon_before+demon_delta)-demon_before),
  'hero',private.ranked_state(p_hero_user) || jsonb_build_object('previous_mmr',hero_before,'delta',greatest(settings.minimum_mmr,hero_before+hero_delta)-hero_before));
 insert into public.ranked_matches(match_id,demon_user,hero_user,winner,reason,deltas)
 values(p_match_id,p_demon_user,p_hero_user,p_winner,p_reason,result);
 return result;
end $$;
revoke all on function public.record_ranked_result(text,uuid,uuid,text,text,numeric,numeric) from public, anon, authenticated;
grant execute on function public.record_ranked_result(text,uuid,uuid,text,text,numeric,numeric) to service_role;

create function public.get_my_ranked_profile() returns jsonb
language plpgsql security definer set search_path='' as $$
declare owner_id uuid:=auth.uid();
begin
 if owner_id is null then raise exception 'authentication required' using errcode='42501'; end if;
 insert into public.ranked_profiles(user_id,mmr)
 select owner_id,initial_mmr from private.ranked_settings where singleton on conflict(user_id) do nothing;
 return private.ranked_state(owner_id);
end $$;
revoke all on function public.get_my_ranked_profile() from public, anon;
grant execute on function public.get_my_ranked_profile() to authenticated;
commit;
