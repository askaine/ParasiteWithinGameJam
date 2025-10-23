extends CharacterBody2D

const SPEED = 150.0	
const JUMP_VELOCITY = -500.0
const GRAVITY_MULTIPLIER = 0.9
var virus_color = Color(0, 1, 0, 1)


var possessing = false
var controller: Node = null


func _ready() -> void:
	if self.is_in_group("Player"):
		var gc = get_node("/root/World/GameController")
		controller = gc.player_controller if gc else null
	if self.is_in_group("Enemy"):
		var gc = get_node("/root/World/GameController")
		controller = gc.enemy_controller if gc else null
	if controller:
		controller.controlled_pawn = self


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta

	if not controller:
		return
	if controller.has_method("handle_input") and controller.controlled_pawn == self:
			controller.handle_input(delta)
	else:
		velocity.x = 0

	move_and_slide()



func move_horizontal(dir: float) -> void:
	if dir != 0:
		if is_on_floor() and controller.controlled_pawn.has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play("Walk")
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func jump() -> void:
	if is_on_floor():
		if controller.controlled_pawn.has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play("Jump")
		velocity.y = JUMP_VELOCITY

func get_pawns_in_infection_range() -> Array[Node]:
	var area: Area2D = $InteractionArea if has_node("InteractionArea") else null
	if not area:
		return []

	var bodies: Array = area.get_overlapping_bodies()
	var pawns: Array[Node] = []
	for b in bodies:
		if b != self and b.has_method("move_horizontal"):
			pawns.append(b as Node)
	return pawns

	
func get_player() -> Node:
	var gc = get_node("/root/World/GameController")
	if not gc:
		return null
	return gc.current_pawn
	
func is_player_self_controlled() -> bool:
	return get_node("/root/World/GameController").current_pawn == get_node("/root/World/GameController").original_player
	
func green_tint() -> void:
	var sprite: Sprite2D = $Sprite2D 
	sprite.modulate = Color(0.0, 0.5, 0.0, 1.0)
