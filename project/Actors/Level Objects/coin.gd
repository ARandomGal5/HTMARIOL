extends StaticBody2D;
@export var palette: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	if palette == 0: %Sprite.play('ground');
	elif palette == 1: %Sprite.play('underground');
	elif palette == 2: %Sprite.play('water');
	elif palette == 3: %Sprite.play('castle');
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass;



func _on_area_body_entered(body):
	body.State.coin += 1;
	#Makes the player play the powerup sound.
	body.Sounds.coin = true;
	queue_free();
	pass # Replace with function body.
