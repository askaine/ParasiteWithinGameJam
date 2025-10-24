extends Node2D

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

	if Input.is_action_just_pressed("ui_accept"):
		if is_player_self_controlled():
			controlled_pawn.change_surface()
		else:
			controlled_pawn.jump()
			
	if Input.is_action_just_pressed("attack"):
		controlled_pawn.shoot_at(get_global_mouse_position())
			
		
	if controlled_pawn.velocity.y>0:
		if controlled_pawn.has_node("AnimatedSprite2D"):
			controlled_pawn.get_node("AnimatedSprite2D").play("Jump")
	if dir != 0:
		facing_left = dir < 0
	
	# Flip sprite based on last direction
	if controlled_pawn.has_node("AnimatedSprite2D"):
		controlled_pawn.get_node("AnimatedSprite2D").flip_h = facing_left
	else:
		controlled_pawn.get_node("Sprite2D").flip_h = facing_left
	

	if Input.is_action_just_pressed("possess"):
		if not possess_pressed:
			var gc = get_node("/root/World/GameController")
			if gc.current_pawn == gc.original_player:
				var nearest = find_nearby_pawn(controlled_pawn)
				if nearest:
					# Play jump animation
					if controlled_pawn.has_node("AnimatedSprite2D"):
						controlled_pawn.get_node("AnimatedSprite2D").play("Jump")

					# Disable collision while in the air
					if controlled_pawn.has_node("CollisionShape2D"):
						controlled_pawn.get_node("CollisionShape2D").disabled = true
						

					# Calculate jump target
					var player_shape = controlled_pawn.get_node_or_null("CollisionShape2D")
					var pawn_shape = nearest.get_node_or_null("CollisionShape2D")
					var offset_x = 0
					if player_shape and pawn_shape:
						var pawn_extent = get_shape_horizontal_extent(pawn_shape.shape)
						var player_extent = get_shape_horizontal_extent(player_shape.shape)
						offset_x = sign(nearest.global_position.x - controlled_pawn.global_position.x) * (pawn_extent + player_extent + 5)

					
					var target_pos = nearest.global_position + Vector2(offset_x, -50)

					# Move player smoothly into pawn over 0.4 seconds
					var jump_duration = 0.4
					var elapsed = 0.0
					var start_pos = controlled_pawn.global_position
					while elapsed < jump_duration:
						var t = elapsed / jump_duration
						controlled_pawn.global_position = start_pos.lerp(target_pos, t)
						await get_tree().process_frame
						elapsed += get_process_delta_time()

					# Ensure final position
					controlled_pawn.global_position = target_pos

					# Re-enable collision now that he is “inside” the pawn
					if controlled_pawn.has_node("CollisionShape2D"):
						controlled_pawn.get_node("CollisionShape2D").disabled = false

					# Possess the pawn
					gc.possess(nearest)
			else:
				# Currently in a possessed pawn → unpossess
				if controlled_pawn.has_node("AnimatedSprite2D"):
					controlled_pawn.get_node("AnimatedSprite2D").play("Jump")
					
				gc.unpossess()
	else:
		possess_pressed = false  # reset when key released
	
# Find a nearby pawn using the pawn's InteractionArea
func find_nearby_pawn(current_pawn: Node) -> Node:
	if not current_pawn:
		return null

	# typed array of Nodes
	var list: Array[Node] = current_pawn.get_pawns_in_infection_range()
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
	
	
func is_player_self_controlled() -> bool:
	return get_node("/root/World/GameController").current_pawn == get_node("/root/World/GameController").original_player


func get_shape_horizontal_extent(shape: Shape2D) -> float:
	if shape is RectangleShape2D:
		return shape.extents.x
	elif shape is CapsuleShape2D:
		return shape.radius  # Capsule width = radius * 2
	elif shape is CircleShape2D:
		return shape.radius
	return 0.0	
	
