extends Node

var player_controller: Node
var current_pawn: Node
var can_possess: bool = true
var possess_cooldown := 0.5  # seconds between possessions
var cooldown_timer: Timer
@onready var camera = $Camera2D


func _ready() -> void:
	player_controller = $PlayerController
	current_pawn = get_node("/root/World/Player/Character")
	camera.reparent(current_pawn)
	if current_pawn:
		current_pawn.controller = player_controller
		player_controller.controlled_pawn = current_pawn  # assign here

	# add cooldown timer
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

	if current_pawn:
		current_pawn.controller = null
	new_pawn.controller = player_controller
	current_pawn = new_pawn
	player_controller.controlled_pawn = new_pawn  # assign here
	camera.reparent(new_pawn)  # camera follows new body
	camera.global_position = current_pawn.global_position

	print("Now controlling:", new_pawn.name)
