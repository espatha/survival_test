extends CharacterBody2D

var input = Vector2.ZERO
var is_moving = false
const SPEED = 20.0 * 1000
var inv_size = 12
var hb_size = 4
@onready var item_inv = preload("res://items/item_inv.tscn")
@onready var inventory = $/root/Node2D/CanvasLayer/IngameUI/inv
@onready var hb_select = preload("res://gui/hb_select.png")
@onready var hb_unselected = preload("res://gui/hotbar.png")
@onready var hotbar = $/root/Node2D/CanvasLayer/IngameUI/hotbar2
@onready var toolbar = $"../CanvasLayer/IngameUI/tools"
@onready var craftbar = $"../CanvasLayer/IngameUI/craft"
@onready var result_slot = $"../CanvasLayer/IngameUI/result"
@onready var health_bar = $"../CanvasLayer/VBoxContainer/hp"
@onready var food_bar = $"../CanvasLayer/VBoxContainer/hp2"
var default_player = preload("res://player/player.png")
var items = {"air":{"texture":preload("res://items/air.png"), "type":"weapon", "cooldown":0.3, "damage":1, "player_texture":null, "stack":1, "anim":preload("res://player/player_fist.png")},
"iron_axe":{"texture":preload("res://items/iron_axe.png"), "type":"tool", "tool":"axe", "cooldown":0.3, "damage":10, "player_texture":preload("res://player/iron_axe.png"), "stack":1, "anim":default_player},
"wood":{"texture":preload("res://items/wood.png"), "type":"resource", "stack":10},
"rock":{"texture":preload("res://items/rock.png"), "type":"resource", "stack":10},
"stick":{"texture":preload("res://items/stick.png"), "type":"resource", "stack":10}}
var item = preload("res://scenes/item.tscn")
@onready var held = $"../CanvasLayer/IngameUI/held_item"
@onready var held_label = $"../CanvasLayer/IngameUI/held_item/Label"
var crafts = [["wood", 2, ["iron_axe"], {"wood":2, "iron_axe":1}],
["iron_axe", 1, [], {"iron_axe":1}]]

var is_holdin_an_item = false
var held_item = ["name", 0, {}, 0, 0]
var inv = []
var inv_open = false
var continue_attacking = false
var selected_slot = 0

var direction = Vector2.from_angle(90)
var is_attacking = false
var cd : float
var direction_status = 0
var current_craft = -1
var health = 20
var food = 40

@onready var sprite = get_node("Sprite")

func _ready():
	for i in range(inv_size + 6):
		inv.append({"Name":"air",
					"Count":0})
	for i in inventory.get_children():
		i.gui_input.connect(_gui_input.bind(i))
	for i in hotbar.get_children():
		i.gui_input.connect(_gui_input.bind(i))
	for i in toolbar.get_children():
		i.gui_input.connect(_gui_input.bind(i))
	for i in craftbar.get_children():
		i.gui_input.connect(_gui_input.bind(i))
	for i in result_slot.get_children():
		i.gui_input.connect(_gui_input.bind(i))

func get_input():
	input.x = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	input.y = int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	
	return input.normalized()

func _physics_process(delta):
	
	#print($"/root/Node2D".getblock(position.x, position.y))
	
	cd -= delta 
	if cd < 0:
		cd = 0
	input = get_input()

# inventory and hotbar

	if Input.is_action_just_pressed("inventory_open"):
		inv_open = !inv_open
	if inv_open:
		inventory.show()
		result_slot.show()
		toolbar.show()
		craftbar.show()
	else:
		inventory.hide()
		result_slot.hide()
		toolbar.hide()
		craftbar.hide()
	
	if Input.is_action_just_pressed("hb_selection_down"):
		selected_slot += 1
		if selected_slot > hb_size - 1:
			selected_slot = 0
		render_hb()
			
	if Input.is_action_just_pressed("hb_selection_up"):
		selected_slot -= 1
		if selected_slot < 0:
			selected_slot = hb_size - 1
		render_hb()
	
	held.position = get_local_mouse_position() * 0.5 + Vector2(DisplayServer.window_get_size()) * 0.5 - Vector2(30, 30)
	
