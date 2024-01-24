extends CharacterBody2D

#I apologize for poor commenting, I am using documentation of the original game's physics and a lot of the decisions are genuinely baffling and I have no idea how to even begin to explain them.

#Distance values.
const BLOCK = 16;
const PIXEL = 1;
const SPIXEL = 0.0625;
const SSPIXEL = 0.00390625;
const SSSPIXEL = 0.000244140625;
#Everything is multiplied by 9 for the sprite upscaling, then another 60 so that it is per frame instead of per second.
#All of the physics constants are written like this despite being horribly unoptimized because.
#1. way easiter to read and keep track of than random decimals like 0.037109375
#2. easier to 'port' the values from the documentation
#3. easier for potential modders to understand these values.
#Walk speeds.
const WALK_SPEED = (PIXEL + 9*SPIXEL)*9*60;
const WALK_ACCEL = (9*SSPIXEL + 8*SSSPIXEL)*9*60;
const MIN_WALK_SPEED = (SPIXEL + 3*SSPIXEL)*9*60;

const LEVEL_ENTRY = (13*SPIXEL)*9*60;

#Run speeds.
const RUN_SPEED = (2*PIXEL + 9*SPIXEL)*9*60;
const RUN_ACCEL = (14*SSPIXEL + 4*SSSPIXEL)*9*60;

#Skid speed.
const SKID_ACCEL = (SPIXEL + 10*SSPIXEL)*9*60;

#Stopping speed.
const STOP_ACCEL = (13*SSPIXEL)*9*60;

#Jump speeds.
#For some reason in the original if you jump with a certain amount of speed or higher, you will turn around faster...?
const JUMP_TURN = (PIXEL + 13*SPIXEL)*9*60;
#Another for some reason, if you jump while moving faster than this you jump higher?
const JUMP_SLOW = PIXEL*9*60;
const JUMP_FAST = (2*PIXEL + 5*SPIXEL)*9*60;

#Falling speeds.
const DEFAULT_GRAV = (2*SPIXEL + 8*SSPIXEL)*9*60;
const FALL_FAST = (2*SPIXEL)*9*60;
const FALL_SLOW = (1*SPIXEL + 14*SSPIXEL)*9*60;

const LET_FALL_SLOW = (6*SPIXEL)*9*60;
const LET_FALL_MED = (7*SPIXEL)*9*60;
const LET_FALL_FAST = (9*SPIXEL)*9*60;

const TERM_VELOC = (4*PIXEL)*9*60;
const SPEED_CAP = (4*PIXEL + 8*SPIXEL)*9*60;

#Used to keep track of the player's current state (their actions, power up, and other important values)
var State = {
	level = self,
	IsJumping = false,
	IsSkidding = false,
	IsRunning = false,
	IsCrouching = false,
	JumpLetGo = false,
	power = 0,
	block = self,
	block_type = 0,
	block_item = 0,
	coin = 0,
	direction = 1,
	#The speed you were traveling at when you jump, updated every frame when you're on the ground, otherwise is kept the same.
	jump_speed = 0,
	jump_height = 0,
}

#Variables related to the player's sprite.
var Sprite = {
	#What sprite node to use.
	sprite = %SpriteSmall,
	#What sub-animation to play from the sprite.
	anim = 'idle',
	#The speed (multiplitive) to play the animation.
	anim_speed = 1,
}

#Used for frame counters.
var Counters = {
	run_stop = 0,
	floor_time = 0,
}

#Used to store data related to hitting blocks.
var Tile_Collision = {
	#The tile map node the player collidied with.
	tile_map = null,
	#The coordinates of the cell that the player hit.
	cell = Vector2(0, 0),
	data = null,
	#This kind of doesn't belong here, but upon colliding with a block item the block item will save it's ID in the player node so the player node can send it the block they collidied with.
	block_item = null,
}
#Used so that powerups can play a sound even though they get deleted on the same frame they're picked up. The powerup sets one of these to true which will play a sound, then set itself to false.
var Sounds = {
	powerup = false,
	oneup = false,
	coin = false,
}

#Sets the gravity to it's default value on play initilize.
var gravity = DEFAULT_GRAV;


