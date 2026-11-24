extends Node2D
## A filled polygon drawn with CanvasItem.draw_colored_polygon, standing in for
## Polygon2D in the authored renderer. In Godot 4.7.2 every Polygon2D redraw with an
## unchanged topology calls mesh_surface_update_index_region, which binds the index
## buffer to GL_ARRAY_BUFFER. WebGL rejects that, so the index update is lost and the
## console fills with INVALID_OPERATION warnings (godotengine/godot#124726, fixed for
## 4.8). draw_colored_polygon triangulates the same way and uses the same per-vertex
## colour, so the result matches; Polygon2D's `antialiased` flag is unused in 4.7.2.

@export var polygon := PackedVector2Array():
	set(value):
		polygon = value
		queue_redraw()

@export var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()

func _draw() -> void:
	if polygon.size() >= 3:
		draw_colored_polygon(polygon, color)

## Replaces a Polygon2D with an equivalent FlatPolygon2D at the same tree position,
## keeping its name (animation track paths), transform, colour, polygon and visibility.
static func replace(source: Polygon2D) -> Node2D:
	var flat: Node2D = load("res://scripts/flat_polygon_2d.gd").new()
	flat.name = source.name
	flat.transform = source.transform
	flat.visible = source.visible
	flat.z_index = source.z_index
	flat.modulate = source.modulate
	flat.self_modulate = source.self_modulate
	flat.color = source.color
	flat.polygon = source.polygon
	source.replace_by(flat)
	source.free()
	return flat
