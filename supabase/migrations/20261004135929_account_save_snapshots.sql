-- Additive, account-owned snapshots. Existing legacy progression is never deleted.
create table public.account_save_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 1 check (revision > 0),
  payload jsonb not null check (jsonb_typeof(payload) = 'object' and octet_length(payload::text) <= 1000000),
  updated_at timestamptz not null default now()
);
alter table public.account_save_snapshots enable row level security;
create policy snapshot_select on public.account_save_snapshots for select to authenticated using ((select auth.uid()) = user_id);
create policy snapshot_insert on public.account_save_snapshots for insert to authenticated with check ((select auth.uid()) = user_id);
create policy snapshot_update on public.account_save_snapshots for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
revoke all on public.account_save_snapshots from anon, authenticated;
grant select, insert, update on public.account_save_snapshots to authenticated;

create function public.read_game_save() returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare saved public.account_save_snapshots; legacy public.player_progress;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  select * into saved from public.account_save_snapshots where user_id = auth.uid();
  if found then
    return jsonb_build_object('found', true, 'revision', saved.revision, 'payload', saved.payload);
  end if;
  select * into legacy from public.player_progress where user_id = auth.uid();
  if found then
    return jsonb_build_object('found', true, 'revision', 0, 'legacy', true, 'payload',
      jsonb_build_object('stage_progress.cfg', jsonb_build_object(
        'progress', jsonb_build_object('current_stage_id', legacy.current_stage_id, 'highest_unlocked_stage', legacy.highest_unlocked_stage),
        'meta', jsonb_build_object('research_points', legacy.research_points),
        'research', coalesce(legacy.research_levels, '{}'::jsonb))));
  end if;
  return jsonb_build_object('found', false, 'revision', 0);
end $$;

create function public.save_game_snapshot(expected_revision bigint, new_payload jsonb) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare next_revision bigint;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  if expected_revision < 0 or new_payload is null or jsonb_typeof(new_payload) <> 'object' or octet_length(new_payload::text) > 1000000 then
    raise exception 'invalid save';
  end if;
  if exists (select 1 from jsonb_object_keys(new_payload) k where k not in ('stage_progress.cfg','monster_collection.cfg','team_loadout.cfg','demon_skill_loadout.cfg','shop_summon_history.cfg')) then
    raise exception 'unsupported save file';
  end if;
  if expected_revision = 0 then
    insert into public.account_save_snapshots(user_id, payload) values(auth.uid(), new_payload)
    on conflict (user_id) do nothing returning revision into next_revision;
  else
    update public.account_save_snapshots set payload = new_payload, revision = revision + 1, updated_at = now()
    where user_id = auth.uid() and revision = expected_revision returning revision into next_revision;
  end if;
  if next_revision is null then return jsonb_build_object('conflict', true); end if;
  return jsonb_build_object('ok', true, 'revision', next_revision);
end $$;
revoke all on function public.read_game_save() from public, anon;
revoke all on function public.save_game_snapshot(bigint,jsonb) from public, anon;
grant execute on function public.read_game_save() to authenticated;
grant execute on function public.save_game_snapshot(bigint,jsonb) to authenticated;
