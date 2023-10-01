extends CharacterBody2D

var input = Vector2.ZERO
var is_moving = false
const SPEED = 20.0 * 1000
var inv_size = 12
@onready var inventory = $/root/Node2D/CanvasLayer/IngameUI/inv
@onready var inventory_text = $/root/Node2D/CanvasLayer/IngameUI/inv2
@onready var hb_texture = $/root/Node2D/CanvasLayer/IngameUI/hotbar2
@onready var hb_select = preload("res://gui/hb_select.png")
@onready var hb_unselected = preload("res://gui/hotbar.png")
@onready var hotbar = $/root/Node2D/CanvasLayer/IngameUI/hotbar
var items = {"air":{"texture":preload("res://items/air.png"), "type":"void", "damage":0},
"iron_axe":{"texture":preload("res://items/iron_axe.png"), "type":"tool", "tool":"axe", "cooldown":0.3, "damage":10, "player_texture":preload("res://player/iron_axe.png")},
"wood":{"texture":preload("res://items/wood.png"), "type":"resource"}}
var item = preload("res://scenes/item.tscn")

var inv = []
var inv_open = false
var continue_attacking = false
var selected_slot = 0

var direction = Vector2.from_angle(90)
var is_attacking = false
var cd : float
var direction_status = 0

@onready var sprite = get_node("Sprite")

func _ready():
	for i in range(inv_size):
		inv.append({"Name":"air",
					"Count":0})


func get_input():
	input.x = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	input.y = int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	
	return input.normalized()

func _physics_process(delta):
	
	cd -= delta 
	if cd < 0:
		cd = 0
	input = get_input()

# inventory and hotbar

	if Input.is_action_just_pressed("inventory_open"):
		inv_open = !inv_open
	if inv_open:
		inventory.show()
		inventory_text.show()
	else:
		inventory.hide()
		inventory_text.hide()
	
	if Input.is_action_just_pressed("hb_selection_down"):
		selected_slot += 1
		if selected_slot > 3:
			selected_slot = 0
		render_hotbar()
			
	if Input.is_action_just_pressed("hb_selection_up"):
		selected_slot -= 1
		if selected_slot < 0:
			selected_slot = 3
		render_hotbar()
	
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
	if items[inv[selected_slot]["Name"]]["type"] == "tool":
		if is_attacking:
			$AnimationPlayer.stop()
			sprite.frame = direction_status * 5 + 20
		var current_cd = items[inv[selected_slot]["Name"]]["cooldown"]
		if 0.1 > current_cd - cd && current_cd - cd <= 0.15:
			sprite.frame = direction_status	* 5 + 21
		elif 0.15 > current_cd - cd && current_cd - cd <= 0.2:
			sprite.frame = direction_status	* 5 + 22
		$Item.set_texture(items[inv[selected_slot]["Name"]]["player_texture"])
	
	$Item.frame = sprite.frame
	
	velocity = input * SPEED * delta
	
	if input != Vector2.ZERO:
		direction = -input
	$attack.rotation = direction.angle()
	
	if (Input.is_action_pressed("attack") && (items[inv[selected_slot]["Name"]]["type"] == "cold_weapon" || items[inv[selected_slot]["Name"]]["type"] == "tool")):
		if (cd <= 0 && continue_attacking):
			is_attacking = true
			cd = items[inv[selected_slot]["Name"]]["cooldown"]
			$attack_timer.start()
	else:
		continue_attacking = false
	move_and_slide()
	
func can_add_item(nam, count):
	for i in range(inv_size):
		if inv[i].Name == nam:
			return true
		elif inv[i].Name == "air":
			return true
	return false

func add_item(nam, count):
	for i in range(inv_size):
		if inv[i].Name == nam:
			inv[i].Count += count
			inv_render()
			return
		elif inv[i].Name == "air":
			inv[i].Name = nam
			inv[i].Count = count
			inv_render()
			return

func inv_render():
	for i in range(4):
		var tex = items[inv[i]["Name"]]["texture"]
		inv_part_render(hotbar, i, tex)
	for i in range(4, inv_size):
		var tex = items[inv[i]["Name"]]["texture"]
		inv_part_render(inventory, i, tex)

func inv_part_render(part, i, tex):
	var slot = part.get_node("slot" + str(i + 1))
	slot.set_texture(tex)
	var count = inv[i]["Count"]
	if count > 1:
		slot.get_node("Label").text = str(count)
	else:
		slot.get_node("Label").text = " "

func render_hotbar():
	for i in hb_texture.get_children():
		if i.name == "slot" + str(selected_slot + 1):
			i.set_texture(hb_select)
		else:
			i.set_texture(hb_unselected)


func spawn_item(x, y, name):
	var new_item = item.instantiate()
	$/root/Node2D/Items.add_child(new_item)
	new_item.position = Vector2(x, y)
	new_item.get_node("Sprite").set_texture(items[name]["texture"])
	new_item.set_meta("item_type", name)


func _on_nothin_input_event(_viewport, _event, _shape_idx):
	var item = inv[selected_slot]["Name"]
	if (Input.is_action_pressed("attack") && cd <= 0 && (items[item]["type"] == "cold_weapon" || items[item]["type"] == "tool")):
		$attack_timer.start()
		is_attacking = true
		continue_attacking = true
		cd = items[item]["cooldown"]



func _on_attack_timer_timeout():
	if is_attacking:
		$attack.show()
		$attack/CollisionShape2D.disabled = false
		is_attacking = false
		$attack_timer.start()
	else:
		$attack.hide()
		$attack/CollisionShape2D.disabled = true
