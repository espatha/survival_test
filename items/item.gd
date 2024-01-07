extends StaticBody2D
@onready var player = $"/root/Node2D/player"
var v
var time = 0
var drop_time = 0.5

func _ready():
	$Area2D.body_entered.connect(col.bind($"/root/Node2D/player"))
	await get_tree().process_frame
	v = get_meta("move")
	if v != Vector2.ZERO:
		$Area2D/CollisionShape2D.disabled = true
	
func _process(delta):
	if time < drop_time && v != Vector2.ZERO:
		time += delta
		print(v)
		position += v * delta * (0.2/drop_time)
		$Sprite.position = Vector2(0, -30 * (-(((2 * time) / drop_time) - 1)**2 + 1))
		if time > drop_time / 2:
			$Area2D/CollisionShape2D.disabled = false

func col(area, body):
	if body.can_add_item(self.get_meta("item_type"), 1) && !player.dead:
		body.add_item(self.get_meta("item_type"), 1)
		self.queue_free()
		
