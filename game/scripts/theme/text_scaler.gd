# text_scaler.gd — scales every text Control in a subtree for the "large text" setting.
# Remembers each node's base size in metadata so toggling is reversible and idempotent.
extends RefCounted

const FACTOR := 1.25
const META_BASE := "_lt_base"
const META_APPLIED := "_lt_applied"
const META_HAD_OVERRIDE := "_lt_had_override"

static func apply(node: Node, enabled: bool) -> void:
	if node is Control:
		_apply_one(node as Control, enabled)
	for child in node.get_children():
		apply(child, enabled)

static func _is_text(c: Control) -> bool:
	return c is Label or c is Button or c is LineEdit or c is RichTextLabel or c is ItemList or c is TextEdit

static func _apply_one(c: Control, enabled: bool) -> void:
	if not _is_text(c):
		return
	var current := c.get_theme_font_size("font_size")
	var has_meta := c.has_meta(META_BASE)
	# Code changed the size after we scaled it: treat the new value as the base.
	if has_meta and current != int(c.get_meta(META_APPLIED)):
		c.set_meta(META_BASE, current)
		c.set_meta(META_HAD_OVERRIDE, true)
	elif not has_meta:
		c.set_meta(META_BASE, current)
		c.set_meta(META_HAD_OVERRIDE, c.has_theme_font_size_override("font_size"))
	var base := int(c.get_meta(META_BASE))
	if enabled:
		var scaled := int(round(base * FACTOR))
		c.add_theme_font_size_override("font_size", scaled)
		c.set_meta(META_APPLIED, scaled)
	else:
		if bool(c.get_meta(META_HAD_OVERRIDE)):
			c.add_theme_font_size_override("font_size", base)
		else:
			c.remove_theme_font_size_override("font_size")
		c.set_meta(META_APPLIED, c.get_theme_font_size("font_size"))
