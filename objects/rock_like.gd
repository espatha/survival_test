extends StaticBody2D

@onready var player = $/root/Node2D/player

func _ready():
	$"/root/Node2D/player/attack".area_entered.connect(_connect)

func _connect(area):
	var body = area.get_owner()
	if body == self && body.has_meta("type") && body.get_meta("type") == "rock" && player.can_add_item("rock", 1):
		player.add_item("rock", 1)
		self.queue_free()
