extends Node2D

const REQUIRED_HITS_PER_WEAKPOINT := 5
var weakpoints_remaining := 0


func _ready():
	var weakpoints = get_tree().get_nodes_in_group("WeakPoint")
	weakpoints_remaining = weakpoints.size()
	
	for wp in get_tree().get_nodes_in_group("WeakPoint"):
		wp.call_deferred("set_monitoring", false)
			
	for wp in weakpoints:
		# Initialize their health
		wp.set("health", REQUIRED_HITS_PER_WEAKPOINT)
		# Connect their "died" signal
		if not wp.has_signal("died"):
			wp.add_user_signal("died")
		wp.connect("died", Callable(self, "_on_weakpoint_destroyed"))

func _on_weakpoint_destroyed():
	weakpoints_remaining -= 1

	if weakpoints_remaining <= 0:
		_on_brain_cleared()

func _on_brain_cleared():
	get_parent().get_parent().end_mini_game()

func enable_weakpoints():
	for wp in get_tree().get_nodes_in_group("WeakPoint"):
		wp.call_deferred("set_monitoring", true)
