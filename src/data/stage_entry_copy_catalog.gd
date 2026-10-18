extends RefCounted
# One-line hints; full combat descriptions remain in StageCatalog.
const SUMMARIES := {
	"stage_1":"원거리 마법 · 둔화와 포위",
	"stage_2":"연속 찌르기 · 탱커와 집중 화력",
	"stage_3":"검과 방패 · 지속 화력",
	"stage_4":"권총 연사 · 장전 중 압박",
	"stage_5":"원소 마법 · 큰 기술 후 공세",
	"stage_6":"광전사 · 탱커 뒤 화력 배치",
	"stage_7":"화학 공격 · 위험 구역 주의",
	"stage_8":"소환술 · 본체와 소환수 분산 대응",
	"stage_9":"정화 기술 · 공세 이어 보내기",
	"stage_10":"대현자 · 기술 종료 후 집중 공세",
}
static func summary(stage_id: String) -> String:
	return String(SUMMARIES.get(stage_id,"앞선 스테이지 클리어 필요"))
