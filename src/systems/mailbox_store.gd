extends RefCounted

const SCOPE := preload("res://src/systems/account_save_scope.gd")
const PROGRESS := preload("res://src/systems/stage_progress.gd")
const DATA := preload("res://src/data/mailbox_catalog.gd")

static func applied(id: String) -> bool:
	var config := ConfigFile.new()
	if SCOPE.load_config(config, PROGRESS.SAVE_PATH) != OK: return false
	return id in config.get_value("mailbox", "applied_mail_ids", [])

static func apply(id: String, attachments: Dictionary) -> bool:
	if id.is_empty() or attachments.is_empty(): return false
	var definitions := DATA.currencies()
	var config := ConfigFile.new()
	var error := SCOPE.load_config(config, PROGRESS.SAVE_PATH)
	if error != OK and error != ERR_FILE_NOT_FOUND: return false
	var ids: Array = Array(config.get_value("mailbox", "applied_mail_ids", [])).duplicate()
	if id in ids: return true
	for currency in attachments:
		var amount: Variant = attachments[currency]
		if not definitions.has(currency) or not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount) != floor(float(amount)) or amount <= 0: return false
		config.set_value("meta", currency, maxi(int(config.get_value("meta", currency, 0)), 0) + int(amount))
	ids.append(id)
	config.set_value("mailbox", "applied_mail_ids", ids)
	return SCOPE.save_configs({PROGRESS.SAVE_PATH.get_file(): config}) == OK

static func pending_ids() -> Array:
	var config := ConfigFile.new()
	if SCOPE.load_config(config, PROGRESS.SAVE_PATH) != OK: return []
	return Array(config.get_value("mailbox", "applied_mail_ids", [])).duplicate()

static func forget_acknowledged(ids: Array) -> bool:
	var config := ConfigFile.new()
	if SCOPE.load_config(config, PROGRESS.SAVE_PATH) != OK: return false
	var pending_ids: Array = Array(config.get_value("mailbox", "applied_mail_ids", [])).duplicate()
	for id in ids: pending_ids.erase(id)
	config.set_value("mailbox", "applied_mail_ids", pending_ids)
	return SCOPE.save_configs({PROGRESS.SAVE_PATH.get_file(): config}) == OK

static func pending(item: Dictionary) -> bool:
	return item.get("claim_state") == "unclaimed" or (item.get("applied_at") == null and not applied(String(item.get("id", ""))))

static func local_mail() -> Array:
	var result := DATA.LOCAL_MAIL.duplicate(true)
	for mail in result: mail["claim_state"] = "granted" if applied(mail.id) else "unclaimed"
	return result

static func recover(mail: Array) -> bool:
	var ok := true
	for item in mail:
		if item is Dictionary and item.get("claim_state") == "granted" and item.get("applied_at") == null and not applied(String(item.get("id", ""))):
			if not item.get("attachments") is Dictionary or not apply(String(item.get("id", "")), item.attachments): ok = false
	return ok

static func unread_count(mail: Array) -> int:
	var count := 0
	for item in mail:
		if item is Dictionary and pending(item): count += 1
	return count
