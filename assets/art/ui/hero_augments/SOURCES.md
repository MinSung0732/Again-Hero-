# 용사 증강 아이콘 — 2026-10-13

사용자 요청으로 imagegen 스킬 / image_gen 내장 도구에서 새로 생성했다. 외부 다운로드/라이선스 이미지/기존 캐릭터 복제 없음. 원본RGBA PNG를 복사해 그대로 저장했다. `weapons.png` 971×1619, 6열10행(60종), `passives.png` 1774×887, 4열2행(8종). PNG 파일이 런타임 리소스이며 base64는 GitHub 바이너리 전달에만 사용한다.

모든 셀은 `manifest.json`에 실제 픽셀Rect와 안정적인 증강 ID/이름으로 기록했다. 용사 키트 순서는 `HeroWeaponCatalog.HERO_WEAPONS` 행 순서, 키트 내부6무기 순서는 열 순서다. 보조 순서는 공격/이동/투사체속도/공속/경험치/획득반경/체력/피감. 회복 fallback은 체력 아이콘을 재사용한다. `hero_augment_icons.gd`는 반올림 셀 경계/AtlasTexture 캐시/filter_clip을 사용한다. 선택 카드와 HUD에서 nearest 필터로 표시하며 신규 몬스터/공격 애니메이션 에셋은 아니다.

원본은 투명 배경이고 모든68셀에 시각 콘텐츠가 있다. 생성 원본 시트의 배열과 아이콘 주제를 확인했다. 복구 후 Godot4.5.1 headless의 실제 HeroMode 선택 카드에서 아이콘Texture 연결/nearest 필터/화면내배치를 확인했다. 실제 화면 렌더·모바일 UI 크기·터치 영역 검수는 미실행이다.

## 사용한 프롬프트

두 프롬프트 모두 다음 공통 지시와 시트별 지시를 이어 붙여 사용했다. `transparent_background=true`.

공통:

> Create a production game UI icon ATLAS PNG, transparent background, perfectly regular grid, ALL icons centered on their own equal-size cells with generous 25% transparent margins. Orthographic flat pixel art with chunky visible square pixels, 32x32-style designs enlarged with nearest neighbor. Hard opaque pixel edges, no antialiasing, no gradients, no shadows outside icon, no text, no labels, no frames, no grid lines. No missing cells, no overlapping cells. Every symbol clear at small mobile size. Exact arrangement matters.

보조 시트:

> Exactly FOUR COLUMNS by TWO ROWS, aspect ratio 2:1, equal square cells. Row 1 left to right: glowing red sword with upward red arrow (attack); turquoise winged boots (movement); golden fast arrow with speed streaks (projectile speed); violet dagger and clock (attack speed). Row 2: emerald experience crystal with small gold plus; cyan magnet attracting three green crystals (pickup radius); bright red heart with small gold plus (maximum health); blue steel shield with downward small red damage arrow (damage reduction). All eight distinct objects fully contained in cells.

무기 시트:

> Exactly SIX COLUMNS by TEN ROWS, aspect ratio 3:5, equal square cells, 60 different fantasy weapon icons. Each row a themed hero loadout. Row1 purple wizard: arcane bolt staff, star wand, magic spear, rune ring, pulse staff, barrier book. Row2 green rogue: dagger, throwing knife, shadow wire spool, poison needle, crescent blade, shadow bomb. Row3 steel knight: longsword, piercing spear, aegis shield, shield hammer, blade ring, battle banner. Row4 gold gunner: revolver, shotgun, rifle, ricochet bullet, grenade, powder bomb. Row5 mage: fire staff, ice scepter, lightning rod, earth staff, storm orb, prism wand. Row6 crimson berserker: blood sword, blood lance, blood wheel, blood burst orb, drain blade, heart chain. Row7 alchemist: acid vial, poison flask, cryo vial, reaction bomb, acid cannon, life elixir. Row8 teal summoner: gate hound head, watcher eye, scout sprite, gate laser prism, gatekeeper shield, rift pulse portal. Row9 holy gold cleric: holy bolt crossbow, holy lance, purification chalice, sacred orb, blessing hand, prayer book. Row10 cosmic sage: starlight staff, comet spear, astral chain, absolute zero ice orb, singularity black violet orb, binary twin stars ring. Exactly six centered objects in every row, ten rows total.
