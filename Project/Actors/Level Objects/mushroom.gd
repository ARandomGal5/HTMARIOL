extends CharacterBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass;
	
var State = {
	direction = 1,
	deploying = false,
}
var Counters = {
	wall_time = 0,
	deploy_time = 0,
}


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Check if the item is not still coming out of the block.
	if State.deploying == false:
		#The speed of a mushroom is the same as the walk speed of mario.
		velocity.x = (1 + 9*0.0625)*9*60*State.direction;
		#Apply gravity.
		if !is_on_floor(): velocity.y = (1 + 9*0.0625)*9*60;
		#If the mushroom bumps into a wall.
		if is_on_wall():
			#Flip the direction the mushroom is moving and push it slightly so it isn't stuck.
			if Counters.wall_time == 0:
				State.direction *= -1;
				global_position.x -= 16*sign(velocity.x);
			Counters.wall_time += 1;
		else:
			Counters.wall_time = 0;
		#Move and check for collision.
		move_and_slide();
	#Check if the item is still coming out of the block.
	else:
		#Make the item go up every frame.
		position.y -= 0.25*9;
		#Once the item reaches the top stop going up.
		if Counters.deploy_time >= 64:
			reparent($'Actors')
			State.deploying = false;
		Counters.deploy_time += 1;



func _on_area_body_entered(body):
	if body.State.power < 1: body.State.power += 1;
	#Makes the player play the powerup sound.
	body.Sounds.PowerUp = true;
	queue_free();
	pass # Replace with function body.
