extends Node

var controlled_pawn: Node = null  # Only the currently possessed pawn

func handle_input(delta: float) -> void:
	if not controlled_pawn:
		return

	var dir := Input.get_axis("ui_left", "ui_right")
	controlled_pawn.move_horizontal(dir)

	if Input.is_action_just_pressed("ui_accept"):
		controlled_pawn.jump()

	if Input.is_action_just_pressed("possess"):
		var nearest = find_nearby_pawn(controlled_pawn)
		if nearest:
			get_node("/root/World/GameController").possess(nearest)

# Find a nearby pawn using the pawn's InteractionArea
func find_nearby_pawn(current_pawn: Node) -> Node:
	if not current_pawn:
		return null

	# typed array of Nodes
	var list: Array[Node] = current_pawn.get_nearby_pawns()
	if list.size() == 0:
		return null

	# typed variables so the analyzer can infer types
	var closest: Node = list[0]
	var best_dist: float = current_pawn.global_position.distance_to(closest.global_position)

	for p in list:
		var pnode: Node = p
		var d: float = current_pawn.global_position.distance_to(pnode.global_position)
		if d < best_dist:
			best_dist = d
			closest = pnode

	return closest
