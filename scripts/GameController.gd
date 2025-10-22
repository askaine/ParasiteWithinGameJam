extends Node

var player_controller: Node
var current_pawn: Node
var original_player: Node
var can_possess: bool = true
var possess_cooldown := 0.5
var cooldown_timer: Timer
@onready var camera = $Camera2D
@onready var enemy_controller = $EnemyController
@onready var ally_controller = $AllyController


func _ready() -> void:
	player_controller = $PlayerController
	original_player = get_node("/root/World/Player/Player")
	current_pawn = original_player
	camera.reparent(current_pawn)
	current_pawn.controller = player_controller
	player_controller.controlled_pawn = current_pawn

	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = possess_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_done)
	add_child(cooldown_timer)


func _on_cooldown_done() -> void:
	can_possess = true


func possess(new_pawn: Node) -> void:
	if not can_possess or not new_pawn:
		return # don’t possess again while already inside another pawn

	can_possess = false
	cooldown_timer.start()

	# Hide original player
	if current_pawn == original_player:
		original_player.visible = false
		original_player.set_physics_process(false)
		original_player.get_node("CollisionShape2D").disabled = true
		original_player.global_position = new_pawn.global_position + Vector2(0, -50)

	if current_pawn:
		current_pawn.controller = null

	# Assign player controller to new pawn
	new_pawn.controller = player_controller
	current_pawn = new_pawn
	player_controller.controlled_pawn = new_pawn

	camera.reparent(new_pawn)
	camera.global_position = new_pawn.global_position

	for g in current_pawn.get_groups():
		current_pawn.remove_from_group(g)
	current_pawn.add_to_group("Player")



func unpossess() -> void:
	if current_pawn == original_player:
		return  # already in player body

	var possessed_pawn = current_pawn

	# Previous pawn becomes an ally
	for g in possessed_pawn.get_groups():
		possessed_pawn.remove_from_group(g)
	possessed_pawn.add_to_group("Ally")
	possessed_pawn.controller = ally_controller
	ally_controller.controlled_pawn = possessed_pawn

	# Restore player
	current_pawn = original_player
	player_controller.controlled_pawn = original_player
	original_player.controller = player_controller

	# Re-enable physics and collision
	original_player.visible = true
	original_player.set_physics_process(true)
	if original_player.has_node("CollisionShape2D"):
		original_player.get_node("CollisionShape2D").disabled = false

	# --- Determine jump-out direction based on pawn movement ---
	var direction = 1  # default right
	if abs(possessed_pawn.velocity.x) > 0.1:
		direction = -1 if possessed_pawn.velocity.x < 0 else 1
	else:
		# pawn is almost still, jump to side player is currently on
		direction = -1 if original_player.global_position.x < possessed_pawn.global_position.x else 1

	# Get collision widths
	var pawn_shape = possessed_pawn.get_node_or_null("CollisionShape2D")
	var player_shape = original_player.get_node_or_null("CollisionShape2D")
	var pawn_width = 0.0
	var player_width = 0.0

	if pawn_shape and pawn_shape.shape is RectangleShape2D:
		pawn_width = pawn_shape.shape.extents.x * 2
	if player_shape and player_shape.shape is RectangleShape2D:
		player_width = player_shape.shape.extents.x * 2

	# Place player just outside the pawn
	original_player.global_position.x = possessed_pawn.global_position.x + direction * (pawn_width/2 + player_width/2 + 5)
	original_player.global_position.y = possessed_pawn.global_position.y - 50  # slightly above

	# Reparent camera to player
	camera.reparent(original_player)
	camera.global_position = original_player.global_position

	print("Returned to player body; previous pawn is now an ally.")
