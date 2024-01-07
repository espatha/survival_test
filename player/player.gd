extends CharacterBody2D

var SPEED
var normal_speed = 50000
var swim_speed = normal_speed / 2
var inv_size = 12
var hb_size = 4
var starve_mult = 1
@onready var item_inv = preload("res://items/item_inv.tscn")
@onready var inventory = $/root/Node2D/CanvasLayer/IngameUI/inv
@onready var hb_select = preload("res://gui/hb_select.png")
@onready var hb_unselected = preload("res://gui/hotbar.png")
@onready var hotbar = $/root/Node2D/CanvasLayer/IngameUI/hotbar2
@onready var world = $".."
@onready var toolbar = $"../CanvasLayer/IngameUI/tools"
@onready var craftbar = $"../CanvasLayer/IngameUI/craft"
@onready var result_slot = $"../CanvasLayer/IngameUI/result"
@onready var health_bar = $"../CanvasLayer/VBoxContainer/hp"
@onready var food_bar = $"../CanvasLayer/VBoxContainer/hp2"
@onready var death_msg = $"../CanvasLayer/death"
@onready var cursor = $"../cursor"
@onready var camera = $Camera2D
var default_player = preload("res://player/player.png")
var player_swiming = preload("res://player/player_swim.png")
var items = {"air":{"texture":preload("res://items/air.png"), "type":"weapon", "cooldown":0.3, "damage":1, "player_texture":preload("res://player/void.png"), "stack":1, "anim":preload("res://player/player_fist.png")},
"iron_axe":{"texture":preload("res://items/iron_axe.png"), "type":"tool", "tool":"axe", "cooldown":0.4, "damage":10, "player_texture":preload("res://player/iron_axe.png"), "stack":1, "anim":default_player},
"stone_axe":{"texture":preload("res://items/stone_axe.png"), "type":"tool", "tool":"axe", "cooldown":0.6, "damage":4, "player_texture":preload("res://player/stone_axe.png"), "stack":1, "anim":default_player},
"wood":{"texture":preload("res://items/wood.png"), "type":"build", "stack":50, "damage":1, "build":preload("res://objects/tscn/log_wall.tscn"), "preview":preload("res://builds/sprites/log_wall.png"), "offset":-2, "fuel":400},
"rock":{"texture":preload("res://items/rock.png"), "type":"resource", "stack":25, "damage":1},
"stick":{"texture":preload("res://items/stick.png"), "type":"resource", "stack":50, "damage":1, "fuel":100},
"berries":{"texture":preload("res://items/berries.png"), "type":"food", "sat":1, "stack":50, "damage":1},
"meat":{"texture":preload("res://items/meat.png"), "type":"food", "sat":2, "stack":20, "damage":1},
"stake":{"texture":preload("res://items/steak.png"), "type":"food", "sat":10, "stack":20, "damage":1},
"bone":{"texture":preload("res://items/bone.png"), "type":"resourse", "stack":25, "damage":3},
"campfire":{"texture":preload("res://builds/sprites/campfire.png"), "type":"build", "stack":10, "damage":1, "build":preload("res://builds/tscn/campfire.tscn"), "preview":preload("res://builds/sprites/campfire.png"), "offset":0, "fuel":800},
}
var item = preload("res://scenes/item.tscn")
@onready var held = $"../CanvasLayer/IngameUI/held_item"
@onready var held_label = $"../CanvasLayer/IngameUI/held_item/Label"
var crafts = [
["stone_axe", 1, [], {"stick":1, "rock":1}],
["campfire", 1, [], {"stick":10}]
]

var input = Vector2.ZERO
var is_moving = false
var is_holdin_an_item = false
var held_item = ["name", 0, {}, 0, 0]
var inv = []
var inv_open = false
var continue_attacking = false
var selected_slot = 0
var dead = false
var is_swimming = false
var can_build = false
var cd : float
var def_cd = 0.5
var is_attacking = false

