# settlement_handler.gd
class_name SettlementHandler
extends RefCounted


func on_level_complete(result: Dictionary, progress: RefCounted, _config: RefCounted) -> void:
	var current: int = progress.get_strategy()
	var won: bool = bool(result.get("won", false))

	if won:
		var hints_used: int = int(result.get("hints_used", 0))
		var time_spent: float = float(result.get("time", 0.0))
		var par_time: float = float(result.get("par_time", 999999.0))
		if hints_used == 0 and (par_time <= 0.0 or time_spent < par_time):
			current = mini(current + 1, 7)
		progress.record_win(time_spent, int(result.get("size", 0)))
	else:
		current = maxi(current - 1, 1)
		progress.record_loss()

	progress.set_strategy(current)
	progress.advance_level()
