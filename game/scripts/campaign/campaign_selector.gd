extends RefCounted

const CAMPAIGN_FILES := {
	"demo_30": "demo_30.json",
	"full_998": "full_998.json",
	"advanced": "advanced.json",
}

static func load_config(path: String, base_profile_dir: String, campaign_dir: String = "res://data/campaigns") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "campaign selector missing"}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {"ok": false, "error": "invalid campaign selector JSON"}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {"ok": false, "error": "invalid campaign selector JSON"}
	var choice: Variant = parsed.get("campaign")
	if not choice is String or not CAMPAIGN_FILES.has(choice):
		return {"ok": false, "error": "unknown campaign selection"}
	var playlist_path: String = campaign_dir.path_join(CAMPAIGN_FILES[choice])
	if not FileAccess.file_exists(playlist_path):
		return {"ok": false, "error": "selected playlist missing: " + playlist_path}
	var progress_dir := base_profile_dir if choice == "demo_30" else base_profile_dir.path_join("full_998")
	return {"ok": true, "playlist_path": playlist_path, "progress_dir": progress_dir, "error": ""}
