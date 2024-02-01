extends Node2D


#Used to store data related to the block bouncing animation.
var Bounce_Block ={
	bouncing = [false, false, false, false, false],
	data = [null, null, null, null, null],
	cell = [Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)],
	palette = [0, 0, 0, 0, 0],
	tile_map = [null, null, null, null, null],
	x = [0, 0, 0, 0, 0],
	block_count = 0,
	block_time = 0,
	bounce_time = [0, 0, 0, 0, 0],
}

# Called when the node enters the scene tree for the first time.
func _ready():
	%Music.play();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var player = $"../Actors/Player"
	#Checks if the player hit a ceiling.
	if player.is_on_ceiling():
		#Gets the tile map from the last slide collision.
		var tile_map = player.get_slide_collision(player.get_slide_collision_count() - 1).get_collider();
		var cell = Vector2i(0, 0)
		var data = null;
		var block_item = 0;
		var palette = 0;
		var block_type = 0;
		if tile_map.get_class() == 'TileMap':
			#If the player is small check 16 tiles above them, otherwise check 32 above them to account for their extra height.
			cell = tile_map.local_to_map(Vector2i(player.position.x/9, player.position.y/9 - 16))
			if player.State.power == 0:
				#Get the cell of the block to hit.
				#Checks the blocks to the left and right to the player so they can hit "edges" without it not doing anything.
				cell = check_adjacent_blocks(16, tile_map, player);
			else:
				cell = check_adjacent_blocks(32, tile_map, player);
			#Gets the data at the tile right above the player.
			data = tile_map.get_cell_tile_data(0, cell)
			#Checks if there is an item at that same position.
			var block_data = %BlockItems.get_cell_tile_data(0, cell);
			if block_data: block_item = block_data.get_custom_data("Type")
			#If the data is valid, retrieve what type of block it is (ground, ? block, brick block) and save it to the player state.
			if data:
				block_type = data.get_custom_data("Type")
				palette = data.get_custom_data("Palette")
			#If the player hits a questionmark block.
			if block_type == 1 && tile_map.name == "Blocks":
				if block_item == 0:
					player.Sounds.coin = true;
					player.State.coin += 1;
				#Checks if the tile you're getting the item from is the same as the actual ? block.
				else:
					#Spawn an item.
					spawn_item(player, to_global(tile_map.map_to_local(cell)), block_item);
					print('a')
				
				#Set the tile to an empty block.
				#Use the alternative tile so that the block can play it's bounce animation using the texture offset without all blocks of the same type bouncing.
				tile_map.set_cell(0, cell, 0, Vector2(16, palette), Bounce_Block.block_count + 1);
				#Saves a bunch of data to a dictionary full of arrays for the block bounce animation (done in arrays so that multiple blocks can bounce at once without the system breaking.)
				Bounce_Block.bouncing[Bounce_Block.block_count] = true;
				Bounce_Block.palette[Bounce_Block.block_count] = palette;
				Bounce_Block.cell[Bounce_Block.block_count] = cell;
				Bounce_Block.tile_map[Bounce_Block.block_count] = tile_map
				#Save the data of the new tile.
				data = tile_map.get_cell_tile_data(0, cell)
				Bounce_Block.data[Bounce_Block.block_count] = data;
				Bounce_Block.x[Bounce_Block.block_count] = tile_map.get_cell_atlas_coords(0, cell, 0).x;
				if Bounce_Block.block_count < 4: Bounce_Block.block_count += 1;
			#Brick blocks.
			elif block_type == 1 && tile_map.name == 'Tiles':
				#If it's a normal brick block.
				if player.State.block_item == 0 || cell.x != player.State.block_cell.x:
					#If the player isn't small and hits a brick block, destroy it.
					if player.State.power > 0:
						tile_map.erase_cell(0, cell);
						%BreakSound.play();
					else: 
						%BumpSound.play();
						#Use the alternative tile so that the block can play it's bounce animation using the texture offset without all blocks of the same type bouncing.
						tile_map.set_cell(0, cell, 0, tile_map.get_cell_atlas_coords(0, cell, 0), Bounce_Block.block_count + 1);
						#Saves a bunch of data to a dictionary full of arrays for the block bounce animation (done in arrays so that multiple blocks can bounce at once without the system breaking.)
						Bounce_Block.bouncing[Bounce_Block.block_count] = true;
						Bounce_Block.palette[Bounce_Block.block_count] = palette;
						Bounce_Block.cell[Bounce_Block.block_count] = cell;
						Bounce_Block.tile_map[Bounce_Block.block_count] = tile_map
						#Save the data of the new tile.
						data = tile_map.get_cell_tile_data(0, cell)
						Bounce_Block.data[Bounce_Block.block_count] = data;
						Bounce_Block.x[Bounce_Block.block_count] = tile_map.get_cell_atlas_coords(0, cell, 0).x;
						if Bounce_Block.block_count < 4: Bounce_Block.block_count += 1;
				#If it is a brick block with an item.
				elif cell.x == player.State.block_cell.x:
					spawn_item(player, to_global(tile_map.map_to_local(cell)), block_item);
					#Set the tile to an empty block.
					#Use the alternative tile so that the block can play it's bounce animation using the texture offset without all blocks of the same type bouncing.
					tile_map.set_cell(0, cell, 0, Vector2(8, palette), Bounce_Block.block_count + 1);
					#Saves a bunch of data to a dictionary full of arrays for the block bounce animation (done in arrays so that multiple blocks can bounce at once without the system breaking.)
					Bounce_Block.bouncing[Bounce_Block.block_count] = true;
					Bounce_Block.palette[Bounce_Block.block_count] = palette;
					Bounce_Block.cell[Bounce_Block.block_count] = cell;
					Bounce_Block.tile_map[Bounce_Block.block_count] = tile_map
					#Save the data of the new tile.
					data = tile_map.get_cell_tile_data(0, cell)
					Bounce_Block.data[Bounce_Block.block_count] = data;
					Bounce_Block.x[Bounce_Block.block_count] = tile_map.get_cell_atlas_coords(0, cell, 0).x;
					if Bounce_Block.block_count < 4: Bounce_Block.block_count += 1;
	if Bounce_Block.bouncing[0] == true:
		bounce_block(0, Bounce_Block.x[0]);
	if Bounce_Block.bouncing[1] == true: 
		bounce_block(1, Bounce_Block.x[1]);
	if Bounce_Block.bouncing[2] == true: 
		bounce_block(2, Bounce_Block.x[2]);
	if Bounce_Block.bouncing[3] == true: 
		bounce_block(3, Bounce_Block.x[3]);
	if Bounce_Block.bouncing[4] == true: 
		bounce_block(4, Bounce_Block.x[4]);

