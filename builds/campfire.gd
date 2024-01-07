extends StaticBody2D

@onready var player = $/root/Node2D/player
var recipes = [["stake", "meat", 0.01, 100],
["sticks", "berries", 0.3, 400]]
var progress = 0.0
@onready var fire = $TextureRect/TextureProgressBar2
@onready var arrow = $TextureRect/TextureProgressBar
@onready var light = $PointLight2D

func _ready():
	$"/root/Node2D/player/attack".area_entered.connect(_connect)
	$fire/AnimationPlayer.play("fire")
	fire = $TextureRect/TextureProgressBar2
	arrow = $TextureRect/TextureProgressBar
	light = $PointLight2D
	self.set_meta("nbt", {"fuel":0, "inv":[{"Count":0, "Name":"air"}, {"Count":0, "Name":"air"}, {"Count":0, "Name":"air"}], "temperature":0})

func _physics_process(_delta):

	if player.global_position.distance_to(self.global_position) > 1000:
		$TextureRect.hide()
	
	var nbt = self.get_meta("nbt")
	light.energy = (nbt["temperature"] / 150) ** 1/4
	
	if nbt["inv"][2] != null:
		var item = player.items[nbt["inv"][2]["Name"]]
		if item.has("fuel") && nbt["fuel"] <= 0:
			nbt["fuel"] = item["fuel"]
			nbt["inv"][2]["Count"] -= 1
			$TextureRect/Slot3.render_slot(2)
	if nbt["fuel"] > 0 && nbt["temperature"] < 500:
		nbt["fuel"] -= 1
		nbt["temperature"] += 0.2
	elif nbt["temperature"] > 0:
		nbt["temperature"] -= 0.2
	if nbt["temperature"] > 2:
		$fire.show()
	else:
		$fire.hide()
	var loh = true
	for i in recipes:
		if i[1] == nbt["inv"][0]["Name"] && (nbt["inv"][1]["Name"] == "air" || nbt["inv"][1]["Name"] == i[0]) && nbt["inv"][1]["Count"] < player.items[nbt["inv"][1]["Name"]]["stack"] && nbt["temperature"] > i[3]:
			progress += i[2]
			loh = false
			if progress > 9:
				nbt["inv"][0]["Count"] -= 1
				nbt["inv"][1]["Name"] = i[0]
				nbt["inv"][1]["Count"] += 1
				$TextureRect/Slot2.render_slot(1)
				$TextureRect/Slot.render_slot(0)
				progress = 0
	if loh && progress > 0:
		progress -= 0.2
	fire.value = int(nbt["temperature"] / 62)
	arrow.value = int(progress)
	self.set_meta("nbt", nbt)

func _connect(area):
	var body = area.get_owner()
	if body == self:
		if body.get_meta("health") > 0:
			body.get_node("AnimationPlayer").play("damage")
			body.set_meta("health", body.get_meta("health") - player.items[player.inv[player.selected_slot]["Name"]]["damage"])
		else:
			body.get_node("Area2D").get_node("CollisionShape2D").queue_free()
			body.get_node("AnimationPlayer").play("death")

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		for i in get_meta("nbt")["inv"]:
			for j in range(i["Count"]):
				player.spawn_item(global_position.x, global_position.y, i["Name"])
		self.queue_free()

func _on_area_2d_input_event(_viewport, _event, _shape_idx):
	if Input.is_action_just_pressed("use_inv"):
		$TextureRect.visible = !$TextureRect.visible
