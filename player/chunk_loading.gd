extends Camera2D

var loaded_chunks = []
var grass = [preload("res://ground/grass.png"), preload("res://ground/grass1.png"), preload("res://ground/grass2.png"), preload("res://ground/grass3.png"), preload("res://ground/grass4.png")]
var sand = [preload("res://ground/sand.png"), preload("res://ground/sand1.png"), preload("res://ground/sand2.png")]
var stone = [preload("res://ground/stone.png"), preload("res://ground/stone1.png"), preload("res://ground/stone2.png")]
var copper = [preload("res://ground/malachite1.png"), preload("res://ground/malachite.png")]
var water = preload("res://ground/water.png")
var clay = preload("res://ground/clay.png")
var name_to_obj = {"tree":preload("res://objects/tscn/tree.tscn"),
"rock":preload("res://objects/tscn/rock.tscn"),
"native_copper":preload("res://objects/tscn/copper_rock.tscn"),
"berry_bush":preload("res://objects/tscn/berry_bush.tscn"),
"campfire":preload("res://builds/tscn/campfire.tscn"),
"log_wall":preload("res://builds/tscn/log_wall.tscn"),
"deer":preload("res://mob/deer/deer.tscn"),
"zombie":preload("res://mob/zombu/zombie.tscn")
}
var error = preload("res://builds/tscn/error.tscn")
var ready_to_load = false
var nav_mesh = []


signal generate(chunk_coo)

@onready var world_obj = $"/root/Node2D/Grass"
@onready var world_gen = $"/root/Node2D"
@onready var world_mobs = $"../../mobs"

func _process(delta):
	#print(chunk_coords(global_position.x, global_position.y))
	$"../../CanvasModulate/AnimationPlayer".seek((int($"../..".time) % 1440) / 60.0)
	$"../../CanvasModulate/AnimationPlayer".play("day_night_cycle")
	var center_chunk = [floor(global_position.x / 1280 - 2), floor(global_position.y / 1280 - 2)]	
	var chunks_to_load = []
	
	
	for x in range(5):
		for y in range(5):
			chunks_to_load.append([center_chunk[0] + x, center_chunk[1] + y])
			
	for i in world_obj.get_children():
		var chunk_coords = [i.position.x / 128, i.position.y / 128]
		if !chunks_to_load.has(chunk_coords):
			loaded_chunks.erase(chunk_coords)
			for chunk in world_gen.chunks:
				if chunk["X"] == chunk_coords[0] and chunk["Y"] == chunk_coords[1]:
					var objects = []
					for y in range(16):
						var line = []
						for x in range(16):
							line.append([null, [0, {}]])
						objects.append(line)
					for obj in i.get_node("Items").get_children():
						var coords = in_chunk_coords(obj.global_position.x, obj.global_position.y)
						objects[coords[1]][coords[0]][0] = obj.get_meta("type")
						objects[coords[1]][coords[0]][1][0] = obj.get_meta("health")
						objects[coords[1]][coords[0]][1][1] = obj.get_meta("nbt")
					chunk["Objects"] = objects
					
			i.queue_free()
	
	for i in chunks_to_load:
		if !loaded_chunks.has(i):
			if ready_to_load:
				ready_to_load = false
				var is_generated = false
				for j in world_gen.chunks:
					if i[0] == j.X and i[1] == j.Y:
						is_generated = true
						var new_chunk = Marker2D.new()
						loaded_chunks.append([i[0], i[1]])
						var blocks_placed = 0
						world_obj.add_child(new_chunk)
						new_chunk.position.x = i[0] * 128
						new_chunk.position.y = i[1] * 128
						new_chunk.name = str(i[0]) + "; " + str(i[1])
						new_chunk.y_sort_enabled = true
						var item_layer = Marker2D.new()
						new_chunk.add_child(item_layer)
						item_layer.name = "Items"
						item_layer.y_sort_enabled = true
						
						for x in range(16):
							for y in range(16):
								if j["Objects"][y][x][0]:
									var new_obj
									if name_to_obj.has(j["Objects"][y][x][0]):
										new_obj = name_to_obj[j["Objects"][y][x][0]].instantiate()
									else:
										print("obj data is corrupted")
										new_obj = error.instantiate()
									item_layer.add_child(new_obj)
									new_obj.set_meta("health", j["Objects"][y][x][1][0])
									new_obj.set_meta("nbt", j["Objects"][y][x][1][1])
									new_obj.position = Vector2(x * 8, y * 8)
						
						for f in j["Mobs"]:
							var nam = f["name"]
							var mob = name_to_obj[nam].instantiate()
							mob.position = Vector2(f["x"], f["y"])
							mob.set_meta("health", f["health"])
							world_mobs.add_child(mob)
						
						for k in j.Ground:
							for l in range(k[1]):
								var new_block = Sprite2D.new()
								new_chunk.add_child(new_block)
								render_block(new_block, k)
								new_block.position.x = ((blocks_placed + l) % 16) * 8
								new_block.position.y = floor((blocks_placed + l) / 16) * 8
							blocks_placed += k[1]
				if !is_generated:
					generate.emit(i)
					
