# cell_model.gd
extends RefCounted

enum CellKind {
	BLANK = 0,      # Ô trống, chưa đánh dấu
	MARK = 1,       # Player đánh X (xóa được)
	CANDY = 2,      # Candy đặt đúng
	WRONG = 3,      # Candy đặt sai (hiện X đỏ)
	GIVEN = 4,      # Candy cho trước (from givens, immutable)
	LOCKED = 5,     # System auto-mark sau candy (player không xóa được)
}

static func is_empty(kind: int) -> bool:
	return kind == CellKind.BLANK

static func is_placed(kind: int) -> bool:
	return kind == CellKind.CANDY or kind == CellKind.GIVEN

static func is_candy(kind: int) -> bool:
	return kind == CellKind.CANDY or kind == CellKind.GIVEN

static func is_cross(kind: int) -> bool:
	return kind == CellKind.MARK or kind == CellKind.WRONG or kind == CellKind.LOCKED

static func is_locked(kind: int) -> bool:
	return kind == CellKind.GIVEN or kind == CellKind.LOCKED

static func is_available(kind: int) -> bool:
	return kind == CellKind.BLANK or kind == CellKind.MARK

static func label(kind: int) -> String:
	match kind:
		CellKind.BLANK: return "blank"
		CellKind.MARK: return "mark"
		CellKind.CANDY: return "candy"
		CellKind.WRONG: return "wrong"
		CellKind.GIVEN: return "given"
		CellKind.LOCKED: return "locked"
	return "unknown"
