extends Control
## Repeat hero-only pillar tiles at a uniform scale instead of stretching demon art.
const ART := preload("res://src/ui/hero_hud_art.gd")
const HUD := preload("res://src/ui/hero_survival_hud.gd")
const TOP := HUD.BATTLE_TOP
const WIDTH := HUD.FRAME_WIDTH
var tiles: Array[Texture2D] = []
static func apply_view_insets(view: Control, enabled: bool) -> void:
	view.offset_left = WIDTH if enabled else 0.0
	view.offset_right = -WIDTH if enabled else 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for index in 4: tiles.append(ART.region(index))
	resized.connect(queue_redraw)
func _draw() -> void:
	if tiles.is_empty(): return
	var height := maxf(0.0,size.y-TOP)
	for side in 2:
		var left := 0.0 if side == 0 else size.x-WIDTH
		draw_rect(Rect2(left,TOP,WIDTH,height),Color("171020"))
		var y := TOP; var index := 0
		while y < size.y:
			var texture: Texture2D = tiles[(index%2)+side*2]
			var tile_height := WIDTH*texture.get_height()/texture.get_width()
			var visible_height := minf(tile_height,size.y-y)
			# Last tile is cropped at the bottom, never distorted.
			draw_texture_rect_region(texture,Rect2(left,y,WIDTH,visible_height),Rect2(0,0,texture.get_width(),texture.get_height()*visible_height/tile_height))
			y += tile_height; index += 1
