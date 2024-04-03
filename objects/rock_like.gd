extends StaticBody2D

@onready var player = $/root/Node2D/player

func _ready():
	$"/root/Node2D/player/attack".area_entered.connect(_connect)

func _connect(area):
	var body = area.get_owner()
	if body == self && body.has_meta("type") && player.can_add_item(body.get_meta("type"), 1):
		player.add_item(body.get_meta("type"), 1)
		self.queue_free()
