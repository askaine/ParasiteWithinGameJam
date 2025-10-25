extends Node2D


@export var melee_range: float = 150.0  # How far the attack reaches
@export var melee_width: float = 100.0  # Height of the attack hitbox
@export var melee_damage: int = 10

var controlled_pawn: Node = null  # Only the currently possessed pawn
var possess_pressed: bool = false  # debounce for possess input
var facing_left: bool = false
var can_attack: bool = true
var attack_cooldown: float = 0.5
var hit_stop: bool = false
var hit_stop_cooldown: float = 0.5
var previous_scene: Node = null
var previous_scene_path: String = "res://world.tscn"
var nearest: Node = null
var gc: Node = null

#--boost--#
var boost_count := 0
const MAX_BOOSTS := 2

@export var MiniGameScene: PackedScene
var previous_player_pos: Vector2
var in_mini_game: bool = false
var mini_game_instance: Node2D = null
@onready var mini_game_far_pos = get_node("/root/World/Node2D").global_position


func handle_input(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	queue_redraw()
	if not controlled_pawn or not can_act():
		return
	var dir := Input.get_axis("ui_left", "ui_right")
	controlled_pawn.move_horizontal(dir)

	if Input.is_action_just_pressed("ui_accept"):
		if is_player_self_controlled():
			controlled_pawn.change_surface()
		else:
			controlled_pawn.jump()
			
	if Input.is_action_just_pressed("attack"):
		shoot()
		
	if Input.is_action_just_pressed("f_key"):
		attack()
			
		
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
			gc = get_node("/root/World/GameController")
			if gc.current_pawn == gc.original_player:
				_try_possess_nearest()
				
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


func _try_possess_nearest():
	var gc = get_node("/root/World/GameController")
	if gc.current_pawn != gc.original_player:
		return

	nearest = find_nearby_pawn(controlled_pawn)
	if not nearest or not nearest.get_node("Health").infectable():
		return

	# Deal 10 damage for attempting possession
	var health = controlled_pawn.get_node_or_null("Health")
	if health:
		health.take_damage(10)

	# Save player position to return later
	previous_player_pos = controlled_pawn.global_position

	# Instantiate mini-game scene
	if MiniGameScene:
		mini_game_instance = MiniGameScene.instantiate()
		var container = Node2D.new()
		container.position = mini_game_far_pos
		get_tree().current_scene.add_child(container)
		container.add_child(mini_game_instance)
		get_tree().current_scene.add_child(mini_game_instance)
		
		# Run even while paused
		mini_game_instance.process_mode = Node.PROCESS_MODE_ALWAYS
		mini_game_instance.set_process_input(true)
		mini_game_instance.set_physics_process(true)
		
		# Connect mini-game finished signal to PlayerController function
		if mini_game_instance.has_signal("_mini_game_finished"):
			mini_game_instance.connect("_mini_game_finished", Callable(self, "_mini_game_finished"))

		# Teleport player to the mini-game location
		controlled_pawn.global_position = mini_game_far_pos
		get_node("/root/World/GameController").camera.zoom = Vector2(0.2, 0.2)




func get_shape_horizontal_extent(shape: Shape2D) -> float:
	if shape is RectangleShape2D:
		return shape.extents.x
	elif shape is CapsuleShape2D:
		return shape.radius  # Capsule width = radius * 2
	elif shape is CircleShape2D:
		return shape.radius
	return 0.0	

func scan_melee_area() -> Array[Node]:
	# Uses the script-level facing_left boolean to decide side.
	if not controlled_pawn:
		return []

	# Facing direction from your boolean
	var facing_direction: int = -1 if facing_left else 1

	# World origin of pawn
	var origin: Vector2 = controlled_pawn.global_position

	# Compute hitbox center in world space (offset in front of pawn)
	var offset_x: float = facing_direction * (melee_range / 2 + 10)
	var attack_position: Vector2 = origin + Vector2(offset_x, 0)

	# Rectangle shape centered on attack_position
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.extents = Vector2(melee_range / 2, melee_width / 2)

	# Transform with global origin (no rotation)
	var transform: Transform2D = Transform2D()
	transform.origin = attack_position

	# Query parameters
	var params: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = transform
	# Exclude the controlled pawn's physics body if possible; node is okay in many cases
	params.exclude = [controlled_pawn]
	params.collide_with_areas = true
	params.collide_with_bodies = true

	# Run query
	var space_state = get_world_2d().direct_space_state
	var results: Array = space_state.intersect_shape(params)

	var hit_targets: Array[Node] = []
	for result in results:
		var target: Node = result.collider
		if not target:
			continue
		if target.is_in_group("Enemy") or target.is_in_group("WeakPoint"):
			hit_targets.append(target)


	return hit_targets


func can_act() -> bool:
	return not hit_stop

func shoot() -> void:
	controlled_pawn.shoot_at(get_global_mouse_position())
	
func attack() -> void:
	if not can_attack:
		return
	
	# Start cooldown
	can_attack = false
	hit_stop = true
	get_tree().create_timer(attack_cooldown).timeout.connect(func(): can_attack = true)
	get_tree().create_timer(hit_stop_cooldown).timeout.connect(func(): hit_stop = false)
	
	# Play attack animation
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("Attack")
	
	# Determine attack direction
	var sprite = get_node_or_null("AnimatedSprite2D") if has_node("AnimatedSprite2D") else get_node_or_null("Sprite2D")
	var facing_direction = -1 if (sprite and sprite.flip_h) else 1
	
	# Scan for targets
	var hit_targets = scan_melee_area()
	
	# Apply damage to hit targets
	for target in hit_targets:
		if target.has_method("take_damage"):
			target.take_damage(melee_damage)
			target.knockback(Vector2(facing_direction * -20000000, 100)) #not finished (TO DO)
		elif target.has_method("_take_damage"):
			target._take_damage(1)


func _mini_game_finished():

	# Teleport player back to previous position
	controlled_pawn.global_position = previous_player_pos

	# Remove mini-game instance
	if mini_game_instance:
		mini_game_instance.queue_free()
		mini_game_instance = null

	# Unpause main scene
	get_tree().paused = false
	in_mini_game = false
	get_node("/root/World/GameController").camera.zoom = Vector2(1, 1)
	gc.possess(nearest)
	
	
func add_boost():
	if boost_count >= MAX_BOOSTS:
		return
	boost_count += 1

	# Heal + Damage Boost
	print(controlled_pawn)
	if controlled_pawn.has_node("Health"):
		var health = controlled_pawn.get_node("Health")
		health.current_hp = min(health.current_hp + 10, health.max_hp + 10)
		health.max_hp += 10
		health.attack_damage += 10

	# Scale up visually
	scale *= 1.5

	print("Boost gained! Total boosts:", boost_count)
