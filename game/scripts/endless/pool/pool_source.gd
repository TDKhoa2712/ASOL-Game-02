# pool_source.gd
class_name PoolSource
extends RefCounted

var source_id: StringName = &""
var priority: int = 0
var inject_every: int = 0
var apply_transform: bool = true
var levels: Array = []
