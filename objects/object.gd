extends StaticBody2D

@onready var player = $/root/Node2D/player

func _ready():
	$Area2D.area_entered.connect(_connect.bind($"/root/Node2D/player/attack"))

func _connect(area, body):
	if get_meta("health") > 0:
		if area.name == "attack":
			$AnimationPlayer.play("damage")
			self.set_meta("health", get_meta("health") - player.items[player.inv[player.selected_slot]["Name"]]["damage"])
	else:
		$Area2D/CollisionShape2D.queue_free()
		if player.position.x < global_position.x:
			$AnimationPlayer.play("death")
		else:
			$AnimationPlayer.play("-death")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		self.queue_free()
		for i in range(3 + randi_range(0, 4)):
			player.spawn_item(global_position.x + i*80 + randi_range(-10, 10), global_position.y  + randi_range(-10, 10), "wood")
	if anim_name == "-death":
		self.queue_free()
		for i in range(3 + randi_range(0, 3)):
			player.spawn_item(global_position.x - i*80 + randi_range(-20, 20), global_position.y  + randi_range(-20, 20), "wood")
