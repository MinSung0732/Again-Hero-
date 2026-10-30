-- Weekly ranking settlement. Thresholds and reward values mirror ranked_badges.json;
-- update both from that file using tools/sync_ranked_weekly_sql.ps1 before deployment.
begin;
create table private.ranked_reward_tiers (
 tier_id text primary key, reset_mmr integer not null, demon_token integer not null, hero_token integer not null
);
create table private.ranked_hero_reward_bands (min_rank integer not null, max_rank integer not null, amount integer not null);
-- BEGIN GENERATED RANKED REWARDS
insert into private.ranked_reward_tiers(tier_id,reset_mmr,demon_token,hero_token) values
 ('bronze_1',1000,20,20),
 ('bronze_2',1000,22,22),
 ('bronze_3',1000,24,24),
 ('bronze_4',1000,26,26),
 ('silver_1',1400,30,30),
 ('silver_2',1400,32,32),
 ('silver_3',1400,34,34),
 ('silver_4',1400,36,36),
 ('gold_1',1800,40,40),
 ('gold_2',1800,42,42),
 ('gold_3',1800,44,44),
 ('gold_4',1800,46,46),
 ('diamond_1',2300,60,60),
 ('diamond_2',2300,64,64),
 ('diamond_3',2300,68,68),
 ('diamond_4',2300,72,72),
 ('demon_lord',2900,85,85),
 ('hero',2900,0,0);
insert into private.ranked_hero_reward_bands(min_rank,max_rank,amount) values
 (1,1,300),
 (2,10,250),
 (11,20,200),
 (21,50,150),
 (51,100,100);
-- END GENERATED RANKED REWARDS
-- Keep the live profile's preview consistent with settlement, including ties.
create or replace function private.ranked_weekly_best(p_user uuid) returns jsonb
language sql security definer set search_path='' as $$
 select state from (select r.role, private.ranked_state(p_user, r.role) as state
 from (values ('demon'),('hero')) as r(role)) s
 where state <> '{}'::jsonb
 order by (state->>'mmr')::integer desc, role limit 1
$$;
create table public.ranked_season_results (
 user_id uuid not null references auth.users(id) on delete cascade,
 week_start date not null, demon jsonb, hero jsonb, reward_tier text not null,
 demon_token integer not null, hero_token integer not null, seen boolean not null default false,
 primary key(user_id, week_start)
);
create table public.mailbox (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 kind text not null, title text not null, body text not null,
 attachments jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(), claim_state text not null default 'unclaimed' check (claim_state in ('unclaimed','granted')), granted_at timestamptz, applied_at timestamptz
);
create index mailbox_user_created on public.mailbox(user_id, created_at desc);
create table private.ranked_settlement_runs (week_start date primary key, settled_at timestamptz not null default now());
alter table public.ranked_season_results enable row level security;
alter table public.mailbox enable row level security;
create policy ranked_results_select on public.ranked_season_results for select to authenticated using ((select auth.uid()) = user_id);
create policy mailbox_select on public.mailbox for select to authenticated using ((select auth.uid()) = user_id);
revoke all on public.ranked_season_results, public.mailbox from public, anon, authenticated;
grant select on public.ranked_season_results, public.mailbox to authenticated;

create function public.list_my_mail(p_recent_limit integer default 200) returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object('mail', coalesce(jsonb_agg(to_jsonb(m) order by (m.claim_state='granted' and m.applied_at is null) desc, m.created_at desc, m.id desc), '[]'::jsonb))
 from (select * from public.mailbox where user_id=auth.uid() and claim_state='granted' and applied_at is null
 union all
 select * from (select * from public.mailbox where user_id=auth.uid() and not (claim_state='granted' and applied_at is null) order by created_at desc, id desc limit greatest(1,least(coalesce(p_recent_limit,200),1000))) recent) m
$$;
create function public.ack_mail(p_ids uuid[]) returns jsonb
language sql security definer set search_path='' as $$
 with updated as (update public.mailbox set applied_at=coalesce(applied_at,now()) where user_id=auth.uid() and claim_state='granted' and id=any(p_ids) returning id)
 select jsonb_build_object('ids',coalesce(jsonb_agg(id),'[]'::jsonb)) from updated
