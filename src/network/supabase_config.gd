extends RefCounted
class_name SupabaseConfig

const PROJECT_URL := "https://xdmqpsyhtnyzzdhgvfep.supabase.co"
const PUBLISHABLE_KEY := "sb_publishable_NDw0fihKml9WpL3-MX-PTg_G10rSWOn"

static func is_configured() -> bool:
	return (
		not PROJECT_URL.is_empty()
		and not PUBLISHABLE_KEY.is_empty()
	)
