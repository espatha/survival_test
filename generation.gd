extends Node2D
var grass = preload("res://ground/grass.png")
var noise = FastNoiseLite.new()
var obj_noise = FastNoiseLite.new()

"""[1, 28], [1, 3], [0, 1], [1, 4]"""
"""[1, 255], [0, 1]"""
var chunks = [{
	"X":0,
	"Y":0,
	"Ground":[[1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2], [1, 0, 0, 1, 2, 1, 1, 1, 1, 2, 2, 1, 0, 1, 1, 2]],
	"Objects":[{"type":"tree", "x":1, "y":5, "health":100},{"type":"tree", "x":5, "y":10, "health":10}]
}]

func setblock(i, ground, block_type):
	if i != -1 and ground[i][0] == block_type:
		ground[i][1] += 1
	else:
		ground.append([block_type, 1])
	i += 1


func _ready():
	
	noise.fractal_octaves = 5
	noise.frequency = 0.005
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	obj_noise.noise_type = FastNoiseLite.TYPE_VALUE
	obj_noise.frequency = 1


func chunk_generate(chunk_coo):

	var ground = []
	var objects = []
	var i = -1
	for y in range(16):
		for x in range(16):
			var new_block = abs(noise.get_noise_2d((chunk_coo[0] * 16 + x), (chunk_coo[1] * 16 + y) * 1)) * 2
			var new_obj = abs(obj_noise.get_noise_2d((chunk_coo[0] * 16 + x) * 1, (chunk_coo[1] * 16 + y) * 1) * 1)
			if new_block > 0.5:
				setblock(i, ground, 1)
			elif new_block > 0.45:
				setblock(i, ground, 2)
			else:
				setblock(i, ground, 0)
			if new_obj < 0.007:
				objects.append({"type":"tree", "health":100, "x":x, "y":y})
	chunks.append({
		"X":chunk_coo[0],
		"Y":chunk_coo[1],
		"Ground":ground,
		"Objects":objects
	})
	
