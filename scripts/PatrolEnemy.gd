# first_enemy.gd
extends Pawn
class_name PatrolEnemy

var patrol_direction: int = 1
@export var patrol_speed: float = 100.0
@export var attack_range: float = 200.0

#func _physics_process(delta: float) -> void:
	#if controller == null or controller.controlled_pawn != self:
		#_ai_behavior(delta)
	#else:
		#controller.handle_input(delta)
#
	#move_and_slide()

#func _ai_behavior(delta: float) -> void:
	## simple patrol
	#move_horizontal(patrol_direction * patrol_speed)
	#if is_on_wall():
		#patrol_direction *= -1
#
	## Example: attack logic
	#var target = _find_nearest_target()
	#if target and global_position.distance_to(target.global_position) < attack_range:
		#_use_skill(0) # first skill
