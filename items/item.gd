extends StaticBody2D

func _ready():
	$Area2D.area_entered.connect(col.bind($"/root/Node2D/player"))

func col(area):
	print(area.name)
	if area.is_in_group("items"):
		print("yo mam")
		
