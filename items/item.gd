extends StaticBody2D

func _ready():
	$Area2D.body_entered.connect(col.bind($"/root/Node2D/player"))

func col(area, body):
	if body.can_add_item(self.get_meta("item_type"), 1):
		body.add_item(self.get_meta("item_type"), 1)
		self.queue_free()
		
