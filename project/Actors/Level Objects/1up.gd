extends CharacterBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass;
	
var State = {
	direction = 1,
}
var Counters = {
	wall_time = 0,
}


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#The speed of a mushroom is the same as the walk speed of mario.
	velocity.x = (1 + 9*0.0625)*9*60*State.direction;
	if !is_on_floor(): velocity.y = (1 + 9*0.0625)*9*60;
	move_and_slide();
	if is_on_wall():
		if Counters.wall_time == 0:
			State.direction *= -1;
			global_position.x -= 16*sign(velocity.x);
		Counters.wall_time += 1;
	else:
		Counters.wall_time = 0;



func _on_area_body_entered(body):
	#Makes the player play the 1up sound.
	body.Sounds.oneup = true;
	queue_free();
	pass # Replace with function body.
