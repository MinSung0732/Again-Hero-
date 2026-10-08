extends SceneTree

# Native pixel UI asset, following the existing clean-frame palette.
# Offline authoring only: no rasterization/cropping loops run in the lobby.
var art := Image.create(128, 128, false, Image.FORMAT_RGBA8)

func rect(x: int, y: int, w: int, h: int, color: String) -> void:
	art.fill_rect(Rect2i(x, y, w, h), Color(color))

func _initialize() -> void:
	art.fill(Color.TRANSPARENT)
	for edge in [0, 1, 2, 3]:
		for p in range(28, 100):
			for t in range(8):
				var colors := ["120b21", "403249", "b6a6c6", "254136", "61e887", "1b7654", "383046", "120b21"]
				var v := 8 + t
				var pos := Vector2i(p, v)
				if edge == 1: pos = Vector2i(127 - v, p)
				if edge == 2: pos = Vector2i(p, 127 - v)
				if edge == 3: pos = Vector2i(v, p)
				art.set_pixelv(pos, Color(colors[t]))
	# One stepped jewel corner, reflected without interpolation into all corners.
	rect(6, 6, 24, 4, "120b21")
	rect(6, 6, 4, 24, "120b21")
	rect(10, 10, 20, 4, "aa99bd")
	rect(10, 10, 4, 20, "aa99bd")
	rect(14, 14, 16, 4, "4d365b")
	rect(14, 14, 4, 16, "4d365b")
	for y in range(2, 29):
		for x in range(2, 29):
			var diamond := absi(x - 15) + absi(y - 15)
			if diamond > 13: continue
			var color := "120b21" if diamond > 11 else "d7b66d" if diamond > 9 else "244737"
			if diamond <= 7:
				color = "c5ffdf" if x + y < 26 else "61e887" if x <= 15 else "259764" if y <= 18 else "115a46"
			art.set_pixel(x, y, Color(color))
	rect(10, 13, 4, 2, "efffeb")
	rect(11, 10, 2, 7, "efffeb")
	var corner := art.get_region(Rect2i(0, 0, 32, 32))
	var horizontal := corner.duplicate()
	horizontal.flip_x()
	var vertical := corner.duplicate()
	vertical.flip_y()
	var both := horizontal.duplicate()
	both.flip_y()
	art.blit_rect(horizontal, Rect2i(0, 0, 32, 32), Vector2i(96, 0))
	art.blit_rect(vertical, Rect2i(0, 0, 32, 32), Vector2i(0, 96))
	art.blit_rect(both, Rect2i(0, 0, 32, 32), Vector2i(96, 96))
	var error := art.save_png("res://assets/art/UI/clean_frames/transcendent_card_frame.png")
	print("TRANSCENDENT_FRAME: ", error)
	quit(error)
