extends Node

var controlled_pawns: Array[CharacterBody2D] = []

@export var speed: float = 100.0
@export var max_target_distance: float = 1000.0  


func _process(delta: float) -> void:
	handle_ai(delta)


func handle_ai(delta: float) -> void:
	for controlled_pawn in controlled_pawns:
		if not controlled_pawn or not controlled_pawn.is_in_group("Enemy"):
			continue

		var target = find_nearest_target(controlled_pawn)
		var body := controlled_pawn as CharacterBody2D
		if not body:
			continue

		if target and (target.is_in_group("Player") or target.is_in_group("Ally")):
			var dx = target.global_position.x - body.global_position.x
			if abs(dx) <= max_target_distance:
				body.velocity.x = sign(dx) * speed
			else:
				body.velocity.x = 0
		else:
			body.velocity.x = 0

		body.move_and_slide()

		var sprite: Sprite2D = body.get_node_or_null("Sprite2D")
		if sprite:
			sprite.flip_h = body.velocity.x < 0


func add_pawn(pawn: Node) -> void:
	if not controlled_pawns.has(pawn):
		controlled_pawns.append(pawn)


func remove_pawn(pawn: Node) -> void:
	if controlled_pawns.has(pawn):
		controlled_pawns.erase(pawn)


func find_nearest_target(current_pawn: Node) -> Node:
	if not current_pawn:
		return null

	var potential_targets: Array[Node] = []

	for p in get_tree().get_nodes_in_group("Player"):
		if p != current_pawn:
			potential_targets.append(p)
	for a in get_tree().get_nodes_in_group("Ally"):
		if a != current_pawn:
			potential_targets.append(a)

	if potential_targets.is_empty():
		return null

	var closest: Node = null
	var best_dist: float = max_target_distance + 1

	for t in potential_targets:
		var dist = current_pawn.global_position.distance_to(t.global_position)
		if dist < best_dist and dist <= max_target_distance:
			best_dist = dist
			closest = t

	return closest
