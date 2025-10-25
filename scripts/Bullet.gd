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
	if body.has_node("Health") and body != shooter:
		var health = body.get_node("Health")
		health.take_damage(damage)
		queue_free()
	elif shooter.is_in_group("Enemy") and body.is_in_group("Enemy"): 
		pass
	elif body != shooter:
		queue_free()
