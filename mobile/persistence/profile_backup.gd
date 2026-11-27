extends RefCounted
## Portable checksummed profile envelope. Integrity check, not authentication or encryption.
const Store = preload("res://persistence/profile_store.gd")
const MAX_BYTES := 8*1024*1024
const FORMAT := "wizard-shooter-profile"

static func encode(profile: Dictionary) -> String:
	if not Store.valid_profile(profile): return ""
	var payload := JSON.stringify({"format":FORMAT,"schema":Store.SCHEMA,"profile":profile},"",true,true)
	var encoded := JSON.stringify({"payload":payload,"checksum":payload.sha256_text()},"",true,true)
	return encoded if encoded.to_utf8_buffer().size()<=MAX_BYTES else ""

static func decode(raw: String) -> Dictionary:
	if raw.is_empty() or raw.length()>MAX_BYTES or raw.to_utf8_buffer().size()>MAX_BYTES:
		return {"error":"Empty or oversized backup."}
	var envelope: Variant=JSON.parse_string(raw)
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("checksum") is String:
		return {"error":"Invalid backup format."}
	var payload: String=envelope.payload
	if payload.sha256_text()!=envelope.checksum: return {"error":"Backup checksum mismatch."}
	var decoded: Variant=JSON.parse_string(payload)
	if not decoded is Dictionary or decoded.get("format")!=FORMAT:
		return {"error":"Not a Wizard Shooter backup."}
	if decoded.get("schema")!=Store.SCHEMA:
		return {"error":"Unsupported backup version."}
	if not Store.valid_profile(decoded.get("profile")):
		return {"error":"Invalid collection or assignments."}
	return {"profile":decoded.profile}

static func summary(profile: Dictionary) -> String:
	return "%d wizards | %d retired | %d essence | %d completed runs" % [profile.roster.size(),profile.archive.size(),profile.essence,profile.settled_runs.size()]
