extends Node2D

# --- CONFIG ---
var neurons_activated := 0
const TOTAL_NEURONS := 2
@export var SpikeScene: PackedScene
@export var spikes_per_area := 3

var spikes_started := false
signal _mini_game_finished

# --- READY ---
func _ready():
	await get_tree().process_frame
	var bounds = Rect2()
	for child in get_children():
		if child is Node2D:
			bounds = bounds.expand(child.position)

	# Move content so it's centered on origin
	for child in get_children():
		if child is Node2D:
			child.position -= bounds.position + bounds.size / 2
	# Connect neuron signals and initialize
	for neuron in $Neurons.get_children():
		neuron.set("activated", false)
		if neuron.has_node("Area2D"):
			neuron.get_node("Area2D").body_entered.connect(Callable(self, "_on_neuron_entered").bind(neuron))
		else:
			push_warning("Neuron " + str(neuron) + " missing Area2D!")

	# Disable platform collisions at start
	for platform in $Platforms.get_children():
		if platform.has_node("CollisionPolygon2D"):
			platform.get_node("CollisionPolygon2D").disabled = true

# --- NEURON ACTIVATION ---
func _on_neuron_entered(body: Node, neuron: Node):
	if body.name != "Player":
		return

	if neuron.get("activated"):
		return # already counted

	# Mark neuron as activated
	neuron.set("activated", true)
	neurons_activated += 1
	print("Neuron activated! Total:", neurons_activated)

	# Disable neuron collision (CircleShape2D) but keep sprite visible
	if neuron.has_node("Area2D/CollisionShape2D"):
		var col = neuron.get_node("Area2D/CollisionShape2D")
		col.call_deferred("set", "disabled", true)

	# Start spikes after first neuron
	if not spikes_started:
		spikes_started = true
		_start_spikes()

	# Spawn platforms and disable spikes after both neurons are activated
	if neurons_activated >= TOTAL_NEURONS:
		var brain = get_node("Brain/Brain")
		if brain:
			brain.enable_weakpoints()
		_spawn_platforms()
		_disable_spikes()
		

# --- PLATFORM SPAWN ---
func _spawn_platforms():
	for platform in $Platforms.get_children():
		platform.visible = true
		platform.modulate.a = 0  # start transparent

		var tween = create_tween()
		# Blink twice
		tween.tween_property(platform, "modulate:a", 1, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(platform, "modulate:a", 0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(platform, "modulate:a", 1, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(platform, "modulate:a", 0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# Final fade-in
		tween.tween_property(platform, "modulate:a", 1, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		# Enable collision after fade-in
		tween.finished.connect(Callable(self, "_enable_platform_collision").bind(platform))

func _enable_platform_collision(platform: Node):
	if platform.has_node("CollisionPolygon2D"):
		platform.get_node("CollisionPolygon2D").disabled = false

# --- SPIKES ---
func _start_spikes():
	_spawn_spikes_from_area($SpikeSpawns/FloorSpawn, false)
	_spawn_spikes_from_area($SpikeSpawns/CeilingSpawn, true)

func _spawn_spikes_from_area(area: Area2D, ceiling=false):
	var poly_node = area.get_node_or_null("CollisionPolygon2D")
	if poly_node == null:
		push_error("Spawn area " + str(area) + " has no CollisionPolygon2D!")
		return

	var poly = poly_node.polygon
	if poly.size() == 0:
		push_error("CollisionPolygon2D in " + str(area) + " has empty polygon!")
		return

	var min_x = poly[0].x
	var max_x = poly[0].x
	var min_y = poly[0].y
	var max_y = poly[0].y
	for point in poly:
		min_x = min(min_x, point.x)
		max_x = max(max_x, point.x)
		min_y = min(min_y, point.y)
		max_y = max(max_y, point.y)

	var local_pos = poly_node.position
	var rect_pos = local_pos + Vector2(min_x, min_y)
	var rect_size = Vector2(max_x - min_x, max_y - min_y)

	for i in range(spikes_per_area):
		var spike_instance = SpikeScene.instantiate()
		var x_pos = rect_pos.x + rect_size.x * (i + 0.5) / spikes_per_area
		var start_y = rect_pos.y + rect_size.y if ceiling else rect_pos.y
		var end_y = rect_pos.y if ceiling else rect_pos.y + rect_size.y

		spike_instance.position = Vector2(x_pos, start_y)
		spike_instance.setup(spike_instance.position, Vector2(x_pos, end_y), ceiling)

		# Add spike to the tree first
		call_deferred("_add_and_extend_spike", spike_instance)

# Helper function deferred to ensure tree is ready
func _add_and_extend_spike(spike_instance: Node2D):
	add_child(spike_instance)
	spike_instance.extend()


func _disable_spikes():
	for spike in get_children():
		if spike.is_class("Node2D") and spike.has_method("fade_out_and_disable"):
			spike.fade_out_and_disable()


func end_mini_game():
	emit_signal("_mini_game_finished")			
