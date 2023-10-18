extends CharacterBody2D

var speed = 100
var dir : Vector2

@onready var player = $/root/Node2D/player
@onready var nav_agent = $NavigationAgent2D

func _physics_process(_delta):
	dir = self.to_local(nav_agent.get_next_path_position()).normalized()
	print(get_world_2d().get_navigation_map())
	velocity = dir * speed
	move_and_slide()

func _on_timer_timeout():
	nav_agent.target_position = player.global_position
