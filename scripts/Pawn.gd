extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -500.0
const GRAVITY_MULTIPLIER = 0.9

var controller: Node = null
var gravity = 600



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

	
	
	if not is_on_surface():
		velocity.y += gravity * GRAVITY_MULTIPLIER * delta


	# Only send input if this pawn is the currently controlled pawn
	if not controller:
		return
	# Only handle input or AI if this pawn is the currently controlled one
	if controller.has_method("handle_input") and controller.controlled_pawn == self:
			controller.handle_input(delta)
	elif controller.has_method("handle_ai"):
		controller.handle_ai(delta)
	else:
		# Not controlled → stop horizontal movement
		velocity.x = 0
	
	

	move_and_slide()



func move_horizontal(dir: float) -> void:
	if dir != 0:
		if is_on_surface() and controller.controlled_pawn.has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play("Walk")
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)


func jump() -> void:
	if is_on_surface():
		if controller.controlled_pawn.has_node("AnimatedSprite2D"):
			$Animatedis_on_floorSprite2D.play("Jump")
		velocity.y = JUMP_VELOCITY
		
func change_surface() -> void:
	if is_on_surface():
		if controller.controlled_pawn.has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play("Change_Surface")
		if gravity > 0:
			velocity.y = JUMP_VELOCITY
		else:
			velocity.y = -JUMP_VELOCITY
		gravity *= -1
		rotation += PI

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
	var area: Area2D = $DetectionArea if has_node("DetectionArea") else null
	if not area:
		return null
	var bodies: Array = area.get_overlapping_bodies()
	var pawn: Node = null
	for b in bodies:
		if b != self and b.is_in_group("Player"):
			pawn = b as Node
	return pawn
	
func is_on_surface() -> bool:
	return is_on_floor() or is_on_ceiling()
