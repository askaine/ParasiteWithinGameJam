extends Node

var controlled_pawn: Node = null  # Only the currently possessed pawn


func handle_ai(delta: float) -> void:
	if not controlled_pawn:
		return
	controlled_pawn.velocity.x = 0

	


func get_nearby_pawns() -> Array[Node]:
	var area: Area2D = controlled_pawn.get_node("DetectionArea") if controlled_pawn.has_node("DetectionArea") else null
	if not area:
		return []

	var bodies: Array = area.get_overlapping_bodies()
	var pawns: Array[Node] = []
	for b in bodies:
		if b != self and b.is_in_group("Enemy"):
			pawns.append(b as Node)
	return pawns


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
