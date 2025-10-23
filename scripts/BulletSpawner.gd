extends Node2D

@export var bullet_scene: PackedScene
@export var bullet_speed: float = 300.0
@export var fire_rate: float = 0.3  # bullets per second

var cooldown: float = 0.0

func _ready() -> void:
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if cooldown > 0:
		cooldown -= delta

func shoot(target_pos: Vector2) -> void:
	if cooldown > 0:
		return
	if not bullet_scene:
		return

	var bullet = bullet_scene.instantiate()
	var direction = (target_pos - global_position).normalized()

	bullet.global_position = global_position + direction * 16.0
	bullet.direction = direction
	bullet.speed = bullet_speed

	get_tree().current_scene.add_child(bullet)
	cooldown = 1.0 / fire_rate
