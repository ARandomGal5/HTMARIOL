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
	var player = get_node("/root/Level/Actors/Player");
	#Check if the item is not still coming out of the block.
	if State.deploying == false:
		#Apply gravity.
		if !is_on_floor(): velocity.y = 1.5625*9*60;
		#Move and check for collision.
		move_and_slide();
	#Check if the item is still coming out of the block.
	else:
		#Make the item go up every frame.
		position.y -= 0.25*9;
		#Once the item reaches the top stop going up.
		if Counters.deploy_time == 64:
			State.deploying = false;
		Counters.deploy_time += 1;
	if player.State.power == 2:
		%Sprite.play("fire");
	else:
		%Sprite.play("mario");



func _on_area_body_entered(body):
	if body.State.power < 2: body.State.power += 1;
	#Makes the player play the powerup sound.
	body.Sounds.PowerUp = true;
	queue_free();
	pass # Replace with function body.
