extends Sprite2D
class_name GroundShadow

const TEXTURE_SIZE := Vector2i(64, 32)
const SOLID_CORE_RADIUS := 0.56
const EDGE_SOFTNESS := 1.10

static var _shared_texture: ImageTexture

@export var display_size := Vector2(64.0, 22.0)
@export_range(0.0, 1.0, 0.01) var opacity := 0.48


func _ready() -> void:
	texture = _get_shared_texture()
	centered = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	self_modulate = Color(0.0, 0.0, 0.0, opacity)
	scale = Vector2(
		display_size.x / float(TEXTURE_SIZE.x),
		display_size.y / float(TEXTURE_SIZE.y)
	)
	set_process(false)


static func _get_shared_texture() -> ImageTexture:
	if _shared_texture != null:
		return _shared_texture

	var image := Image.create(
		TEXTURE_SIZE.x,
		TEXTURE_SIZE.y,
		false,
		Image.FORMAT_RGBA8
	)
	var center := Vector2(TEXTURE_SIZE) * 0.5
	var radii := center - Vector2.ONE
	for y in range(TEXTURE_SIZE.y):
		for x in range(TEXTURE_SIZE.x):
			var normalized := Vector2(
				(float(x) + 0.5 - center.x) / radii.x,
				(float(y) + 0.5 - center.y) / radii.y
			)
			var edge_distance := normalized.length()
			var edge_progress := clampf(
				(1.0 - edge_distance) / (1.0 - SOLID_CORE_RADIUS),
				0.0,
				1.0
			)
			var alpha := 1.0
			if edge_distance > SOLID_CORE_RADIUS:
				alpha = pow(edge_progress, EDGE_SOFTNESS)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	_shared_texture = ImageTexture.create_from_image(image)
	return _shared_texture
