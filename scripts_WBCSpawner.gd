extends Node

# Timed spawner for white blood cells (Godot 4)
# Place this node in your main scene (e.g., under a root node or an "Enemies" node).
# Set `wbc_scene` in the inspector to res://scenes/WhiteBloodCell.tscn

@export var wbc_scene: PackedScene
@export var min_interval: float = 15.0
@export var max_interval: float = 20.0
@export var spawn_min_distance: float = 480.0
@export var spawn_max_distance: float = 720.0

var _timer: Timer

func _ready() -> void:
	randomize()
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	_start_timer()

func _start_timer() -> void:
	_timer.wait_time = randf_range(min_interval, max_interval)
	_timer.start()

func _on_timer_timeout() -> void:
	if wbc_scene:
		var wbc = wbc_scene.instantiate()
		var spawn_pos = _choose_spawn_position()
		# Add the new WBC under the spawner's parent (so it's in the same world node)
		if get_parent():
			get_parent().add_child(wbc)
		else:
			get_tree().get_current_scene().add_child(wbc)
		if wbc is Node2D:
			wbc.global_position = spawn_pos
	_start_timer()

func _choose_spawn_position() -> Vector2:
	var players = get_tree().get_nodes_in_group("Player")
	var center = Vector2.ZERO
	if players.size() > 0:
		center = players[0].global_position
	var angle = randf() * TAU
	var dist = randf_range(spawn_min_distance, spawn_max_distance)
	return center + Vector2(cos(angle), sin(angle)) * dist