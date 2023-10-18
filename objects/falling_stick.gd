extends StaticBody2D


func _ready():
	if randi() % 2 == 0:
		$Stick.flip_h = true
		$Stick.flip_v = true
	$AnimationPlayer.play("death")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		$/root/Node2D/player.spawn_item(self.position.x, self.position.y, "stick")
		self.queue_free()