func render_block(new_block, k):
	if k[0] == 4:
		new_block.name = "copper"
		new_block.set_texture(copper[randi() % copper.size()])
	elif k[0] == 3:
		new_block.name = "stone"
		new_block.set_texture(stone[randi() % stone.size()])
	elif k[0] == 5:
		new_block.name = "clay"
		new_block.set_texture(clay)
	elif k[0] == 1:
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
	
func chunk_coords(x, y):
	var output = [0, 0]
	output[0] = floor((floor(x) + 40) / 1280)
	output[1] = floor((floor(y) + 40) / 1280)
	return output
	
func in_chunk_coords(x, y):
	var output = [0, 0]
	output[0] = floor(fmod((floor(x) + 40), 1280) / 80)
	output[1] = floor(fmod((floor(y) + 40), 1280) / 80)
	return output
	
func inside_chunk_coords(x, y):
	var output = [0, 0]
	var cc = chunk_coords(x, y)
	output[0] = floor((x + 40 - cc[0] * 1280) / 80)
	output[1] = floor((y + 40 - cc[1] * 1280) / 80)
	return output

func _on_load_timer_timeout():
	ready_to_load = true

#"AI"
func _on_nav_update_timeout():
	var center_chunk = [floor(global_position.x / 1280 - 2), floor(global_position.y / 1280 - 2)]	
	var chunks = []
	for y in range(5):
		chunks.append([])
		for x in range(5):
			var c = world_gen.get_chunk_local(center_chunk[0] + x, center_chunk[1] + y)
			chunks[y].append([])
			if c != -1:
				chunks[y][x] = world_gen.chunks[c].duplicate()
				chunks[y][x]["Ground"] = ground_to_matrix(chunks[y][x]["Ground"])
			else:
				var objects = []
				for y1 in range(16):
					var line = []
					for x1 in range(16):
						line.append([null, [0]])
					objects.append(line)
				chunks[y][x] = {
					"Ground":ground_to_matrix([[0, 256]]),
					"Objects":objects,
				}
	nav_mesh = []
	for y in range(5):
		for dy in range(16):
			nav_mesh.append([])
			for x in range(5):
				for dx in range(16):
					if chunks[y][x]["Objects"][dy][dx][0] != null:
						nav_mesh[dy + y * 16].append(1)
					elif chunks[y][x]["Ground"][dy][dx] == 0:
						nav_mesh[dy + y * 16].append(2)
					else:
						nav_mesh[dy + y * 16].append(0)
	
func get_nav_mesh(x, y):
	var pos = nav_mesh_pos(x, y)
	if pos != null:
		return nav_mesh[pos[1]][pos[0]]
	
func nav_mesh_pos(x, y):
	var center = [floor(global_position.x / 1280 - 2) * 16, floor(global_position.y / 1280 - 2) * 16]
	if is_pos_valid(floor(x / 80) - center[0], floor(y / 80) - center[1]):
		return [floor(x / 80) - center[0], floor(y / 80) - center[1]]
	else:
		return null
		
func nav_to_global(x, y):
	var center = [floor(global_position.x / 1280 - 2) * 16, floor(global_position.y / 1280 - 2) * 16]
	return [(center[0] + x) * 80, (center[1] + y) * 80]
	

func path(from, to):
	var fp = nav_mesh_pos(from[0], from[1])
	var tp = nav_mesh_pos(to[0], to[1])
	if fp != null && tp != null:
		return get_next_pos(fp, tp)
	else:
		return [null]

func get_next_pos(from: Array, to: Array):
	var parents = []
	var x
	var y
	var open = [[from, 0, 0, 0, []]]
	var closed = []
	var max = -1
	var q
	var output
	var nav_pos = nav_mesh_pos(from[0] - 0.5, global_position.y - 0.5)
	if nav_mesh[to[1]][to[0]] != 0 || from == to:
		return [null]
	'''while len(open) > 0:
		for i in len(open):
			if max < open[i][1]:
				q = i
				max = open[i][1]
		print(open)
		for i in range(-1, 3):
			for j in range(-1, 3):
				if j != 0 && i != 0:
					var new_coo = [open[q][0][0] + i, open[q][0][1] + j]
					var g = open[q][0][1] + 1
					var h = 0
					var f = g + h
					var q_open = -1
					var q_closed = -1
					for k in len(open):
						if open[k][0] == new_coo:
							q_open = k
					for k in len(open):
						if open[k][0] == new_coo:
							q_closed = k
					if q_open != -1 && f < open[q_open][1]:
						if q_closed != -1 && f < open[q_closed][1]:
							open.append([new_coo, f, g, h, q])
					if new_coo == to:
						return [to]
		closed.append(open[q].duplicate())
		open.remove_at(q)'''
	return [nav_to_global(to[0], to[1])]

func is_pos_valid(x, y):
	#return (x >= 0) && (x < 80) && (y >= 0) && (y < 80)
	if y > len(nav_mesh) - 1:
		return false
	elif x > len(nav_mesh[y]) - 1:
		return false
	else:
		return true

func ground_to_matrix(gr):
	var out = []
	var line = []
	for i in gr:
		for j in range(i[1]):
			line.append(i[0])
	for i in range(16):
		out.append(line.slice(i * 16, i * 16 + 16))
	return out
