begin;
-- Only the public ranking fields escape this function; owner policies remain unchanged.
create function public.get_ranked_leaderboard(role text, page_offset integer, page_size integer)
returns table(rank bigint, nickname text, tier text, mmr integer)
language plpgsql stable security definer set search_path = '' as $$
begin
 if auth.uid() is null then raise exception 'authentication required' using errcode='42501'; end if;
 if role is null or role not in ('hero','demon') or page_offset is null or page_offset < 0
    or page_size is null or page_size < 1 or page_size > 20 then
  raise exception 'invalid leaderboard page' using errcode='22023';
 end if;
 return query
 select ranked.position, p.nickname,
  case when t.tier_id='demon_lord' and ranked.position <= s.hero_top_count then 'hero' else t.tier_id end,
  ranked.score
 from (select r.user_id, r.mmr as score, row_number() over (order by r.mmr desc, r.user_id) as position
       from public.ranked_profiles r where r.role=get_ranked_leaderboard.role) ranked
 left join public.player_profiles p on p.user_id=ranked.user_id
 cross join private.ranked_settings s
 left join lateral (select x.tier_id from private.ranked_thresholds x where x.minimum_mmr<=ranked.score order by x.minimum_mmr desc limit 1) t on true
 where s.singleton order by ranked.position offset page_offset limit page_size;
end $$;
revoke all on function public.get_ranked_leaderboard(text, integer, integer) from public, anon;
grant execute on function public.get_ranked_leaderboard(text, integer, integer) to authenticated;
commit;
