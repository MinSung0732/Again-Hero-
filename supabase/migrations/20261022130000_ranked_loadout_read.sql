-- Deploy with protocol 9 server and client. Only the service role may read another user's loadout.
begin;
create function public.read_ranked_loadout(p_user uuid, p_hero_stage text, p_monster_ids text[]) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare saved jsonb; collection jsonb; owned jsonb := '{}'::jsonb; clears jsonb := '{}'::jsonb; monster_id text;
begin
  if p_user is null or p_hero_stage is null or (p_hero_stage <> '' and p_hero_stage !~ '^stage_[0-9]{1,2}$')
     or p_monster_ids is null or cardinality(p_monster_ids) > 4 then
    raise exception 'invalid loadout query' using errcode = '22023';
  end if;
  select payload into saved from public.account_save_snapshots where user_id = p_user;
  if not found then return '{}'::jsonb; end if;
  collection := coalesce(saved #> '{monster_collection.cfg,monsters}', '{}'::jsonb);
  if jsonb_typeof(collection) <> 'object' then return '{}'::jsonb; end if;
  foreach monster_id in array p_monster_ids loop
    if monster_id is null or monster_id !~ '^[a-z0-9_]{1,64}$' then
      raise exception 'invalid monster id' using errcode = '22023';
    end if;
    if collection ? (monster_id || '_unlocked') then
      owned := owned || jsonb_build_object(monster_id || '_unlocked', collection -> (monster_id || '_unlocked'));
    end if;
    if collection ? (monster_id || '_shards') then
      owned := owned || jsonb_build_object(monster_id || '_shards', collection -> (monster_id || '_shards'));
    end if;
  end loop;
  if p_hero_stage <> '' then
    clears := jsonb_build_object('stage_3', saved #> '{stage_progress.cfg,cleared,stage_3}')
      || jsonb_build_object(p_hero_stage, saved #> array['stage_progress.cfg','cleared',p_hero_stage]);
  end if;
  return jsonb_build_object(
    'progress', jsonb_build_object('cleared', clears),
    'monsters', owned,
    'team_ids', coalesce(saved #>> '{team_loadout.cfg,team,monster_ids}', ''),
    'skill_ids', coalesce(saved #>> '{demon_skill_loadout.cfg,skills,skill_ids}', ''),
    'transcendence_id', coalesce(saved #>> '{team_loadout.cfg,transcendence,monster_id}', '')
  );
end $$;
revoke all on function public.read_ranked_loadout(uuid,text,text[]) from public, anon, authenticated;
grant execute on function public.read_ranked_loadout(uuid,text,text[]) to service_role;
commit;