#animation for good
	if input.x < 0:
		$AnimationPlayer.play("walk_left")
		direction_status = 3
	elif input.x > 0:
		$AnimationPlayer.play("walk_right")
		direction_status = 1
	elif input.y == 1:
		$AnimationPlayer.play("walk_up")
		direction_status = 0
	elif input.y == -1:
		$AnimationPlayer.play("walk_down")
		direction_status = 2
	else:
		$AnimationPlayer.stop(true)
		sprite.frame = direction_status * 5
	if items[inv[selected_slot]["Name"]]["type"] == "tool" || items[inv[selected_slot]["Name"]]["type"] == "weapon":
		if continue_attacking:
			$AnimationPlayer.stop()
			sprite.frame = direction_status * 5 + 20
		var current_cd = items[inv[selected_slot]["Name"]]["cooldown"]
		if 0.1 > current_cd - cd && current_cd - cd <= 0.15:
			sprite.frame = direction_status	* 5 + 21
		elif 0.15 > current_cd - cd && current_cd - cd <= 0.2:
			sprite.frame = direction_status	* 5 + 22
		$Item.set_texture(items[inv[selected_slot]["Name"]]["player_texture"])
		$Sprite.set_texture(items[inv[selected_slot]["Name"]]["anim"])
	else:
		$Item.set_texture(default_player)
	
	$Item.frame = sprite.frame
	
	velocity = input * SPEED * delta
	
	if input != Vector2.ZERO:
		direction = -input
	$attack.rotation = direction.angle()
	
	if (Input.is_action_pressed("attack") && (items[inv[selected_slot]["Name"]]["type"] == "weapon" || items[inv[selected_slot]["Name"]]["type"] == "tool")):
		if (cd <= 0 && continue_attacking):
			is_attacking = true
			cd = items[inv[selected_slot]["Name"]]["cooldown"]
			$attack_timer.start()
	else:
		continue_attacking = false
	move_and_slide()
	
func hold():
	held.show()
	held.set_texture(items[held_item[0]]["texture"])
	if held_item[1] > 1:
		held_label.text = str(held_item[1])
	else:
		held_label.text = ""
	
func can_add_item(nam, _count):
	for i in range(inv_size):
		if inv[i].Name == nam && items[nam]["stack"] > inv[i].Count:
			return true
		elif inv[i].Name == "air":
			return true
	return false

func add_item(nam, count):
	for i in range(inv_size):
		if inv[i].Name == nam && items[nam]["stack"] > inv[i].Count:
			inv[i].Count += count
			inv_add_item(i, nam, inv[i].Count)
			return
		elif inv[i].Name == "air":
			inv[i].Name = nam
			inv[i].Count = count
			inv_set_item(i, nam, inv[i].Count)
			return

func inv_set_item(slot_id, item_name, count):
	var new_item = item_inv.instantiate()
	if slot_id < hb_size:
		hotbar.get_child(slot_id - hb_size).add_child(new_item)
	elif slot_id < inv_size:
		inventory.get_child(slot_id - hb_size).add_child(new_item)
	elif slot_id < inv_size + 3:
		toolbar.get_child(slot_id - inv_size).add_child(new_item)
	elif slot_id < inv_size + 6:
		craftbar.get_child(slot_id - inv_size - 3).add_child(new_item)
	new_item.set_texture(items[item_name]["texture"])
	new_item.name = item_name
	if count > 1:
		new_item.get_node("Label").text = str(count)
	else:
		new_item.get_node("Label").text = ""

func inv_add_item(slot_id, _item_name, count):
	if slot_id >= hb_size:
		if count > 1:
			inventory.get_child(slot_id - hb_size).get_child(0).get_node("Label").text = str(count)
		else:
			inventory.get_child(slot_id - hb_size).get_child(0).get_node("Label").text = ""
	else:
		if count > 1:
			hotbar.get_child(slot_id).get_child(0).get_node("Label").text = str(count)
		else:
			hotbar.get_child(slot_id).get_child(0).get_node("Label").text = ""

