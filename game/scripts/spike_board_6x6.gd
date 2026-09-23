extends Control


const FILLS := [
	Color("#F8DDD2"), Color("#D5EDE6"), Color("#F8E8BC"),
	Color("#E5DDF4"), Color("#D9ECF6"), Color("#F4DDEA"),
]
const INK := Color("#344054")


func _draw() -> void:
	var cell := size.x / 6.0
	for row in range(6):
		for column in range(6):
			var rect := Rect2(Vector2(column, row) * cell, Vector2.ONE * cell)
			draw_rect(rect, FILLS[column], true)
			_draw_pattern(rect, column)
	for line_index in range(7):
		var offset := line_index * cell
		draw_line(Vector2(offset, 0), Vector2(offset, size.y), INK, 2.0)
		draw_line(Vector2(0, offset), Vector2(size.x, offset), INK, 2.0)
		if line_index > 0 and line_index < 6:
			draw_line(Vector2(offset, 0), Vector2(offset, size.y), INK, 6.0)
	draw_rect(Rect2(Vector2.ZERO, size), INK, false, 6.0)


func _draw_pattern(rect: Rect2, region: int) -> void:
	var accent := Color("#47546788")
	var center := rect.get_center()
	match region:
		0:
			draw_circle(center + Vector2(0, -42), 6.0, accent)
		1:
			draw_line(center + Vector2(-20, -44), center + Vector2(20, -44), accent, 4.0)
		2:
			draw_line(center + Vector2(-20, -50), center + Vector2(20, -34), accent, 4.0)
		3:
			draw_rect(Rect2(center + Vector2(-8, -51), Vector2(16, 16)), accent, false, 3.0)
		4:
			draw_arc(center + Vector2(0, -43), 12.0, 0, PI, 12, accent, 4.0)
		5:
			draw_arc(center + Vector2(0, -43), 9.0, 0, TAU, 16, accent, 4.0)
