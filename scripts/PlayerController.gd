extends Node

var controlled_pawn: Node = null  # Only the currently possessed pawn
var possess_pressed: bool = false  # debounce for possess input
var facing_left: bool = false


func handle_input(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if not controlled_pawn:
		return

	var dir := Input.get_axis("ui_left", "ui_right")
	controlled_pawn.move_horizontal(dir)

	if Input.is_action_pressed("ui_accept"):
		controlled_pawn.jump()
		
	if dir != 0:
		facing_left = dir < 0
	
	# Flip sprite based on last direction
	controlled_pawn.get_node("Sprite2D").flip_h = facing_left
	

	if Input.is_action_just_pressed("possess"):
		if not possess_pressed:
			var gc = get_node("/root/World/GameController")
			if gc.current_pawn == gc.original_player:
				# Only possess if in original player body
				var nearest = find_nearby_pawn(controlled_pawn)
				if nearest:
					gc.possess(nearest)
			else:
				# Currently in a possessed pawn → unpossess
				gc.unpossess()
	else:
		possess_pressed = false  # reset when key released
	

				



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
		if p == controlled_pawn:
			continue
		var pnode: Node = p
		var d: float = current_pawn.global_position.distance_to(pnode.global_position)
		if d < best_dist:
			best_dist = d
			closest = pnode

	return closest
