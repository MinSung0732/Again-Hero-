extends RefCounted
class_name StageIntroDialogues


static func get_dialogue(stage_id: String) -> Dictionary:
	match stage_id:
		"stage_1":
			return _stage_1()
		_:
			return {}


static func _stage_1() -> Dictionary:
	return {
		"location": "[마왕성 최심부]",
		"hero_name": "견습 마도사",
		"lines": [
			{"speaker": "demon", "text": "……이 기척은."},
			{"speaker": "demon", "text": "설마 벌써 여기까지 들어온 건가?"},
			{"speaker": "hero", "text": "와아……"},
			{"speaker": "hero", "text": "여기가 진짜 마왕성 안쪽이구나!"},
			{"speaker": "demon", "text": "……."},
			{"speaker": "hero", "text": "아, 저기 있다!"},
			{"speaker": "hero", "text": "마왕 맞죠?!"},
			{"speaker": "demon", "text": "……너는 누구냐."},
			{"speaker": "hero", "text": "저요?"},
			{"speaker": "hero", "text": "용사예요!"},
			{"speaker": "demon", "text": "……용사?"},
			{"speaker": "hero", "text": "네!"},
			{"speaker": "hero", "text": "아직 견습이긴 한데……"},
			{"speaker": "hero", "text": "그래도 정식으로 용사 칭호도 받았어요!"},
			{"speaker": "demon", "text": "……."},
			{"speaker": "demon", "text": "인간들은 이제 어린아이에게까지 용사라는 이름을 붙이는 건가."},
			{"speaker": "hero", "text": "어린아이 아니거든요!"},
			{"speaker": "hero", "text": "그리고 저, 마법도 엄청 잘 써요!"},
			{"speaker": "demon", "text": "나는 수백 년 만에 다시 눈을 떴다."},
			{"speaker": "demon", "text": "군세조차 제대로 갖추지 못했거늘……"},
			{"speaker": "demon", "text": "첫 침입자가 이런 꼬맹이라니."},
			{"speaker": "hero", "text": "또 꼬맹이라고 했다!"},
			{"speaker": "demon", "text": "돌아가라."},
			{"speaker": "hero", "text": "네?"},
			{"speaker": "demon", "text": "오늘은 못 본 것으로 해주마."},
			{"speaker": "hero", "text": "……."},
			{"speaker": "hero", "text": "그건 좀 곤란한데요."},
			{"speaker": "demon", "text": "무엇이?"},
			{"speaker": "hero", "text": "저……"},
			{"speaker": "hero", "text": "오늘이 첫 임무라서요."},
			{"speaker": "demon", "text": "……그래서?"},
			{"speaker": "hero", "text": "빈손으로 돌아가면 엄청 창피하잖아요!"},
			{"speaker": "demon", "text": "……."},
			{"speaker": "hero", "text": "그러니까 마왕님!"},
			{"speaker": "hero", "text": "얌전히 쓰러져 주세요!"},
			{"speaker": "demon", "text": "……몇백 년을 잠들어 있었더니 세상이 많이 변했군."},
			{"speaker": "hero", "text": "히히."},
			{"speaker": "hero", "text": "긴장했었는데……"},
			{"speaker": "hero", "text": "생각보다 별거 아닌 것 같기도 하고!"},
			{"speaker": "demon", "text": "……."},
			{"speaker": "demon", "text": "좋다."},
			{"speaker": "demon", "text": "그 생각이 얼마나 오래 가는지 보도록 하지."},
			{"speaker": "hero", "text": "……어?"},
			{"speaker": "hero", "text": "자, 잠깐만요."},
			{"speaker": "hero", "text": "갑자기 분위기가 너무 무서워졌는데요?!"},
			{"speaker": "demon", "text": "첫 임무라고 했지, 용사."},
			{"speaker": "demon", "text": "후회할 시간은 전투가 끝난 뒤에도 충분하다."},
			{"speaker": "hero", "text": "으으……"},
			{"speaker": "hero", "text": "좋아!"},
			{"speaker": "hero", "text": "나도 용사니까…… 안 도망가!"},
			{"speaker": "hero", "text": "간다, 마왕!"},
			{"speaker": "demon", "text": "와라."},
		],
	}
