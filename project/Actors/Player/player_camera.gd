extends Camera2D

var dir = Vector2(0, 0);
var old_parent = Vector2(0, 0)
# Called when the node enters the scene tree for the first time.
func _ready():
	limit_left = get_parent().position.x - 1920;
	%CameraWall.position = Vector2(0, 0);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var parent = get_parent().position
	offset.y = -parent.y + 1064;
	dir = parent - old_parent;
	if sign(dir).x == 1 && get_parent().global_position.x >= get_screen_center_position().x:
		limit_left = parent.x - 1920;
	#This is fucking stupid but, to make it so the player can't pass the left of a screen, have a static body that is to the left of the screen with the world collision layer.
	%CameraWall.global_position.x = get_screen_center_position().x;
	old_parent = parent;
