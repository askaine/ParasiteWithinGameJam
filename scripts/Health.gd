extends Node

@export var max_hp: int = 50
@export var attack_damage: int = 10

var current_hp: int
var can_infect = false

signal died

func _ready() -> void:
	current_hp = max_hp

# Take damage
func take_damage(amount: int) -> void:
	current_hp -= amount
	print(get_parent().name, "Health - ", current_hp)
	hit_flash(get_parent().get_node("AnimatedSprite2D"))
	if current_hp <= 0:
		current_hp = 0
		die()
	elif current_hp == 10:
		can_infect = true
		infectable()

# Heal
func heal(amount: int) -> void:
	current_hp += amount
		
	if current_hp > max_hp:
		current_hp = max_hp
		
		


func infectable() -> bool:
	return can_infect
	


# Called on death
func die() -> void:
	print("%s died" % get_parent().name)
	emit_signal("died")
	# Remove parent node from scene tree
	


func hit_flash(sprite: AnimatedSprite2D, duration: float = 0.2, flash_color: Color = Color(1, 1, 1)) -> void:
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