func _gui_input(event, slot):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			var id = slot.get_index()
			if slot.get_parent().name == "inv":
				id += hb_size
			elif slot.get_parent().name == "tools":
				id += inv_size
			elif slot.get_parent().name == "craft":
				id += inv_size + 3
			elif slot.get_parent().name == "result":
				id = -1
			if !is_holdin_an_item:
				var nam : String
				var count
				if slot.get_child_count() != 0:
					nam = slot.get_child(0).name
					if slot.get_parent().name == "result":
						count = crafts[current_craft][1]
						remove_items_crafting(current_craft)
					else:
						count = int(inv[id]["Count"])
				else:
					return
				held_item = [nam, count, slot.get_child(0).get_meta("nbt"), id, slot]
				is_holdin_an_item = true
				hold()
				#print("shi goin on: " + str(id) + " : " + str(count))
				if slot.get_parent().name == "result":
					result_slot.get_child(0).remove_child(result_slot.get_child(0).get_child(0))
				else:
					inv[id] = {"Name":"air", "Count":0}
					if id < hb_size:
						hotbar.get_child(held_item[3]).get_child(0).queue_free()					
					elif id < inv_size:
						inventory.get_child(held_item[3] - hb_size).get_child(0).queue_free()
					elif id < inv_size + 3:
						toolbar.get_child(held_item[3] - inv_size).get_child(0).queue_free()
					elif id < inv_size + 6:
						craftbar.get_child(held_item[3] - inv_size - 3).get_child(0).queue_free()	
			else:
				if slot.get_parent().name == "result":
					if held_item[0] == slot.get_child(0).name && held_item[1] < items[held_item[0]]["stack"] && items[held_item[0]]["stack"] >= held_item[1] + crafts[current_craft][1]:
						held_item[1] += crafts[current_craft][1]
						hold()
						remove_items_crafting(current_craft)
				else:
					if slot.get_child_count() == 0:
						if !(items[held_item[0]]["type"] != "tool" && (id < inv_size + 3 && id > inv_size - 1)):
							is_holdin_an_item = false
							inv[id] = {"Name":held_item[0], "Count":held_item[1]}
							inv_set_item(id, held_item[0], held_item[1])
							held.hide()
					elif slot.get_child(0).name == held_item[0]:
						if held_item[1] <= items[held_item[0]]["stack"] - inv[id]["Count"]:
							inv[id]["Count"] += held_item[1]
							held.hide()
							is_holdin_an_item = false
						else:
							held_item[1] -= items[held_item[0]]["stack"] - inv[id]["Count"]
							inv[id]["Count"] = items[held_item[0]]["stack"]
							hold()
						if inv[id]["Count"] > 1:
							slot.get_child(0).get_node("Label").text = str(inv[id]["Count"])
						else:
							slot.get_child(0).get_node("Label").text = ""
					elif slot.get_child(0).name != held_item[0]:
						if !(items[held_item[0]]["type"] != "tool" && (id < inv_size + 3 && id > inv_size - 1)):
							var c = held_item
							held_item = [inv[id]["Name"], inv[id]["Count"], slot.get_child(0).get_meta("nbt"), id, slot]
							hold()
							inv[id] = {"Name":c[0], "Count":c[1]}
							slot.get_child(0).name = c[0]
							slot.get_child(0).set_texture(items[c[0]]["texture"])
							if c[1] > 1:
								slot.get_child(0).get_node("Label").text = str(c[1])
							else:
								slot.get_child(0).get_node("Label").text = ""
			craft_search()

func craft_search():
	var tool_count = 0
	var craft_count = 0
	var no_craft = true
	for i in inv.slice(inv_size, inv_size + 3):
		if i["Name"] != "air":
			tool_count += 1
	for i in inv.slice(inv_size + 3, inv_size + 6):
		if i["Name"] != "air":
			craft_count += 1
	for craft in crafts:
		if craft_count == len(craft[3]) && tool_count == len(craft[2]):
			var tools_to_craft = craft[2].duplicate()
			var items_to_craft = craft[3].duplicate()
			for i in inv.slice(inv_size, inv_size + 3):
				if tools_to_craft.find(i["Name"]) == 0:
					tools_to_craft.erase(i["Name"])
			for i in inv.slice(inv_size + 3, inv_size + 6):
				if items_to_craft.get(i["Name"]) != null && i["Count"] >= items_to_craft.get(i["Name"]):
					items_to_craft.erase(i["Name"])
			if items_to_craft == {} && tools_to_craft == []:
				no_craft = false
				if result_slot.get_child(0).get_child_count() == 0:
					render_result(craft[0], craft[1])
					current_craft = crafts.find(craft)
					print("craft: " + craft[0])
	if no_craft:
		if result_slot.get_child(0).get_child_count() != 0:
			result_slot.get_child(0).get_child(0).queue_free()

