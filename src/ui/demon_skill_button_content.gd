extends Control
# Fixed icon and two text lines; parent Button keeps all input/disabled handling.
var icon: TextureRect
var title: Label
var state: Label
var _last_available := false
var _state_initialized := false
func _init() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 clip_contents = true
 icon = TextureRect.new()
 icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(icon)
 title = _label(24,Color("ffe5a0"))
 state = _label(20,Color("d5c8e4"))
 resized.connect(_layout)
func _label(font_size: int, color: Color) -> Label:
 var label := Label.new()
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.autowrap_mode = TextServer.AUTOWRAP_OFF
 label.clip_text = true
 label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color)
 add_child(label)
 return label
func configure(texture: Texture2D, caption: String) -> void:
 icon.texture = texture
 title.text = caption
 _layout()
func update_state(text: String, available: bool) -> void:
 if state.text != text: state.text = text
 if _state_initialized and available == _last_available: return
 _state_initialized = true
 _last_available = available
 icon.modulate = Color.WHITE if available else Color(0.85,0.85,0.85,1)
 state.add_theme_color_override("font_color",Color("f3da88") if available else Color("d5c8e4"))
func _layout() -> void:
 var extent := minf(60,maxf(0,size.y-20))
 icon.position = Vector2(16,(size.y-extent)*0.5)
 icon.size = Vector2(extent,extent)
 var left := 16+extent+14
 var width := maxf(0,size.x-left-16)
 title.position = Vector2(left,size.y*0.5-29)
 title.size = Vector2(width,30)
 state.position = Vector2(left,size.y*0.5+1)
 state.size = Vector2(width,28)