var direction = Vector2.from_angle(90)
var build_pos
var direction_status = 0
var current_craft = -1
var health = 20
var food = 40.0

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
	
	
	if !dead:
	#print($"/root/Node2D".getblock(position.x, position.y))
		
		is_swimming = world.getblock(position.x, position.y) == 0
		
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
			
		SPEED = normal_speed
		if items[inv[selected_slot]["Name"]]["type"] == "tool" || items[inv[selected_slot]["Name"]]["type"] == "weapon":
			$Item.show()
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
			$Item.hide()
			$Sprite.set_texture(default_player)
		if is_swimming:
			$Item.hide()
			$Sprite.set_texture(player_swiming)
			SPEED = swim_speed
		
		$Item.frame = sprite.frame
		
		velocity = input * SPEED * delta
		
		if input != Vector2.ZERO:
			direction = -input
		$attack.rotation = direction.angle()
		
		if (Input.is_action_pressed("attack") && !is_swimming && items[inv[selected_slot]["Name"]]["type"] != "build"):
			if (cd <= 0 && (continue_attacking || is_attacking)):
				is_attacking = true
				if items[inv[selected_slot]["Name"]]["type"] == "tool" || items[inv[selected_slot]["Name"]]["type"] == "weapon":
					cd = items[inv[selected_slot]["Name"]]["cooldown"]
				else:
					cd = def_cd
				$attack_timer.start()
		else:
			continue_attacking = false
		build_pos = floor(get_global_mouse_position() / 80 + Vector2(0.5, 0.5)) * 80 + Vector2(0.5, 0.5)
		cursor.position = build_pos
		held.position = get_local_mouse_position() / 2 + get_viewport().get_visible_rect().size / 2 - Vector2(30, 30)
		
		if world.getblock(build_pos.x, build_pos.y) == 0 || cursor.get_node("Area2D").has_overlapping_bodies():
			cursor.modulate = Color(1, 0, 0, 0.7)
			can_build = false
		else:
			cursor.modulate = Color(0.2, 1, 0.2, 0.8)
			can_build = true
		if items[inv[selected_slot]["Name"]]["type"] == "build":
			cursor.show()
			cursor.set_texture(items[inv[selected_slot]["Name"]]["preview"])
			cursor.offset.y = items[inv[selected_slot]["Name"]]["offset"]
		else:
			cursor.hide()
		move_and_slide()
		

func hold():
	if held_item[1] < 1:
		held_item[0] = "air"
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
		var id = slot.get_index()
		if slot.get_parent().name == "inv":
			id += hb_size
		elif slot.get_parent().name == "tools":
			id += inv_size
		elif slot.get_parent().name == "craft":
			id += inv_size + 3
		elif slot.get_parent().name == "result":
			id = -1
		if event.is_action_pressed("use_inv"):
			if inv[id]["Name"] == "air":
				if is_holdin_an_item:
					inv_set_item(id, held_item[0], 1)
					inv[id]["Name"] = held_item[0]
					inv[id]["Count"] = 1				
					held_item[1] -= 1
					if held_item[1] < 1:
						held_item = ["air", 0, 0, 0, 0]
						is_holdin_an_item = false
					hold()
					render_slot(id)
			else:
				if items[inv[id]["Name"]]["type"] == "food" && food < 39:
					eat(items[inv[id]["Name"]]["sat"])
					inv[id]["Count"] -= 1
					if inv[id]["Count"] < 1:
						inv[id]["Name"] = "air"
					render_slot(id)
				else:
					if !is_holdin_an_item:
						var half = (inv[id]["Count"] / 2)
						held_item = [inv[id]["Name"], inv[id]["Count"] - half, 0, 0, 0]
						is_holdin_an_item = true
						hold()
						inv[id]["Count"] = half
						render_slot(id)
					elif inv[id]["Name"] == held_item[0] && items[inv[id]["Name"]]["stack"] > inv[id]["Count"]:
						held_item[1] -= 1
						hold()
						inv[id]["Count"] += 1
						render_slot(id)
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
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
					if slot.get_child_count() != 0 && held_item[0] == slot.get_child(0).name && held_item[1] < items[held_item[0]]["stack"] && items[held_item[0]]["stack"] >= held_item[1] + crafts[current_craft][1]:
						held_item[1] += crafts[current_craft][1]
						hold()
						remove_items_crafting(current_craft)
				else:
					if slot.get_child_count() == 0:
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
						if !((id < inv_size + 3 && id > inv_size - 1)):
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
	if inv[id]["Count"] < 1:
		inv[id]["Name"] = "air"
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
	new_item.set_meta("move", Vector2(randf_range(-100, 100), randf_range(-100, 100)))
	
	
