extends CharacterBody2D

var State = {
	direction = 1,
}
var Counters = {
	wall_time = 0,
}

func _ready():
	%Sprite.play('walk');
func _physics_process(delta):
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
