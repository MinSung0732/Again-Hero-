extends SceneTree

# Offline pixel authoring. Edges are uniform stretch strips; each corner stays
# inside its 32px nine-slice patch. No runtime drawing or texture processing.
const SHOP := preload("res://src/data/shop_catalog.gd")
var art: Image

func rect(x: int, y: int, w: int, h: int, color: Color) -> void:
	art.fill_rect(Rect2i(x, y, w, h), color)

func jewel(center: Vector2i, radius: int, color: Color, trim: Color) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var distance := absi(x - center.x) + absi(y - center.y)
			if distance > radius: continue
			var shade := Color("120b21") if distance >= radius - 1 else trim if distance >= radius - 3 else color.darkened(0.55)
			if distance <= radius - 5:
				shade = color.lightened(0.65) if x + y < center.x + center.y - 2 else color if x <= center.x else color.darkened(0.35)
			art.set_pixel(x, y, shade)

func build(rarity: String, rank: int) -> Error:
	art = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	art.fill(Color.TRANSPARENT)
	var color := Color("92929c") if rank == 0 else Color(SHOP.get_rarity(rarity).color)
	var trim := color.lightened(0.45) if rank < 3 else Color("d7b66d")
	var edge := [Color("120b21"), color.darkened(0.65), trim, color, color.darkened(0.45), Color("32273d"), Color("120b21")]
	for side in range(4):
		for p in range(28, 100):
			for t in range(edge.size()):
				var v := 8 + t
				var pos := Vector2i(p, v)
				if side == 1: pos = Vector2i(127 - v, p)
				if side == 2: pos = Vector2i(p, 127 - v)
				if side == 3: pos = Vector2i(v, p)
				art.set_pixelv(pos, edge[t])
	# Rank 0: compact iron brackets. Rank 1: broad brass plates/rivets.
	# Rank 2: a blue facet. Rank 3: gilded amethyst + stepped filigree.
	rect(6, 6, 24, 10, Color("120b21"))
	rect(6, 6, 10, 24, Color("120b21"))
	rect(8, 8, 22, 4, trim)
	rect(8, 8, 4, 22, trim)
	rect(12, 12, 18, 4, color.darkened(0.45))
	rect(12, 12, 4, 18, color.darkened(0.45))
	if rank == 0:
		rect(10, 10, 8, 8, color.darkened(0.6))
		rect(11, 11, 4, 4, color.lightened(0.35))
	elif rank == 1:
		rect(9, 9, 14, 14, color.darkened(0.4))
		rect(10, 10, 10, 4, trim)
		rect(10, 14, 4, 7, color)
		rect(14, 14, 4, 4, Color("fff4bb"))
		rect(24, 8, 3, 3, color)
		rect(8, 24, 3, 3, color)
	else:
		if rank == 3:
			for step in range(4):
				rect(2 + step * 2, 24 - step * 4, 3, 5, trim.darkened(0.1 * step))
				rect(24 - step * 4, 2 + step * 2, 5, 3, trim.darkened(0.1 * step))
		jewel(Vector2i(16, 16), 11 if rank == 2 else 13, color, trim)
		rect(12, 13, 3, 2, color.lightened(0.85))
		rect(13, 11, 2, 6, color.lightened(0.85))
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
	return art.save_png("res://assets/art/UI/clean_frames/formation_%s_frame.png" % rarity)

func _initialize() -> void:
	for rank in range(4):
		var rarity: String = SHOP.RARITY_ORDER[rank]
		var result := build(rarity, rank)
		if result != OK:
			quit(result)
			return
		print("FORMATION_FRAME: ", rarity)
	quit()
