extends StaticBody2D

var no_berry = preload("res://objects/sprites/bush.png")
@onready var player = $/root/Node2D/player

func _ready():
	$"/root/Node2D/player/attack".area_entered.connect(_connect)
	set_meta("nbt", {"Berries":randi_range(1, 3)})

func _connect(area):
	var body = area.get_owner()
	if body == self && body.has_meta("type") && body.get_meta("type") == "berry_bush":
		if body.get_meta("health") > 0:
			var meta = body.get_meta("nbt")
			body.get_node("AnimationPlayer").play("damage")
			body.set_meta("health", body.get_meta("health") - player.items[player.inv[player.selected_slot]["Name"]]["damage"])
			if meta["Berries"] > 0 && player.can_add_item("rock", 1):
				meta["Berries"] -= 1
				body.set_meta("nbt", meta)
				body.get_node("Sprite").set_texture(no_berry)
				player.add_item("rock", 1)
		else:
			body.get_node("AnimationPlayer").play("death")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		self.queue_free()
		for i in range(randi_range(0, 2)):
			player.spawn_item(global_position.x, global_position.y, "stick")