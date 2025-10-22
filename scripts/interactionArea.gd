extends Area2D
class_name InteractionArea

@export var action_name: String = "interact"


var interact: Callable = func():
	pass
	
func _ready() -> void:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: CollisionObject2D) -> void:
	InteractionManager.register_area(self)
		

func _on_body_exited(body: CollisionObject2D) -> void:
	InteractionManager.unregister_area(self)
