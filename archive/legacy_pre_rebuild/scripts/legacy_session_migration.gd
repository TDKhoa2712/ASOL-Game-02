extends RefCounted

# Read-only compatibility boundary. The next normal save persists version 3.
# Never expose legacy vocabulary through the current game API.
static func to_current(source: Dictionary) -> Dictionary:
	var migrated := source.duplicate(true)
	if source.get("sessionVersion", -1) != 2:
		return migrated
	if typeof(source.get("cells")) != TYPE_ARRAY:
		return migrated
	for cell in source["cells"]:
		if cell not in ["empty", "x", "x_error", "cat"]:
			return migrated
	for index in migrated["cells"].size():
		if migrated["cells"][index] == "cat":
			migrated["cells"][index] = "candy"
	migrated["sessionVersion"] = 3
	return migrated