func check_adjacent_blocks(height, tile_map, player) -> Vector2i:
	var cell = Vector2i(0, 0)
	var check = -1;
	
	#Defaults the cell to right above you.
	cell = tile_map.local_to_map(Vector2i(player.position.x/9, player.position.y/9 - height))
	#Gets the atlas index of the cell above you.
	check = tile_map.get_cell_atlas_coords(0, cell).x;
	#If it is valid (not -1) save the new cell to the one above you.
	if check != -1:
		cell = tile_map.local_to_map(Vector2i(player.position.x/9, player.position.y/9 - height));
	else:
		#If it is invalid check the cell one tile to the left.
		check = tile_map.get_cell_atlas_coords(0, Vector2i(cell.x - 1, cell.y)).x;
		#If that is valid, save it as the cell to use.
		if check != -1:
			cell = tile_map.local_to_map(Vector2i(player.position.x/9 - 16, player.position.y/9 - height));
		else:
			#Otherwise use the cell on the right.
			cell = tile_map.local_to_map(Vector2i(player.position.x/9 + 16, player.position.y/9 - height));
			
	return cell;

func spawn_item(player, cell, block_item) -> void:
	#Default the item to a mushroom.
	var path = preload('res://Actors/Level Objects/mushroom.tscn').instantiate()
	#Checks the item assigned to the current block the player is hitting.
	#1 for scaling powerup.
	if block_item == 1:
		if player.State.power == 0: path = preload('res://Actors/Level Objects/mushroom.tscn').instantiate();
		else: path = preload('res://Actors/Level Objects/fire_flower.tscn').instantiate();
	#2 for mushroom.
	elif block_item == 2: path = preload('res://Actors/Level Objects/mushroom.tscn').instantiate();
#3 for fire flower.
	elif block_item == 3: path = preload('res://Actors/Level Objects/fire_flower.tscn').instantiate();
	#4 for star.
	elif block_item == 4: path = preload('res://Actors/Level Objects/fire_flower.tscn').instantiate();
	#5 for 1up.
	elif block_item == 5: path = preload('res://Actors/Level Objects/1up.tscn').instantiate();
	#Creates an item node that's a child of the main level.
	get_parent().add_child(path);
	var coord = Vector2((cell.x)*9, (cell.y - 16)*9);
	print(coord)
	path.global_position = coord;
	player.Sounds.item = true;
	
func bounce_block(block, x) -> void:
	#Check if the variables aren't null.
	if Bounce_Block.data[block] && Bounce_Block.tile_map[block] && Bounce_Block.cell[block] != Vector2i(0, 0):
		#Sets the cell to the alternative tile each frame so that once the previous block in the queue stops bouncing it will shift over one correctly.
		Bounce_Block.tile_map[block].set_cell(0, Bounce_Block.cell[block], 0, Vector2(x, Bounce_Block.palette[block]), block + 1)
		#For the first 10 frames make the block move up, then make the block move down.
		if Bounce_Block.bounce_time[block] <= 10: Bounce_Block.data[block].texture_origin.y += 1;
		else: Bounce_Block.data[block].texture_origin.y -= 1;
		#As a fail safe checks if the texture origin is 0 and will set the tile to the default tile instead of alternative.
		if Bounce_Block.data[block].texture_origin.y == 0:
			Bounce_Block.tile_map[block].set_cell(0, Bounce_Block.cell[block], 0, Vector2(x, Bounce_Block.palette[block]), 0);
		#Once the animation is done stop running this function, reset the counter, then set the tile to the non alternative tile.
		if Bounce_Block.bounce_time[block] >= 20: 
			Bounce_Block.tile_map[block].set_cell(0, Bounce_Block.cell[block], 0, Vector2(x, Bounce_Block.palette[block]), 0);
			Bounce_Block.bouncing[block] = false;
			Bounce_Block.bounce_time[block] = 0;
			Bounce_Block.data[block].texture_origin.y = 0;
			Bounce_Block.x[block] = 0;
			#If this is the last block in the array, 'loop' the pattern back to 0.
			if Bounce_Block.block_count == 4 || Bounce_Block.bouncing[block + 1] == false: Bounce_Block.block_count = 0;
		Bounce_Block.bounce_time[block] += 1;
