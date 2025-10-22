extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -500.0
const GRAVITY_MULTIPLIER = 0.9

var controller: Node = null

func _ready() -> void:
	if name == "Player":
		var gc = get_node("/root/World/GameController")
		controller = gc.player_controller if gc else null

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta

	# Only send input if this pawn is the currently controlled pawn
	if controller and controller.controlled_pawn == self:
		controller.handle_input(delta)
	else:
		# Stop input entirely, also zero horizontal velocity if desired
		velocity.x = 0

	move_and_slide()

func move_horizontal(dir: float) -> void:
	if dir != 0:
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func get_nearby_pawns() -> Array[Node]:
	var area: Area2D = $InteractionArea if has_node("InteractionArea") else null
	if not area:
		return []

	var bodies: Array = area.get_overlapping_bodies()
	var pawns: Array[Node] = []
	for b in bodies:
		if b != self and b.has_method("move_horizontal"):
			pawns.append(b as Node)
	return pawns
