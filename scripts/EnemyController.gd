extends Node

var controlled_pawns: Array[CharacterBody2D] = []

@export var speed: float = 100.0
@export var max_target_distance: float = 5000.0  
var enemy_ai_map = {
	"FirstEnemy": "FirstEnemyAi",
	"ShooterEnemy": "ShooterEnemyAi",
}

func _process(delta: float) -> void:
	for enemy in controlled_pawns:
		if not enemy:
			continue
		var type_name = enemy.name  
		if enemy_ai_map.has(type_name):
			var func_name = enemy_ai_map[type_name]
			if has_method(func_name):
				call(func_name, enemy, delta)
	

func FirstEnemyAi(enemy: Node,delta: float) -> void:
		if not enemy or not enemy.is_in_group("Enemy"):
			return

		var target = find_nearest_target(enemy)
		var body := enemy as CharacterBody2D
		if not body:
			return
		if not enemy.is_player_self_controlled():
			target = get_node("/root/World/GameController").possessing_pawn
		if target and (target.is_in_group("Player") or target.is_in_group("Ally")):
			var dx = target.get_node("CollisionShape2D").global_position.x - body.get_node("CollisionShape2D").global_position.x
			if abs(dx) <= max_target_distance:
				body.velocity.x = sign(dx) * speed
			else:
				body.velocity.x = 0
		else:
			body.velocity.x = 0

		body.move_and_slide()

		var sprite: Sprite2D = body.get_node_or_null("Sprite2D")
		if sprite:
			sprite.flip_h = body.velocity.x < 0

func ShooterEnemyAi(enemy: Node, delta: float) -> void:
	var target = get_current_target()
	if not target:
		stop_movement(enemy)
		return

	if not is_target_in_range(enemy, target, 500): # 500 pixels shooting range
		move_towards(enemy, target, 100) # move closer
		return

	# Check line of sight
	if has_line_of_sight(enemy, target):
		stop_movement(enemy)
		shoot_at(enemy, target)
	else:
		move_towards(enemy, target, 50) # move closer slowly if blocked



func get_current_target() -> Node:
	var gc = get_node("/root/World/GameController")
	if gc.possessing_pawn:
		return gc.possessing_pawn
	elif gc.current_pawn:
		return gc.current_pawn
	return null

func move_towards(enemy: Node, target: Node, speed: float) -> void:
	var dx = target.global_position.x - enemy.global_position.x
	enemy.velocity.x = sign(dx) * speed
	enemy.move_and_slide()
	if enemy.has_node("Sprite2D"):
		enemy.get_node("Sprite2D").flip_h = enemy.velocity.x < 0

func stop_movement(enemy: Node) -> void:
	enemy.velocity.x = 0
	enemy.move_and_slide()

func is_target_in_range(enemy: Node, target: Node, max_distance: float) -> bool:
	return enemy.global_position.distance_to(target.global_position) <= max_distance

func has_line_of_sight(enemy: Node2D, target: Node2D) -> bool:
	var space_state = enemy.get_world_2d().direct_space_state

	var params := PhysicsRayQueryParameters2D.new()
	params.from = enemy.global_position
	params.to = target.global_position
	params.exclude = [enemy]  


	var result = space_state.intersect_ray(params)
	if result.is_empty():
		return true
	return result.get("collider") == target



func shoot_at(enemy: Node, target: Node) -> void:
	if not enemy.has_node("BulletSpawner"):
		return
	var spawner = enemy.get_node("BulletSpawner")
	if not spawner.has_method("shoot"):
		return
	spawner.shoot(target.global_position)


func add_pawn(pawn: Node) -> void:
	if not controlled_pawns.has(pawn):
		controlled_pawns.append(pawn)


func remove_pawn(pawn: Node) -> void:
	if controlled_pawns.has(pawn):
		controlled_pawns.erase(pawn)


func find_nearest_target(current_pawn: Node) -> Node:
	if not current_pawn:
		return null

	var potential_targets: Array[Node] = []

	for p in get_tree().get_nodes_in_group("Player"):
		if p != current_pawn:
			potential_targets.append(p)
	for a in get_tree().get_nodes_in_group("Ally"):
		if a != current_pawn:
			potential_targets.append(a)

	if potential_targets.is_empty():
		return null

	var closest: Node = null
	var best_dist: float = max_target_distance + 1

	for t in potential_targets:
		var dist = current_pawn.global_position.distance_to(t.global_position)
		if dist < best_dist and dist <= max_target_distance:
			best_dist = dist
			closest = t

	return closest
