extends Node2D

@export var move_time := 0.3
@export var retract_time := 0.3
@export var damage := 10

var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var is_ceiling := false

func setup(start_pos: Vector2, end_pos_global: Vector2, ceiling: bool):
	is_ceiling = ceiling
	start_position = start_pos
	end_position = end_pos_global
	position = start_position

	# Disable collision at start
	var col = get_node_or_null("Area2D/CollisionPolygon2D")
	if col:
		col.disabled = true

func extend():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", end_position, move_time)
	tween.tween_callback(Callable(self, "_enable_collision"))


func fade_out_and_disable():
	# Fade out visually
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.3)

	# Disable collisions after the current physics frame (safe!)
	var area_col = get_node_or_null("Area2D/CollisionPolygon2D")
	if area_col:
		area_col.call_deferred("set", "disabled", true)

	var static_col = get_node_or_null("StaticBody2D/CollisionShape2D")
	if static_col:
		static_col.call_deferred("set", "disabled", true)

	# Optional: disable Area2D monitoring too (also deferred)
	var area = get_node_or_null("Area2D")
	if area:
		area.call_deferred("set_monitoring", false)
		area.call_deferred("set_monitorable", false)



func _enable_collision():
	var col = get_node_or_null("Area2D/CollisionPolygon2D")
	if col:
		col.disabled = false

func _on_body_entered(body: Node) -> void:
	if body.has_node("Health") and (body.is_in_group("Player") or body.is_in_group("Ally")):
		var health = body.get_node("Health")
		health.take_damage(damage)
	elif body.is_in_group("Enemy"):
		pass
	else:
		pass
