# 배포 용량·무기 이펙트 준비 최적화

작업 브랜치 feature/stage10-astra, 수정전원격 af59831afba54c23b4f69330670bf516381866bf, main10c9805842d745412ffe9b45e822896001ef27cb. 이전최적화의AI/공간그리드/풀구조는유지하며 실제반복작업·확인된미사용제작자료만처리했다.

## 배포 용량

활성 addons/againhero_oauth export plugin이 무기hero_weapon_v2 각폴더의 source.png/sprite_sheet.png/icon.png/manifest.json을skip한다. 제작자료는저장소에서삭제하지않는다. 현재91분리sequence와40추가iconatlas는이파일을읽지않는다. hero_augments 원본weapons.png/passives.png와assets/art/zeus_reassembled_v2.zip도배포제외. normalized2atlas/unique_v2 atlas/실프레임728개는유지한다. 의도한원본을향후게임에서직접사용하면 export 정책도함께갱신한다.

Android release template은 *.png include를사용한다. 전체raw PNG제외는기존다른UI/캐릭터 raw-loader에영향줄수있어이번에는하지않는다. 손실압축·도트리사이즈·음질변경없음. 플랫폼아키텍처/권한/서명/SDK설정변경없음.

## 코드·로딩·메모리

- 알려진91종은이전처럼디렉터리열거·정렬하지않고 effect_01~08을직접로드한다. 알파bounds의최대반경+2px과중심64,64를제작도구로계산해동일Rect2를저장한다. 이전GPU get_image/readback728회·bounds계산을없애고AtlasTexture만만든다. 실제선택키트는최대80프레임범위. 원본도트/정렬축/루프/크기/판정불변. 레거시경로의동적계산은보존한다.
- 입장시HeroWeaponArt staticcache를선택키트effectdirectory로제한한다. 여러캐릭터를순차플레이해도전체91sequence참조가누적되지않는다. 이미생성한runtime/projectile/liveactor는자신의Array/Texture참조를유지해현재연출이깨지지않는다.
- build_hero_effect_layouts.py --check는metadata최신성을검사한다. 프레임수정시도구재실행필수,prepare_hero_weapon_art.py --finalize에서자동연결.

## 측정·검증

동일이펙트·아이콘격리프로젝트,all_resources+*.png/*.json동일조건에서export plugin만전후비교했다. Linux Godot4.7.2 export-pack은Windows/Android와공유되는resourceexport경로를검증하며네이티브enginebinary는포함하지않는다.

| 측정 | 이전 | 이후 |
|---|---:|---:|
| PCK bytes | 16,365,084 | 5,759,400 |
| PCK MiB | 15.61 | 5.49 |

10,605,684bytes(10.12MiB)/64.8%절감. 전체제품APK/Windows용량은사용자build가제공되지않아측정하지않았다. GPU메모리/FPS실측없음.

Godotheadless검사: HERO_WEAPON_ART3547(기존2817+728bakedpixelparity+2cache수명),최적화PCK572(91종8프레임존재·제작파일제외·100무기/16보조icon),무기extension2193. 합6312PASS. 원본배우scene는격리에서null처리,네이티브GPUdraw는spy기록;전투완주·Windows/Android전체제품검증이아님. Python구문/layout최신/source참조/diff검사PASS.

재현: tools/build_effect_export_fixture.py <outside-repo>로baseline구성→Godot --headless --path <fixture> --editor --export-pack Pack <before.pck>. 같은fixture에 --optimized로재구성→<after.pck>내보내기→Godot --headless --main-pack <after.pck>. 성공검사는 tests/hero_effect_export_smoke.gd. 아트회귀는build_hero_weapon_art_fixture.py와tests/hero_weapon_art_smoke.gd.

적용: Godot종료→feature최신코드받기→Godot다시열고import완료→Windows/APK다시내보내기. 프로젝트설정의Again Hero OAuth Return 플러그인이활성화되어야자동제외동작한다. main자동병합없음.
