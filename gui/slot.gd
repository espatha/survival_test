extends TextureRect
@onready var pl = $"/root/Node2D/player"

func _ready():
	var i = get_index()
	var inv = self.get_owner().get_meta("nbt")["inv"]
	if inv[i] != null && inv[i]["Name"] != "air":
		set_item(inv[i]["Name"], inv[i]["Count"])
		render_slot(i)


func _on_gui_input(event):
	var inv = self.get_owner().get_meta("nbt")["inv"]
	var slot = self
	var id = slot.get_index()
	if event.is_action_pressed("use_inv"):
		if inv[id]["Name"] == "air":
			if pl.is_holdin_an_item:
				set_item(pl.held_item[0], 1)
				inv[id]["Name"] = pl.held_item[0]
				inv[id]["Count"] = 1				
				pl.held_item[1] -= 1
				if pl.held_item[1] < 1:
					pl.held_item = ["air", 0, 0, 0, 0]
					pl.is_holdin_an_item = false
				pl.hold()
				render_slot(id)
		else:
			if pl.items[inv[id]["Name"]]["type"] == "food" && pl.food < 39:
				pl.eat(pl.items[inv[id]["Name"]]["sat"])
				inv[id]["Count"] -= 1
				if inv[id]["Count"] < 1:
					inv[id]["Name"] = "air"
				render_slot(id)
			else:
				if !pl.is_holdin_an_item:
					var half = (inv[id]["Count"] / 2)
					print(half)
					pl.held_item = [inv[id]["Name"], inv[id]["Count"] - half, 0, 0, 0]
					pl.is_holdin_an_item = true
					pl.hold()
					inv[id]["Count"] = half
					render_slot(id)
				elif inv[id]["Name"] == pl.held_item[0] && pl.items[inv[id]["Name"]]["stack"] > inv[id]["Count"]:
					pl.held_item[1] -= 1
					pl.hold()
					inv[id]["Count"] += 1
					render_slot(id)
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
		if !pl.is_holdin_an_item:
			var nam : String
			var count
			if slot.get_child_count() != 0:
				nam = slot.get_child(0).name
				count = int(inv[id]["Count"])
			else:
				return
			pl.held_item = [nam, count, slot.get_child(0).get_meta("nbt"), id, slot]
			pl.is_holdin_an_item = true
			pl.hold()
			inv[id] = {"Name":"air", "Count":0}
			render_slot(id)
		else:
			if slot.get_child_count() == 0:
				pl.is_holdin_an_item = false
				inv[id] = {"Name":pl.held_item[0], "Count":pl.held_item[1]}
				render_slot(id)
				pl.held.hide()
			elif slot.get_child(0).name == pl.held_item[0]:
				if pl.held_item[1] <= pl.items[pl.held_item[0]]["stack"] - inv[id]["Count"]:
					inv[id]["Count"] += pl.held_item[1]
					pl.held.hide()
					pl.is_holdin_an_item = false
				else:
					pl.held_item[1] -= pl.items[pl.held_item[0]]["stack"] - inv[id]["Count"]
					inv[id]["Count"] = pl.items[pl.held_item[0]]["stack"]
					pl.hold()
				if inv[id]["Count"] > 1:
					get_child(0).get_node("Label").text = str(inv[id]["Count"])
				else:
					slot.get_child(0).get_node("Label").text = ""
			elif slot.get_child(0).name != pl.held_item[0]:
				var c = pl.held_item
				pl.held_item = [inv[id]["Name"], inv[id]["Count"], slot.get_child(0).get_meta("nbt"), id, slot]
				pl.hold()
				inv[id] = {"Name":c[0], "Count":c[1]}
				slot.get_child(0).name = c[0]
				slot.get_child(0).set_texture(pl.items[c[0]]["texture"])
				if c[1] > 1:
					slot.get_child(0).get_node("Label").text = str(c[1])
				else:
					slot.get_child(0).get_node("Label").text = ""
	render_slot(id)
	var nbt = self.get_owner().get_meta("nbt")
	nbt["inv"] = inv
	self.get_owner().set_meta("nbt", nbt)

func set_item(item_name, count):
	var new_item = pl.item_inv.instantiate()
	add_child(new_item)
	new_item.set_texture(pl.items[item_name]["texture"])
	new_item.position.x = 6
	new_item.position.y = 6
	new_item.scale.y = 0.4
	new_item.scale.x = 0.4
	new_item.name = item_name
	if count > 1:
		new_item.get_node("Label").text = str(count)
	else:
		new_item.get_node("Label").text = ""

func inv_add_item(slot_id, _item_name, count):
	if count > 1:
		get_child(0).get_node("Label").text = str(count)
	else:
		get_child(0).get_node("Label").text = ""

func render_slot(id):
	var inv = self.get_owner().get_meta("nbt")["inv"]
	var slot = self
	if inv[id]["Count"] < 1:
		inv[id]["Name"] = "air"
	if slot.get_child_count() == 0 && inv[id]["Name"] != "air":
		set_item(inv[id]["Name"], inv[id]["Count"])
	elif slot.get_child_count() != 0 && inv[id]["Name"] == "air":
		slot.remove_child(slot.get_child(0))
	elif slot.get_child_count() != 0 && inv[id]["Name"] != "air":
		slot.get_child(0).set_texture(pl.items[inv[id]["Name"]]["texture"])
		if inv[id]["Count"] != 1:
			slot.get_child(0).get_node("Label").text = str(inv[id]["Count"])
		else:
			slot.get_child(0).get_node("Label").text = ""
