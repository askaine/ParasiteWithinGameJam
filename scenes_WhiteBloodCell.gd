extends CharacterBody2D

# White blood cell enemy (Godot 4)
# - Homing behavior: chases the node in group "Player"
# - On contact (close distance) tries multiple methods to damage the player:
#   - calls player's take_damage / apply_damage if present
#   - otherwise tries the "Health" child node and calls its methods (take_damage, modify_health, apply_damage)
# Tweak speed and damage in the inspector.

@export var speed: float = 160.0
@export var damage: int = 1

var _player: Node = null

func _ready() -> void:
	randomize()
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		_player = players[0]

func _physics_process(delta: float) -> void:
	if _player and _player.is_inside_tree():
		var dir = _player.global_position - global_position
		if dir.length() > 0.1:
			velocity = dir.normalized() * speed
			move_and_slide()
			# simple contact detection: close radius
			if global_position.distance_to(_player.global_position) < 20.0:
				_apply_damage_to(_player)
				queue_free()
	else:
		# No player found: stop moving
		velocity = Vector2.ZERO
		move_and_slide()

func _apply_damage_to(target: Node) -> void:
	# Preferred: player implements take_damage or apply_damage
	if target.has_method("take_damage"):
		target.call("take_damage", damage)
		return
	if target.has_method("apply_damage"):
		target.call("apply_damage", damage)
		return
	# Fallback: try the child's Health node (many projects put a Health node on the Player)
	if target.has_node("Health"):
		var h = target.get_node("Health")
		if h:
			if h.has_method("take_damage"):
				h.call("take_damage", damage)
				return
			if h.has_method("modify_health"):
				h.call("modify_health", -damage)
				return
			if h.has_method("apply_damage"):
				h.call("apply_damage", damage)
				return
	# If none of the above, try to emit a signal or print a message for debugging
	print("WBC: couldn't find damage method on target: ", target)