$$;
create function public.latest_unseen_ranked_season() returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object('result', (select to_jsonb(r) from public.ranked_season_results r where r.user_id=auth.uid() and not r.seen order by r.week_start desc limit 1))
$$;
create function public.grant_mail(p_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare item public.mailbox;
begin
 if auth.uid() is null then raise exception 'authentication required' using errcode='42501'; end if;
 update public.mailbox set claim_state='granted', granted_at=coalesce(granted_at,now()) where id=p_id and user_id=auth.uid() returning * into item;
 if not found then return null; end if;
 return jsonb_build_object('id',item.id,'attachments',item.attachments);
end $$;
create function public.mark_ranked_season_seen(p_week_start date) returns jsonb
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'authentication required' using errcode='42501'; end if;
 update public.ranked_season_results set seen=true where user_id=auth.uid() and week_start=p_week_start;
 return jsonb_build_object('seen',found);
end $$;
revoke all on function public.list_my_mail(integer), public.ack_mail(uuid[]), public.latest_unseen_ranked_season(), public.grant_mail(uuid), public.mark_ranked_season_seen(date) from public, anon;
grant execute on function public.list_my_mail(integer), public.ack_mail(uuid[]), public.latest_unseen_ranked_season(), public.grant_mail(uuid), public.mark_ranked_season_seen(date) to authenticated;

create function private.settle_ranked_week() returns void
language plpgsql security definer set search_path='' as $$
declare start_date date := (date_trunc('week', (now() at time zone 'Asia/Seoul') - interval '3 days') + interval '3 days' - interval '7 days')::date;
begin
 -- Block concurrent result writes and profile creation while snapshotting and resetting.
 lock table public.ranked_profiles in share row exclusive mode;
 insert into private.ranked_settlement_runs(week_start) values(start_date) on conflict do nothing;
 if not found then return; end if;
 create temporary table ranked_week_snapshot on commit drop as
 select p.user_id,p.role,p.mmr,p.wins,p.losses,
 row_number() over(partition by p.role order by p.mmr desc,p.user_id) as server_rank
 from public.ranked_profiles p;
 create temporary table ranked_week_states on commit drop as
 select s.*, case when t.tier_id='demon_lord' and s.server_rank <= (select hero_top_count from private.ranked_settings where singleton)
 then 'hero' else t.tier_id end as tier
 from ranked_week_snapshot s cross join lateral
 (select tier_id from private.ranked_thresholds where minimum_mmr<=s.mmr order by minimum_mmr desc limit 1) t;
 insert into public.ranked_season_results(user_id,week_start,demon,hero,reward_tier,demon_token,hero_token)
 select u.user_id,start_date,
 (select jsonb_build_object('final_tier',tier,'final_mmr',mmr,'server_rank',server_rank,'wins',wins,'losses',losses) from ranked_week_states where user_id=u.user_id and role='demon'),
 (select jsonb_build_object('final_tier',tier,'final_mmr',mmr,'server_rank',server_rank,'wins',wins,'losses',losses) from ranked_week_states where user_id=u.user_id and role='hero'),
 best.tier,coalesce(b.amount,r.demon_token),coalesce(b.amount,r.hero_token)
 from (select distinct user_id from ranked_week_states) u
 cross join lateral (select tier,server_rank from ranked_week_states where user_id=u.user_id order by mmr desc, role limit 1) best
 join private.ranked_reward_tiers r on r.tier_id=best.tier
 left join private.ranked_hero_reward_bands b on best.tier='hero' and best.server_rank between b.min_rank and b.max_rank
 where exists (select 1 from ranked_week_states played where played.user_id=u.user_id and played.wins+played.losses>=1);
 insert into public.mailbox(user_id,kind,title,body,attachments)
 select user_id,'ranked_weekly','주간 랭크 보상','지난 주 랭크 정산 보상입니다.',jsonb_build_object('demon_token',demon_token,'hero_token',hero_token)
 from public.ranked_season_results where week_start=start_date;
 update public.ranked_profiles p set mmr=case when s.mmr=r.reset_mmr and s.tier not in ('hero','demon_lord') then coalesce((select max(t.reset_mmr) from private.ranked_reward_tiers t where t.reset_mmr<r.reset_mmr),r.reset_mmr) else r.reset_mmr end,wins=0,losses=0,updated_at=now()
 from ranked_week_states s join private.ranked_reward_tiers r on r.tier_id=s.tier
 where p.user_id=s.user_id and p.role=s.role;
end $$;
revoke all on function private.settle_ranked_week() from public, anon, authenticated;
-- pg_cron uses UTC: Wednesday 15:00 UTC = Thursday 00:00 KST.
create extension if not exists pg_cron with schema pg_catalog;
select cron.schedule('ranked-weekly-settlement','0 15 * * 3','select private.settle_ranked_week()');
commit;
