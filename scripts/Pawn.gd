extends CharacterBody2D

const SPEED = 550.0	
const JUMP_VELOCITY = -500.0
const GRAVITY_MULTIPLIER = 0.9
var virus_color = Color(0, 1, 0, 1)


var possessing = false
var controller: Node = null
var gravity = 600
var health = 100


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

	if not is_on_surface() and is_player_self_controlled:
		velocity.y += gravity * GRAVITY_MULTIPLIER * delta
	elif not is_player_self_controlled():
		velocity.y += abs(gravity) * GRAVITY_MULTIPLIER * delta



	if not controller:
		return
	if controller.has_method("handle_input") and controller.controlled_pawn == self:
			controller.handle_input(delta)
	else:
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
	if not is_player_self_controlled():
		return
	if is_on_surface():
		if controller.controlled_pawn.has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play("Change_Surface")
		if gravity > 0:
			velocity.y = JUMP_VELOCITY
		else:
			velocity.y = -JUMP_VELOCITY
		gravity *= -1
		rotation += PI

func knockback(vector: Vector2) -> void:
	velocity += vector

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

func is_on_surface() -> bool:
	return is_on_floor() or is_on_ceiling()

func shoot_at(cords: Vector2) -> void:
	if not has_node("BulletSpawner"):
		return
	var spawner = get_node("BulletSpawner")
	if not spawner.has_method("shoot"):
		return
	spawner.shoot(cords,self)
	
func take_damage(amount: int) -> void:
	self.get_node("Health").take_damage(amount)


func get_controller() ->Node:
	return controller
