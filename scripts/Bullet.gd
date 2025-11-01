extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 500.0
@export var damage: int = 10
var shooter: Node = null

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	global_position += direction * speed * delta
	
	if shooter:
		var controller = shooter.get_controller()
		if controller:
			if controller.has_method("handle_input"):
				add_to_group("PlayerAttack")


func _on_body_entered(body: Node) -> void:
	if body == shooter:
		return  
		
	if shooter.is_in_group("Enemy") and body.is_in_group("Enemy"):
		pass
	elif body.has_method("take_damage"):
		var horizontal_dir = sign(direction.x) if direction.x != 0 else 1
		body.take_damage(damage, horizontal_dir)
		queue_free()
	else:
		queue_free()
