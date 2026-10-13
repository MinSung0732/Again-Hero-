extends Control
const ART := preload("res://src/ui/castle_battle_chrome.gd")
var surround: Texture2D
var floor_backing: Texture2D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	surround = ART.texture(self,ART.ROOT+"castle_surround.png")
	floor_backing = ART.texture(self,ART.ROOT+"flagstone_floor.png")
	resized.connect(queue_redraw)
func _draw() -> void:
	if surround == null: return
	for side in [0.0,size.x-90.0]:
		if floor_backing != null: draw_texture_rect_region(floor_backing,Rect2(side,330,90,maxf(1,size.y-330)),Rect2(0,0,180,1254))
	draw_texture_rect_region(surround,Rect2(0,330,90,maxf(1,size.y-330)),Rect2(0,550,196,920))
	draw_texture_rect_region(surround,Rect2(size.x-90,330,90,maxf(1,size.y-330)),Rect2(828,550,196,920))
