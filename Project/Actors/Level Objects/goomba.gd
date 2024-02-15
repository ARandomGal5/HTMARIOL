extends CharacterBody2D

@export var palette = 0;
var State = {
	direction = 1,
	dead = false,
}
var Counters = {
	wall_time = 0,
	dead_time = 0,
}

@onready var Sprite = {
	anim = 'overworld',
	sprite = %Sprite_Walk,
}

func _ready():
	pass;
	
func _physics_process(delta):
	#The speed of a mushroom is the same as the walk speed of mario.
	if !State.dead:
		velocity.x = (1)*9*60*State.direction;
		if !is_on_floor(): velocity.y = (1 + 9*0.0625)*9*60;
		move_and_slide();
		if is_on_wall():
			if Counters.wall_time == 0:
				State.direction *= -1;
				global_position.x -= 16*sign(velocity.x);
			Counters.wall_time += 1;
		else:
			Counters.wall_time = 0;
		
	if palette == 0:
		Sprite.anim = 'overworld'
	elif palette == 1:
		Sprite.anim = 'underground'
	elif palette == 2:
		Sprite.anim = 'underwater'
	elif palette == 3:
		Sprite.anim = 'castle'
	
	if State.dead == false:
		Sprite.sprite = %Sprite_Walk;
		%Sprite_Walk.visible = true;
		%Sprite_Die.visible = false;
	else:
		Sprite.sprite = %Sprite_Die;
		%Sprite_Walk.visible = false;
		%Sprite_Die.visible = true;
		if Counters.dead_time == 30: queue_free();
		Counters.dead_time += 1;
	
	if Sprite.sprite: 
		Sprite.sprite.play(Sprite.anim);

func _on_hitbox_body_entered(body):
	if body.State.power > 0:
		body.State.power = 0;
		body.Sounds.Warp = true;

func _on_hurtbox_body_entered(body):
	State.dead = true;
	body.Sounds.Squish = true;
	print('a')
