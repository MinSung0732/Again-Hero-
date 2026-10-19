extends RefCounted
## Explicit server opt-in, with a fresh invitation per server lifetime.
## No account IDs, reusable passwords or fixture tokens in public test traffic.
const SERVER_FLAG := "--localtest"
const TICKET_BYTES := 24
const SESSION_BYTES := 16
const UID_PREFIX := "localtest:"

static func new_ticket() -> String:
	return Crypto.new().generate_random_bytes(TICKET_BYTES).hex_encode()

static func new_session() -> String:
	return Crypto.new().generate_random_bytes(SESSION_BYTES).hex_encode()

static func valid_hex(value: String, bytes: int) -> bool:
	return value.length() == bytes * 2 and value.is_valid_hex_number(false)

static func session_uid(credentials: Dictionary, server_ticket: String) -> String:
	if not valid_hex(server_ticket, TICKET_BYTES): return ""
	if not credentials.get("ticket", null) is String or not credentials.get("session", null) is String: return ""
	var ticket: String = credentials.ticket
	var session: String = credentials.session
	if not valid_hex(ticket, TICKET_BYTES) or not valid_hex(session, SESSION_BYTES): return ""
	var difference := 0
	var expected := server_ticket.to_utf8_buffer()
	var supplied := ticket.to_utf8_buffer()
	for index in expected.size(): difference |= expected[index] ^ supplied[index]
	return UID_PREFIX + session if difference == 0 else ""
