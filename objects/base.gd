extends StaticBody2D

@onready var player = $/root/Node2D/player

func _ready():
	$"/root/Node2D/player/attack".body_entered.connect(_connect)

func _connect(body):
	if body == self:
		if body.get_meta("health") > 0:
			var damage = player.items[player.inv[player.selected_slot]["Name"]]["damage"]
			if !(player.items[player.inv[player.selected_slot]["Name"]]["type"] == "tool" && player.items[player.inv[player.selected_slot]["Name"]]["tool"] == body.get_meta("tool")):
				damage = floor(damage / 10)
			body.get_node("AnimationPlayer").play("damage")
			body.set_meta("health", body.get_meta("health") - damage)
			player.damage_tool(1)
		else:
			body.get_node("AnimationPlayer").play("death")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		self.queue_free()
		for i in get_meta("drop"):
			for j in range(randi_range(i[1], i[2])):
				player.spawn_item(global_position.x, global_position.y, i[0])
