extends CharacterBody2D

const SPEED = 550.0	
const JUMP_VELOCITY = -500.0
const GRAVITY_MULTIPLIER = 0.9
var virus_color = Color(0, 1, 0, 1)


var knockback_velocity: float = 0.0
var knockback_timer: float = 0.0
var vertical_knockback: float = 0.0
const KNOCKBACK_DURATION: float = 0.2
const KNOCKBACK_Y_FORCE: float = 200.0


var possessing = false
var controller: Node = null
var gravity = 600
var health = 100

var can_take_damage: bool = true
var damage_cooldown: float = 0.1


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

	# Apply gravity
	if not is_on_surface() and is_player_self_controlled:
		velocity.y += gravity * GRAVITY_MULTIPLIER * delta
	elif not is_player_self_controlled():
		velocity.y += abs(gravity) * GRAVITY_MULTIPLIER * delta

	# Normal input / movement
	if not controller:
		return
	if controller.has_method("handle_input") and controller.controlled_pawn == self and knockback_timer <= 0.0:
		controller.handle_input(delta)
	elif knockback_timer <= 0.0:
		velocity.x = 0

	# Apply knockback if active
	if knockback_timer > 0.0:
		velocity.x = knockback_velocity
		velocity.y = vertical_knockback
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			vertical_knockback = 0.0  # Reset vertical knockback when done

	move_and_slide()


func move_horizontal(dir: float) -> void:
	if dir != 0:
		if is_on_surface() and self.has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play("Walk")
		velocity.x = dir * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func jump() -> void:
	if is_on_surface():
		if self.has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.play("Jump")
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

func knockback(horizontal_force: float) -> void:
	knockback_velocity = horizontal_force
	knockback_timer = KNOCKBACK_DURATION

	# Apply vertical knockback depending on surface
	if is_on_floor():
		vertical_knockback = -KNOCKBACK_Y_FORCE  # Knock up
	elif is_on_ceiling():
		vertical_knockback = KNOCKBACK_Y_FORCE   # Knock down
	else:
		vertical_knockback = -KNOCKBACK_Y_FORCE  # Default to upward


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
	
func take_damage(amount: int,dir: int) -> void:
	if not can_take_damage:
		return

	can_take_damage = false

	knockback(dir * 1000)
	if has_node("Health"):
		$Health.take_damage(amount)

	# Start cooldown timer
	var timer := get_tree().create_timer(damage_cooldown)
	await timer.timeout
	can_take_damage = true


func get_controller() ->Node:
	return controller
