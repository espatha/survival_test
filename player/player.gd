extends CharacterBody2D

var input = Vector2.ZERO
var is_moving = false
const SPEED = 20.0 * 1000

@onready var sprite = get_node("Sprite")

func get_input():
	input.x = int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
	input.y = int(Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_W))
	
	return input.normalized()

func _physics_process(delta):
	
	input = get_input()

#animation for good
	if input.x < 0:
		$AnimationPlayer.play("walk_left")
	elif input.x > 0:
		$AnimationPlayer.play("walk_right")
	elif input.y == 1:
		$AnimationPlayer.play("walk_up")
	elif input.y == -1:
		$AnimationPlayer.play("walk_down")
	else:
		$AnimationPlayer.stop(false)
		sprite.frame = 0
	
	
	velocity = input * SPEED * delta
	
	move_and_slide()
	
		
