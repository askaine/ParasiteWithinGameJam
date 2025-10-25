extends Area2D

@export var health := 5



func area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		_take_damage(1)

func _take_damage(amount: int):
	health -= amount

	if health <= 0:
		_die()

func _die():
	emit_signal("died")
	queue_free()  # remove weak point visually


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		_take_damage(1)