func damage(amount, _type):
	health -= amount
	if health < 1:
		health_bar.value = health
		death()
	var dif = health_bar.value - health
	while health_bar.value > health:
		await get_tree().process_frame
		health_bar.value -= get_process_delta_time() * 15 * dif
	health_bar.value = health

	
func heal(amount):
	health += amount
	var dif = -health_bar.value + health
	while health_bar.value < health:
		await get_tree().process_frame
		health_bar.value += get_process_delta_time() * 15 * dif
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
	if food > 40:
		food = 40

func death():
	$CollisionShape2D.disabled = true
	health_bar.value = health
	health = 20
	death_msg.show()
	$AnimationPlayer.play("death")
	dead = true
	$"../CanvasLayer/ColorRect".show()

func _on_nothin_input_event(_viewport, _event, _shape_idx):
	var item_new = inv[selected_slot]["Name"]
	var chunk_coo = camera.chunk_coords(cursor.global_position.x, cursor.global_position.y)
	if cd <= 0 && Input.is_action_pressed("attack") && !is_swimming && items[inv[selected_slot]["Name"]]["type"] != "build":
		if !is_holdin_an_item:
			$attack_timer.start()
			is_attacking = true
			if items[item_new]["type"] == "tool" || items[item_new]["type"] == "weapon":
				cd = items[item_new]["cooldown"]
			else:
				cd = def_cd
		continue_attacking = true
	if can_build && items[inv[selected_slot]["Name"]]["type"] == "build" && Input.is_action_pressed("attack") && world.chunks[world.get_chunk(build_pos[0], build_pos[1])]["Objects"][int(build_pos[1] / 80) % 16][int(build_pos[0] / 80) % 16][0] == null:
		var build = items[inv[selected_slot]["Name"]]["build"].instantiate()
		for chunk in world.get_node("Grass").get_children():
			if chunk.name == str(chunk_coo[0]) + "; " + str(chunk_coo[1]):
				chunk.get_node("Items").add_child(build)
				inv[selected_slot]["Count"] -= 1
				if inv[selected_slot]["Count"] < 1:
					inv[selected_slot]["Name"] = "air"
				render_slot(selected_slot)
				world.chunks[world.get_chunk(build_pos[0], build_pos[1])]["Objects"][int(build_pos[1] / 80) % 16][int(build_pos[0] / 80) % 16][0] = inv[selected_slot]["Name"]
		for i in cursor.get_node("Area2D").get_overlapping_areas():
			if i.get_owner().has_meta("type") && floor(i.get_owner().global_position.x) == floor(cursor.global_position.x) && floor(i.get_owner().global_position.y) == floor(cursor.global_position.y):
				i.get_owner().queue_free()
		build.global_position = build_pos
	

func _on_attack_timer_timeout():
	if is_attacking:
		$attack/CollisionShape2D.disabled = false
		$attack.show()
		is_attacking = false
		$attack_timer.start()
	else:
		$attack.hide()
		$attack/CollisionShape2D.disabled = true



func _on_starvation_timeout():
	if !dead:
		eat(-1 * starve_mult)
		if food <= 0:
			damage(1, "starve")
			food = 0
		elif food > 35:
			heal(1)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		death_msg.hide()
		$"../CanvasLayer/ColorRect".hide()
		health_bar.value = health
		food = 20
		food_bar.value = 20
		for i in range(len(inv)):
			if inv[i]["Name"] != "air" && inv[i]["Count"] > 0:
				for j in range(inv[i]["Count"]):
					spawn_item(position.x, position.y, inv[i]["Name"])
			inv[i]["Name"] = "air"
			inv[i]["Count"] = 0
			render_slot(i)
		position = Vector2.ZERO
		dead = false
		await get_tree().process_frame
		$CollisionShape2D.disabled = false
