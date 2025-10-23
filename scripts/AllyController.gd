extends Node

@export var speed: float = 120.0
@export var follow_distance: float = 400.0
@export var enemy_detection_range: float = 1000.0

var controlled_pawn: CharacterBody2D = null
var current_target: Node = null
var player_ref: Node = null


func _ready() -> void:
	player_ref = get_tree().get_nodes_in_group("Player").front() if get_tree().has_group("Player") else null


func _process(delta: float) -> void:
	if not controlled_pawn:
		return
	handle_ai(delta)


func handle_ai(delta: float) -> void:
	if not player_ref or not controlled_pawn:
		return

	var enemy = find_nearest_enemy(controlled_pawn)
	if enemy:
		current_target = enemy
	else:
		current_target = player_ref

	var body := controlled_pawn as CharacterBody2D
	if not body:
		return

	if current_target == player_ref:
		var dx = player_ref.global_position.x - body.global_position.x
		if abs(dx) > follow_distance:
			body.velocity.x = sign(dx) * speed
		else:
			body.velocity.x = 0
	else:
		var dx = current_target.global_position.x - body.global_position.x
		body.velocity.x = sign(dx) * speed

	body.move_and_slide()

	var sprite: Sprite2D = body.get_node_or_null("Sprite2D")
	if sprite:
		sprite.flip_h = body.velocity.x < 0


func add_pawn(new_pawn: CharacterBody2D) -> void:
	if controlled_pawn and is_instance_valid(controlled_pawn):
		print("Old ally removed:", controlled_pawn.name)
		controlled_pawn.queue_free()

	controlled_pawn = new_pawn


func remove_pawn(pawn: Node) -> void:
	if controlled_pawn == pawn:
		controlled_pawn = null


func find_nearest_enemy(current_pawn: Node) -> Node:
	if not current_pawn:
		return null

	var enemies = get_tree().get_nodes_in_group("Enemy")
	if enemies.is_empty():
		return null

	var closest_enemy: Node = null
	var best_dist := enemy_detection_range

	for e in enemies:
		var dist = current_pawn.global_position.distance_to(e.global_position)
		if dist < best_dist:
			best_dist = dist
			closest_enemy = e

	return closest_enemy