func _physics_process(delta):
	# Add the gravity.
	if !is_on_floor():
		#Only change the falling speed if the player is jumping, otherwise use the previous falling speed (yes this is how the original does it)
		if State.IsJumping == true:
			if Input.is_action_pressed("jump"):
				#If you were moving slower while you start the jump, fall faster.
				if abs(State.jump_speed) < JUMP_SLOW:
					gravity = FALL_FAST;
				elif abs(State.jump_speed) < JUMP_FAST:
					gravity = FALL_SLOW;
				#If you are fast enough just use the default gravity...?
				else:
					gravity = DEFAULT_GRAV;
			else:
				#Basically the same as above just with different values.
				if abs(State.jump_speed) < JUMP_SLOW:
					gravity = LET_FALL_MED;
				elif abs(State.jump_speed) < JUMP_FAST:
					gravity = LET_FALL_SLOW;
				else:
					gravity = LET_FALL_FAST;
		velocity.y += gravity
		Counters.floor_time = 0;
		State.IsCrouching = false;
	else:
		State.IsJumping = false;
		State.JumpLetGo = false;
		Counters.floor_time += 1;
		
	#Caps your horizontal falling speed.
	if velocity.y > SPEED_CAP: velocity.y = TERM_VELOC;

	# Handle jump.
	#If the player is moving fast enough, let them jump another 1 block.
	if abs(velocity.x) < JUMP_FAST:
		State.jump_height = -4*9*60;
	else:
		State.jump_height = -5*9*60;
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = State.jump_height;
		%JumpSound.play();
		State.IsJumping = true;
		
	###
	###Horziontal movement
	###
	#Get an axis dirived from the input map.
	var xinput = Input.get_axis("left", "right")
	
	#Creates a variable that tracks if the player is holding the run button.
	var rinput = Input.is_action_pressed("run");
	#Check if the player is pressing any horizontal input.
	if xinput && is_on_floor() && State.IsCrouching == false:
		#Check if you're not turning.
		if xinput == sign(velocity.x) || velocity.x == 0:
			if !rinput && Counters.run_stop == 0:
				#Check if the player is under max walking speed, and if so accelerate by the walking acceleration each frame in the direction they're holding.
				if abs(velocity.x) < WALK_SPEED: velocity.x += WALK_ACCEL*xinput;
				#If they're above or at max speed, set their speed to max speed to make sure they don't go over.
				else: velocity.x = WALK_SPEED*xinput;
				
				if abs(velocity.x) < MIN_WALK_SPEED: velocity.x = MIN_WALK_SPEED*sign(velocity.x);
			if rinput:
				#Check if the player is under max walking speed, and if so accelerate by the walking acceleration each frame in the direction they're holding.
				if abs(velocity.x) < RUN_SPEED: velocity.x += RUN_ACCEL*xinput;
				#If they're above or at max speed, set their speed to max speed to make sure they don't go over.
				else: velocity.x = RUN_SPEED*xinput;
				#Makes it so that 10 frames have to pass after not running for mario to walk, so that you can fireball without stopping running.
				Counters.run_stop = 10;
			State.IsSkidding = false;
		#If the player is turning.
		else:
			#Check if their not stopped, and if so decelerate them every frame in the way they're holding.
			if abs(velocity.x) > SKID_ACCEL: velocity.x += SKID_ACCEL*-sign(velocity.x);
			else: velocity.x = 0;
			State.IsSkidding = true;
		#Tracks what speed you're running at for when you jump.
		State.jump_speed = velocity.x;
	#If you are moving in the air.
	elif xinput && !is_on_floor():
		#If you are holding forward.
		if xinput == sign(velocity.x) || velocity.x == 0:
			if abs(velocity.x) < WALK_SPEED:
				velocity.x += WALK_ACCEL*xinput;
			else:
				velocity.x += RUN_ACCEL*xinput;
				
			#Caps your speed, if you started the jump walking cap it to walking speed, otherwise cap it to running speed.
			if abs(State.jump_speed) <= WALK_SPEED:
				if abs(velocity.x) > WALK_SPEED: velocity.x = WALK_SPEED*sign(velocity.x);
			else:
				if abs(velocity.x) > RUN_SPEED: velocity.x = RUN_SPEED*sign(velocity.x);
				
		#If you are holding backwards.
		else:
			if abs(velocity.x) >= WALK_SPEED:
				velocity.x += RUN_ACCEL*xinput;
			elif abs(State.jump_speed) >= JUMP_TURN:
				velocity.x += STOP_ACCEL*xinput;
			else:
				velocity.x += WALK_ACCEL*xinput;
	elif is_on_floor():
		#Checks if you're still moving.
		if velocity.x != 0:
			#Checks if you're not skidding.
			if State.IsSkidding == false:
				#Decrease your speed by your stopping deceleration every frame.
				if abs(velocity.x) > STOP_ACCEL: velocity.x += STOP_ACCEL*-sign(velocity.x);
				else: velocity.x = 0;
			#If you are still skidding, keep skidding normally.
			else:		
				if abs(velocity.x) > SKID_ACCEL: velocity.x += SKID_ACCEL*-sign(velocity.x);
				else: velocity.x = 0;
		else:
			State.IsSkidding = false;
		
	#If you press down while not pressing anything crouch.
	if Input.is_action_pressed('down'):
		State.IsCrouching = true;
	else: State.IsCrouching = false;
		
	#if you press left or were holding left and just land, while on the floor, flip the direction of the player so they turn around.
	if ((xinput == -1 || xinput == -1 && Counters.floor_time == 1) && State.direction == 1 || (xinput == 1 || xinput == 1 && Counters.floor_time == 1) && State.direction == -1) && is_on_floor() && State.IsCrouching == false:
		scale.x = -9;
		State.direction *= -1;
	
	if Counters.run_stop > 0 && !rinput:
		Counters.run_stop -= 1;
		
	if is_on_ceiling():
		#Gets the tile map from the last slide collision.
		Tile_Collision.tile_map = get_slide_collision(get_slide_collision_count() - 1).get_collider();
		#If the player is small check 16 tiles above them, otherwise check 32 above them to account for their extra height.
		Tile_Collision.cell = Tile_Collision.tile_map.local_to_map(Vector2i(position.x/9, position.y/9 - 16))
		
		
		if State.power == 0:
			#Get the cell of the block to hit.
			#Checks the blocks to the left and right to the player so they can hit "edges" without it not doing anything.
			check_adjacent_blocks(16);
		else:
			check_adjacent_blocks(32);
		#Gets the data at the tile right above the player.
		Tile_Collision.data = Tile_Collision.tile_map.get_cell_tile_data(0, Tile_Collision.cell)
		var palette = 0
		#If the data is valid, retrieve what type of block it is (ground, ? block, brick block) and save it to the player state.
		if Tile_Collision.data:
			State.block_type = Tile_Collision.data.get_custom_data("Type")
			palette = Tile_Collision.data.get_custom_data("Palette")
		else:
			#If it is invalid just set it to the default of 0 (ground)
			State.block_type = 0;
		#If the player hits a questionmark block.
		if State.block_type == 1 && Tile_Collision.tile_map.name == "Blocks":
			if State.block_item == 0: 
				%CoinSound.play();
				State.coin += 1;
			else: 
				#Spawns an item.
				spawn_item();
			
			#Sets the tile to an empty block.
			Tile_Collision.tile_map.set_cell(0, Tile_Collision.cell, 0, Vector2(16, palette), 0)
		#Brick blocks.
		elif State.block_type == 1 && Tile_Collision.tile_map.name == 'Tiles':
			#If it's a normal brick block.
			if State.block_item == 0:
				#If the player isn't small and hits a brick block, destroy it.
				if State.power > 0:
					Tile_Collision.tile_map.erase_cell(0, Tile_Collision.cell);
					%BreakSound.play();
				else: %BumpSound.play();
			#If it is a brick block with an item.
			else:
				spawn_item();
				#Sets the tile to an empty block.
				Tile_Collision.tile_map.set_cell(0, Tile_Collision.cell, Tile_Collision.tile_map.tile_set.get_source_id(0), Vector2(8, palette), 0)

		
	#Changes the sprite that's visible and playing animations depending on the player's powerup level.
	#Small
	if State.power == 0: 
		#Sets the sprite to play animations from to the small sprite, and disables the other sprite's visibility.
		Sprite.sprite = %SpriteSmall;
		%SpriteSmall.visible = true;
		%SpriteBig.visible = false;
		%SpriteFire.visible = false;
		
		#Enables the small hitbox and disables all others.
		%SmallHitbox.disabled = false;
		%BigHitbox.disabled = true;
		%CrouchHitBox.disabled = true;
	#Big/fire flower
	else:
		#Checks if mario is big.
		if State.power == 1:
			#Sets the sprite to the big sprite and disables the visibilies of the others.
			Sprite.sprite = %SpriteBig;
			%SpriteSmall.visible = false;
			%SpriteBig.visible = true;
			%SpriteFire.visible = false;
		#Checks if mario is instead in his fire form.
		else:
			#Sets the sprite to the fire sprite and disables the visibilites of the others.
			Sprite.sprite = %SpriteFire;
			%SpriteSmall.visible = false;
			%SpriteBig.visible = false;
			%SpriteFire.visible = true;
		
		#Disables the small hitbox.
		%SmallHitbox.disabled = true;
		#If the player is crouching use the crouch hitbox, otherwise use the normal big hitbox.
		if Sprite.anim != "crouch": 
			%BigHitbox.disabled = false;
			%CrouchHitBox.disabled = true;
		else: 
			%BigHitbox.disabled = true;
			%CrouchHitBox.disabled = false;

	
	if is_on_floor():
		if velocity.x != 0 && State.IsSkidding == false && Sprite.anim != "crouch":
			Sprite.anim = "run";
		elif State.IsSkidding == true:
			Sprite.anim = "turn";
		else:
			Sprite.anim = "idle";
			
		if !xinput && State.IsCrouching == true && State.power > 0:
			Sprite.anim = "crouch";
		Sprite.anim_speed = 1;
	else:
		if State.IsJumping == true:
			Sprite.anim = "jump";
			Sprite.anim_speed = 1;
		else:
			Sprite.anim = "run";
			Sprite.anim_speed = 0;
			Sprite.sprite.set_frame_and_progress(2, 0);
	
	Sprite.sprite.play(Sprite.anim, Sprite.anim_speed);
	
	if Sounds.powerup == true:
		%PowerSound.play();
		Sounds.powerup = false;
	if Sounds.oneup == true:
		%OneupSound.play();
		Sounds.oneup = false;
	if Sounds.coin == true:
		%CoinSound.play();
		Sounds.coin = false;
	
	move_and_slide()