func remove_items_crafting(craft):
	for i in inv.slice(inv_size + 3, inv_size + 6):
		for cr in crafts[craft][3].keys():
			if i["Name"] == cr:
				i["Count"] -= crafts[craft][3][cr]
				if i["Count"] < 1:
					i["Name"] = "air"
	for i in range(inv_size + 3, inv_size + 6):
		render_slot(i)

func render_slot(id):
	var slot
	if id < hb_size:
		slot = hotbar.get_child(id)
	elif id < inv_size:
		slot = inventory.get_child(id - hb_size)
	elif id < inv_size + 3:
		slot = toolbar.get_child(id - inv_size)
	elif id < inv_size + 6:
		slot = craftbar.get_child(id - inv_size - 3)
	if slot.get_child_count() == 0 && inv[id]["Name"] != "air":
		inv_set_item(id, inv[id]["Name"], inv[id]["Count"])
	elif slot.get_child_count() != 0 && inv[id]["Name"] == "air":
		slot.remove_child(slot.get_child(0))
	elif slot.get_child_count() != 0 && inv[id]["Name"] != "air":
		slot.get_child(0).set_texture(items[inv[id]["Name"]]["texture"])
		if inv[id]["Count"] != 1:
			slot.get_child(0).get_node("Label").text = str(inv[id]["Count"])
		else:
			slot.get_child(0).get_node("Label").text = ""

func render_result(nam, count):
	var result_item = item_inv.instantiate()
	result_slot.get_child(0).add_child(result_item)
	result_slot.get_child(0).get_child(0).set_texture(items[nam]["texture"])
	result_item.name = nam
	if count > 1:
		result_item.get_node("Label").text = str(count)
	else:
		result_item.get_node("Label").text = ""

func render_hb():
	for i in hotbar.get_children():
		if i.get_index() == selected_slot:
			i.set_texture(hb_select)
		else:
			i.set_texture(hb_unselected)


func spawn_item(x, y, nam):
	var new_item = item.instantiate()
	$/root/Node2D/Items.add_child(new_item)
	new_item.position = Vector2(x, y)
	new_item.get_node("Sprite").set_texture(items[nam]["texture"])
	new_item.set_meta("item_type", nam)
	
	
func damage(amount, _type):
	health -= amount
	var dif = health_bar.value - health
	while health_bar.value > health:
		await get_tree().process_frame
		health_bar.value -= get_process_delta_time() * 15 * dif
	health_bar.value = health
	
	
func eat(amount):
	food += amount
	var dif = food_bar.value - food
	if amount < 0:
		while food_bar.value > food:
			await get_tree().process_frame
			food_bar.value -= get_process_delta_time() * 15
	else:
		while food_bar.value < food:
			await get_tree().process_frame
			food_bar.value += get_process_delta_time() * 15
	food_bar.value = food


func _on_nothin_input_event(_viewport, _event, _shape_idx):
	var item_new = inv[selected_slot]["Name"]
	if (Input.is_action_pressed("attack") && cd <= 0 && (items[item_new]["type"] == "weapon" || items[item_new]["type"] == "tool") && !is_holdin_an_item):
		$attack_timer.start()
		is_attacking = true
		continue_attacking = true
		cd = items[item_new]["cooldown"]


func _on_attack_timer_timeout():
	if is_attacking:
		$attack/CollisionShape2D.disabled = false
		$attack.show()
		is_attacking = false
		$attack_timer.start()
	else:
		$attack.hide()
		$attack/CollisionShape2D.disabled = true

