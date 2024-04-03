extends Node2D
var grass = preload("res://ground/grass.png")
var noise = FastNoiseLite.new()
var obj_noise = FastNoiseLite.new()
var mountain_noise = FastNoiseLite.new()
var copper_noise = FastNoiseLite.new()
var time = 720.0
var SPT = 0.2

@onready var camera = $player/Camera2D


var chunks = [#{
	#"X":0,
	#"Y":0,
	#"Ground":[[1, 28], [1, 3], [0, 1], [1, 4], [2, 40]],
	#"Objects":[{"type":"tree", "x":1, "y":5, "health":100},{"type":"tree", "x":5, "y":10, "health":10}]}
]

func _physics_process(_delta):
	time += SPT
	#print(get_chunk($player.global_position.x, $player.global_position.y))
	
func get_chunk_local(x, y):
	var coo = [x, y]
	for i in range(len(chunks)):
		if chunks[i]["X"] == coo[0] && chunks[i]["Y"] == coo[1]:
			return i
	return -1

func get_chunk_obj(x, y):
	var cc = camera.chunk_coords(x, y)
	for i in $Grass.get_children():
		if i.name == str(cc[0]) + "; " + str(cc[1]):
			return i

func get_chunk(x, y):
	var coo = $player/Camera2D.chunk_coords(x, y)
	return get_chunk_local(int(coo[0] / 1), int(coo[1] / 1))

func setblock(i, ground, block_type):
	if i != -1 and ground[i][0] == block_type:
		ground[i][1] += 1
	else:
		ground.append([block_type, 1])
	i += 1

func set_block(x, y, id):
	var chunk = get_chunk(x, y)
	if chunk != -1:
		var obj = get_chunk_obj(x, y)
		var coo = camera.inside_chunk_coords(x, y)
		var block = coo[0] + coo[1] * 16
		chunks[chunk]["Ground"][block][0] = id
		if obj != null:
			var new_block = obj.get_child(block + 1)
			var k = chunks[chunk]["Ground"][block]
			camera.render_block(new_block, k)

func get_block(x, y, chunk):
	var i = floor(y) * 16 + floor(x)
	var leftover = 0
	for j in chunk:
		if j[1] + leftover > i:
			return j[0]
		else:
			leftover += j[1]
	
func getblock(x, y):
	x += 40
	y += 40
	var dx = floor(x / 1280)
	var dy = floor(y / 1280)
	for i in chunks:
		if i["X"] == dx && i["Y"] == dy:
			return get_block(x / 80 - dx * 16, y / 80 - dy * 16, i["Ground"])

func _ready():
	
	noise.fractal_octaves = 5
	noise.frequency = 0.005
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	mountain_noise.fractal_octaves = 10
	mountain_noise.frequency = 0.004
	mountain_noise.seed = randi()
	mountain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	obj_noise.noise_type = FastNoiseLite.TYPE_VALUE
	obj_noise.frequency = 1
	copper_noise.noise_type = FastNoiseLite.TYPE_VALUE
	copper_noise.frequency = 0.08


func chunk_generate(chunk_coo):
	var ground = []
	var objects = []
	var i = -1
	for y in range(16):
		var line = []
		for x in range(16):
			var new_clay_block = abs(mountain_noise.get_noise_2d((chunk_coo[0] * 16 + x + 10200), (chunk_coo[1] * 16 + y + 10897))) * 2
			var new_block = abs(noise.get_noise_2d((chunk_coo[0] * 16 + x), (chunk_coo[1] * 16 + y))) * 2
			var new_mountain_block = abs(mountain_noise.get_noise_2d((chunk_coo[0] * 16 + x), (chunk_coo[1] * 16 + y))) * 2
			var copper = copper_noise.get_noise_2d((chunk_coo[0] * 16 + x), (chunk_coo[1] * 16 + y))
			line.append([null, [0]])
			if new_block < 0.4 && new_mountain_block > 0.65 && new_mountain_block > randf_range(0.65, 0.8) && new_block < randf_range(0.2, 0.4):
				if copper > 0.5 && copper > randf_range(0.5, 0.6):
					setblock(i, ground, 4)
				else:
					setblock(i, ground, 3)
			elif new_block < 0.5 && new_clay_block > 1.4:
				setblock(i, ground, 5)
			else:
				if new_block < 0.5:
					setblock(i, ground, 1)
				elif new_block < 0.55:
					setblock(i, ground, 2)
				else:
					setblock(i, ground, 0)
		objects.append(line)
	for y in range(16):
		for x in range(16):
			var copper = copper_noise.get_noise_2d((chunk_coo[0] * 16 + x), (chunk_coo[1] * 16 + y))
			var new_obj = abs(obj_noise.get_noise_2d((chunk_coo[0] * 16 + x) * 1, (chunk_coo[1] * 16 + y) * 1) * 1)
			if new_obj < 0.008 && get_block(x, y, ground) == 1 && objects[y][x][0] == null:
				objects[y][x] = ["tree", [100, {"branches":randi_range(2, 3)}]]
			elif (new_obj > 0.76 || new_obj < 0.008) && ((get_block(x, y, ground) != 0 && randi_range(0, 3) == 1) || get_block(x, y, ground) == 3) && objects[y][x][0] == null:
				objects[y][x] = ["rock", [100, {}]]
			elif (get_block(x, y, ground) == 3 || get_block(x, y, ground) == 4) && copper > 0.49 && randf_range(0, 1) < 0.3:
				objects[y][x] = ["native_copper", [100, {}]]
			elif randi_range(0, 1000) == 1 && get_block(x, y, ground) == 1 && objects[y][x][0] == null:
				objects[y][x] = ["berry_bush", [20, {"berries":randi_range(0, 2)}]]
	chunks.append({
		"X":chunk_coo[0],
		"Y":chunk_coo[1],
		"Ground":ground,
		"Objects":objects,
		"Mobs":[]
	})
	
"""{"name":"deer", "health":50, "nbt":[], "x":0, "y":0}"""
