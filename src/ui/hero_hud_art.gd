extends RefCounted
## Authored hero-only atlas; cache regions once. No bitmap work during battle.
const ATLAS := preload("res://assets/art/ui/hero_hud/hero_hud_atlas.png")
const ICON_KEYS := ["damage","armor","speed","haste","hp","siphon","area","reach","count","projectile","duration","xp"]
static var cache: Dictionary = {}
static func region(index: int) -> AtlasTexture:
	var key := str(index)
	if not cache.has(key):
		var cell := ATLAS.get_size()/4.0
		var result := AtlasTexture.new(); result.atlas = ATLAS
		var left := roundf((index%4)*cell.x); var top := roundf(int(index/4)*cell.y)
		var right := roundf((index%4+1)*cell.x); var bottom := roundf((int(index/4)+1)*cell.y)
		result.region = Rect2(left,top,right-left,bottom-top)
		if index < 4:
			result.region.position.x += roundf(result.region.size.x*0.33)
			result.region.size.x = roundf(result.region.size.x*0.34)
		result.filter_clip = true
		cache[key] = result
	return cache[key]
static func icon(key: String) -> Texture2D:
	var index := ICON_KEYS.find(key)
	return region(4+maxi(0,index))
