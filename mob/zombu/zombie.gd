extends CharacterBody2D

var speed = 500

var next_pos = [null]

@onready var player = $/root/Node2D/player
@onready var ai = $/root/Node2D/player/Camera2D
@onready var brain = $Brain
@onready var anim = $AnimationPlayer
@onready var anim2 = $damage_player
@onready var attack = $attack
@onready var col = $attack/CollisionShape2D2
var is_taking_damage = false

func _ready():
	$"/root/Node2D/player/attack".area_entered.connect(_connect)
	set_meta("next_pos", [null])


func _connect(area):
	var body = area.get_owner()
	if body == self:
		self.is_taking_damage = true
		if body.get_meta("health") > 0:
			body.get_node("damage_player").play("damage")
			body.set_meta("health", body.get_meta("health") - player.items[player.inv[player.selected_slot]["Name"]]["damage"])
			knokback((-player.global_position + body.global_position).normalized().angle(), 10, 50)
		else:
			body.get_node("damage_player").play("death")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		self.queue_free()
		for i in get_meta("drop"):
			for j in range(randi_range(i[1], i[2])):
				player.spawn_item(global_position.x, global_position.y, i[0])
	if anim_name == "damage":
		self.is_taking_damage = false
				
func _physics_process(delta):
	
	if player.global_position.distance_to(self.global_position) > 3000:
		self.queue_free()
	
	var next_pos = self.get_meta("next_pos")
	if next_pos[0] != null:
		var move_to = position.move_toward(Vector2(next_pos[0][0], next_pos[0][1]), delta * speed)
		var move_dir = move_to - position
		var angle = move_dir.angle()
		attack.rotation = angle
		if !self.is_taking_damage:
			if move_dir.x == 0 and move_dir.y == 0:
				anim.stop()
			elif angle > PI / 3 and angle < 2 * PI / 3:
				anim.play("run_down")
			elif angle > - 2 * PI / 3 and angle < - PI / 3:
				anim.play("run_up")
			elif angle >= 2 * PI / 3 or angle <= -2 * PI / 3:
				anim.play("run_left")
			elif angle >= - PI / 3 and angle <= PI / 3:
				anim.play("run_right")
			position = move_to
	else:
		anim.stop()
	move_and_slide()


func _on_brain_timeout():
	brain.wait_time = randf_range(0.1, 0.5)
	var np = ai.path([floor(global_position.x), floor(global_position.y)], [floor(player.global_position.x), floor(player.global_position.y)])
	self.set_meta("next_pos", np)


func _on_attack_speed_timeout():
	col.disabled = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	col.disabled = true


func _on_attack_body_entered(body):
	if body.name == "player":
		body.damage(1, "mob", attack.rotation)
		

func knokback(dir, time, mult):
	for i in range(2, time):
		var move = Vector2.RIGHT.rotated(dir) * mult * (1/float(i))
		position += move
		await get_tree().process_frame
