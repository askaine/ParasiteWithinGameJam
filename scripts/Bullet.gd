extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 500.0
@export var damage: int = 10

func _physics_process(delta: float) -> void:
	if direction == Vector2.ZERO:
		return
	global_position += direction * speed * delta

	
	

func _on_body_entered(body: Node) -> void:
	if body.has_node("Health"):
		var health = body.get_node("Health")
		health.take_damage(damage)
		queue_free()
	elif body.is_in_group("Enemy"): 
		pass
	else:
		queue_free()
