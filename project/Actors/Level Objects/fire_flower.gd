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
	if !is_on_floor(): velocity.y = 1.5625*9*60;
	move_and_slide();
	var player = get_node("/root/Level/Actors/Player");
	if player.State.power == 2:
		%Sprite.play("fire");
	else:
		%Sprite.play("mario");



func _on_area_body_entered(body):
	if body.State.power < 2: body.State.power += 1;
	#Makes the player play the powerup sound.
	body.Sounds.powerup = true;
	queue_free();
	pass # Replace with function body.
