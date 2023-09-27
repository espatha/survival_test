extends Camera2D

var loaded_chunks = []
var grass = [preload("res://ground/grass.png"), preload("res://ground/grass1.png"), preload("res://ground/grass2.png"), preload("res://ground/grass3.png"), preload("res://ground/grass4.png")]
var sand = [preload("res://ground/sand.png"), preload("res://ground/sand1.png"), preload("res://ground/sand2.png")]
var water = preload("res://ground/water.png")

signal generate(chunk_coo)

@onready var world_obj = $"/root/Node2D/Grass"

func _process(delta):
	
	
	
	var center_chunk = [floor(global_position.x / 1280 - 1.5), floor(global_position.y / 1280 - 2)]	
	var chunks_to_load = []
	for x in range(5):
		for y in range(5):
			chunks_to_load.append([center_chunk[0] + x, center_chunk[1] + y])
			
	for i in world_obj.get_children():
		var chunk_coords = [i.position.x / 128, i.position.y / 128]
		if !chunks_to_load.has(chunk_coords):
			loaded_chunks.erase(chunk_coords)
			i.queue_free()
			
	for i in chunks_to_load:
		if !loaded_chunks.has(i):
			var is_generated = false
			for j in $"/root/Node2D".chunks:
				if i[0] == j.X and i[1] == j.Y:
					is_generated = true
					var new_chunk = Marker2D.new()
					loaded_chunks.append([i[0], i[1]])
					var blocks_placed = 0
					world_obj.add_child(new_chunk)
					new_chunk.position.x = i[0] * 128
					new_chunk.position.y = i[1] * 128
					new_chunk.name = str(i[0]) + "; " + str(i[1])
					for k in j.Ground:
						for l in range(k[1]):
							var new_block = Sprite2D.new()
							new_chunk.add_child(new_block)
							if k[0] == 1:
								new_block.name = "grass"
								if randi() % 2 == 1:
									new_block.set_texture(grass[2])
								else:
									new_block.set_texture(grass[randi() % grass.size()])
								new_block.z_index = 2
							elif k[0] == 2:
								new_block.name = "sand"
								new_block.set_texture(sand[randi() % sand.size()])
								new_block.z_index = 1
							else:
								new_block.name = "water"
								new_block.set_texture(water)
							new_block.position.x = ((blocks_placed + l) % 16) * 8
							new_block.position.y = floor((blocks_placed + l) / 16) * 8
						blocks_placed += k[1]
			if !is_generated:
				generate.emit(i)
