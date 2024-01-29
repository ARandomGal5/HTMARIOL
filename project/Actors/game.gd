extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() != 3:
			DisplayServer.window_set_mode(3, 0);
		else:
			DisplayServer.window_set_mode(0, 0)
