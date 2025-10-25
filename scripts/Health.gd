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
	
