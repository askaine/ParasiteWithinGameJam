extends Node

var player_controller: Node
var current_pawn: Node
var original_player: Node
var can_possess: bool = true
var possess_cooldown := 0.5
var cooldown_timer: Timer
var possessing_pawn: Node

@onready var camera = $Camera2D
@onready var enemy_controller = $EnemyController
@onready var ally_controller = $AllyController

func _ready() -> void:
	player_controller = $PlayerController
	original_player = get_node("/root/World/Player/Player")
	current_pawn = original_player
	
	camera.reparent(current_pawn)
	camera.global_position = original_player.global_position

	current_pawn.controller = player_controller
	player_controller.controlled_pawn = current_pawn

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		enemy_controller.add_pawn(enemy)

	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = possess_cooldown
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_done)
	add_child(cooldown_timer)


func _on_cooldown_done() -> void:
	can_possess = true



func possess(new_pawn: Node) -> void:
	if not can_possess or not new_pawn:
		return

	can_possess = false
	cooldown_timer.start()

	# Ensure we only allow the original player to eat enemies
	if current_pawn != original_player:
		return

	# Make sure new_pawn is a valid enemy
	if not new_pawn.is_in_group("Enemy"):
		return

	# Stop the enemy AI (if it has one)
	if enemy_controller.has_method("remove_pawn"):
		enemy_controller.remove_pawn(new_pawn)

	# Move player slightly toward the target (simulate jump-engulf)
	var tween = create_tween()
	tween.tween_property(original_player, "global_position", new_pawn.global_position, 0.25)

	# Play the engulf animation (handled in player)
	if original_player.has_method("play_engulf_animation"):
		original_player.play_engulf_animation()

	# Queue up the “eat” after animation finishes
	tween.tween_callback(func ():
		if is_instance_valid(new_pawn):
			new_pawn.queue_free() # Enemy disappears (eaten)
		if original_player.get_controller().has_method("add_boost"):
			original_player.get_controller().add_boost()
	)




	
