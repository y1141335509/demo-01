extends Node2D

@export var watermelon_scene: PackedScene
@onready var game_manager := $"../GameManager"

func _on_Timer_timeout():
	var wm = watermelon_scene.instantiate()
	wm.game_manager = game_manager
	wm.position = Vector2(randf_range(100, 700), 600)
	wm.linear_velocity = Vector2(randf_range(-100, 100), randf_range(-600, -400))
	
	# 连接信号 sliced -> GameManager.update_stats
	wm.connect("sliced", Callable(game_manager, "update_stats"))

	add_child(wm)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
