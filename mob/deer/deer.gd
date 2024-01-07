extends CharacterBody2D

var speed = 1000

var next_pos = [null]

@onready var player = $/root/Node2D/player
@onready var ai = $/root/Node2D/player/Camera2D
@onready var brain = $Brain
@onready var anim = $AnimationPlayer
var is_taking_damage = false

func _ready():
	$"/root/Node2D/player/attack".area_entered.connect(_connect)
	set_meta("next_pos", [null])


func _connect(area):
	var body = area.get_owner()
	if body == self:
		anim.speed_scale = 1
		self.is_taking_damage = true
		if body.get_meta("health") > 0:
			body.get_node("AnimationPlayer").play("damage")
			body.set_meta("health", body.get_meta("health") - player.items[player.inv[player.selected_slot]["Name"]]["damage"])
		else:
			body.get_node("AnimationPlayer").play("death")


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "death":
		self.queue_free()
		for i in get_meta("drop"):
			for j in range(randi_range(i[1], i[2])):
				player.spawn_item(global_position.x, global_position.y, i[0])
	if anim_name == "damage":
		is_taking_damage = false
		anim.speed_scale = speed * 0.001
				
func _physics_process(delta):
	var next_pos = self.get_meta("next_pos")
	if next_pos[0] != null:
		var move_to = position.move_toward(Vector2(next_pos[0][0], next_pos[0][1]), delta * speed)
		var move_dir = move_to - position
		var angle = move_dir.angle()
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
	brain.wait_time = randf_range(3, 7)
	var np = ai.path([floor(global_position.x), floor(global_position.y)], [floor(global_position.x) +  randi_range(-480, 480), floor(global_position.y) + randi_range(-480, 480)])
	self.set_meta("next_pos", np)