func check_adjacent_blocks(height) -> void:
	var cell = Tile_Collision.cell
	var tile_map = Tile_Collision.tile_map;
	var check = -1;
	
	#Defaults the cell to right above you.
	cell = tile_map.local_to_map(Vector2i(position.x/9, position.y/9 - height))
	#Gets the atlas index of the cell above you.
	check = tile_map.get_cell_atlas_coords(0, cell).x;
	#If it is valid (not -1) save the new cell to the one above you.
	if check != -1:
		cell = tile_map.local_to_map(Vector2i(position.x/9, position.y/9 - height));
	else:
		#If it is invalid check the cell one tile to the left.
		check = tile_map.get_cell_atlas_coords(0, Vector2i(cell.x - 1, cell.y)).x;
		#If that is valid, save it as the cell to use.
		if check != -1:
			cell = tile_map.local_to_map(Vector2i(position.x/9 - 16, position.y/9 - height));
		else:
			#Otherwise use the cell on the right.
			cell = tile_map.local_to_map(Vector2i(position.x/9 + 16, position.y/9 - height));
			

	Tile_Collision.cell = cell;
	Tile_Collision.tile_map = tile_map;
	
func spawn_item() -> void:
	#Default the item to a mushroom.
	var path = preload('res://Actors/Level Objects/mushroom.tscn').instantiate()
	#Checks the item assigned to the current block the player is hitting.
	#1 for scaling powerup.
	if State.block_item == 1:
		if State.power == 0: path = preload('res://Actors/Level Objects/mushroom.tscn').instantiate();
		else: path = preload('res://Actors/Level Objects/fire_flower.tscn').instantiate();
	#2 for mushroom.
	elif State.block_item == 2: path = preload('res://Actors/Level Objects/mushroom.tscn').instantiate();
#3 for fire flower.
	elif State.block_item == 3: path = preload('res://Actors/Level Objects/fire_flower.tscn').instantiate();
	#4 for star.
	elif State.block_item == 4: path = preload('res://Actors/Level Objects/fire_flower.tscn').instantiate();
	#5 for 1up.
	elif State.block_item == 5: path = preload('res://Actors/Level Objects/1up.tscn').instantiate();
	#Creates an item node that's a child of the main level.
	get_parent().add_child(path);
				
	var coord = Vector2(State.block.position.x, State.block.position.y - 16*9);
	path.position = coord;
	%ItemSound.play();
	
