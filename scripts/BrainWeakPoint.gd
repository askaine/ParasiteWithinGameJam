extends Area2D

@export var health := 5



func area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		_take_damage(1)

func _take_damage(amount: int):
	health -= amount
	hit_flash(get_parent().get_node("Sprite2D"))
	if health <= 0:
		
		_die()

func _die():
	emit_signal("died")
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("PlayerAttack"):
		_take_damage(1)
		
func hit_flash(sprite: Sprite2D, duration: float = 0.2, flash_color: Color = Color(1, 1, 1)) -> void:
	# Make sure the sprite has a unique ShaderMaterial
	var shader : Shader = preload("res://Shaders/hit_flash_shader.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = shader
	sprite.material = mat

	mat.set_shader_parameter("flash_color", flash_color)
	mat.set_shader_parameter("flash_strength", 0.0)

	var tween := create_tween()
	var half_dur := duration / 2.0

	# Fade in
	tween.tween_property(mat, "shader_parameter/flash_strength", 2.0, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(mat, "shader_parameter/flash_strength", 0.0, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished

	# Optionally remove shader after done
	sprite.material = null
