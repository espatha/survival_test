extends Node2D
var grass = preload("res://ground/grass.png")
var noise = FastNoiseLite.new()


var chunks = [{
	"X":0,
	"Y":0,
	"Ground":[[1, 255], [0, 1]]
}, {
	"X":0,
	"Y":1,
	"Ground":[[1, 28], [1, 3], [0, 1], [1, 4]]
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
	
	#total bs
	for i in range(0):
		for j in range(0):
			var loh = Sprite2D.new()
			loh.set_texture(grass)
			self.add_child(loh)
			loh.position.x = 8 * i
			loh.position.y = 8 * j
		


func chunk_generate(chunk_coo):

	var ground = []
	var i = -1
	for y in range(16):
		for x in range(16):
			var new_block = abs(noise.get_noise_2d((chunk_coo[0] * 16 + x) * 1, (chunk_coo[1] * 16 + y) * 1)) * 2
			if new_block > 0.5:
				setblock(i, ground, 1)
			elif new_block > 0.45:
				setblock(i, ground, 2)
			else:
				setblock(i, ground, 0)
	chunks.append({
		"X":chunk_coo[0],
		"Y":chunk_coo[1],
		"Ground":ground
	})
