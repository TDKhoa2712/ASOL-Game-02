# select_context.gd
class_name SelectContext
extends RefCounted

var level_num: int = 1
var size: int = 4
var rank: int = 1
var tier: String = "N"
var is_hard: bool = false
var is_super_hard: bool = false
var relaxation_phase: int = 0
