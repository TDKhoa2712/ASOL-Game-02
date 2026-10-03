# cell_model.gd
extends RefCounted

enum CellKind {
	BLANK = 0,      # Ô trống, chưa đánh dấu
	MARK = 1,       # Player đánh X (xóa được)
	CANDY = 2,      # Candy đặt đúng
	ERROR = 3,      # Candy đặt sai (hiện X đỏ, không xóa được)
	GIVEN = 4,      # Candy cho trước (from givens, immutable)
}

static func is_empty(kind: int) -> bool:
	return kind == CellKind.BLANK

static func is_placed(kind: int) -> bool:
	return kind == CellKind.CANDY or kind == CellKind.GIVEN

static func is_candy(kind: int) -> bool:
	return kind == CellKind.CANDY or kind == CellKind.GIVEN

static func is_cross(kind: int) -> bool:
	return kind == CellKind.MARK or kind == CellKind.ERROR

static func is_locked(kind: int) -> bool:
	return kind == CellKind.GIVEN

static func is_available(kind: int) -> bool:
	return kind == CellKind.BLANK or kind == CellKind.MARK

static func label(kind: int) -> String:
	match kind:
		CellKind.BLANK: return "blank"
		CellKind.MARK: return "mark"
		CellKind.CANDY: return "candy"
		CellKind.ERROR: return "error"
		CellKind.GIVEN: return "given"
	return "unknown"
