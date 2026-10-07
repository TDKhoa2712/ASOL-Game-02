# strategy_modifier.gd
class_name StrategyModifier
extends RefCounted


static func strategy_to_rank(strategy: int) -> int:
	match strategy:
		5: return 4
		6: return 5
		7: return 5
		_: return clampi(strategy, 1, 5)


static func strategy_to_tier(strategy: int) -> String:
	match strategy:
		5, 7: return "H"
		_: return "N"


static func rank_tier_to_strategy(rank: int, tier: String) -> int:
	if rank == 4 and tier == "H":
		return 5
	if rank == 5:
		return 7 if tier == "H" else 6
	return rank
