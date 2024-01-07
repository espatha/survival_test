extends StaticBody2D

@onready var player = $/root/Node2D/player
var branch = preload("res://objects/tscn/falling_stick.tscn")

func _ready():
	$"/root/Node2D/player/attack".body_entered.connect(_connect)

func _connect(body):
	if body == self && body.has_meta("type") && body.get_meta("type") == "tree":
		if body.get_meta("health") > 0:
			body.get_node("AnimationPlayer").play("damage")
			body.set_meta("health", body.get_meta("health") - player.items[player.inv[player.selected_slot]["Name"]]["damage"])
		else:
			body.get_node("CollisionShape2D").queue_free()
			if player.position.x < body.global_position.x:
				body.get_node("AnimationPlayer").play("death")
			else:
				body.get_node("AnimationPlayer").play("-death")
		var nbt = get_meta("nbt")
		if nbt["branches"] > 0 && randi() % 2 == 0:
			var stick = branch.instantiate()
			$/root/Node2D.add_child(stick)
			stick.position = self.global_position + Vector2(randi_range(-140, 140), randi_range(-140, 140))
			stick.rotation = deg_to_rad(0)
			nbt["branches"] -= 1
			set_meta("nbt", nbt)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		self.queue_free()
		for i in range(3 + randi_range(0, 4)):
			player.spawn_item(global_position.x + i*80, global_position.y, "wood")
		for i in range(2 + randi_range(0, 2)):
			player.spawn_item(global_position.x + 180 + randi_range(-150, 150), global_position.y + randi_range(-150, 150), "stick")
	if anim_name == "-death":
		self.queue_free()
		for i in range(3 + randi_range(0, 3)):
			player.spawn_item(global_position.x - i*80, global_position.y, "wood")
		for i in range(2 + randi_range(0, 2)):
			player.spawn_item(global_position.x - 180 + randi_range(-150, 150), global_position.y + randi_range(-150, 150), "stick")
