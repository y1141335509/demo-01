extends Node2D

@export var watermelon_scene: PackedScene
@onready var game_manager := $"../GameManager"

func _on_timer_timeout():
	print("Timer触发，尝试生成西瓜...")
	
	if watermelon_scene == null:
		print("错误：Watermelon scene 未设置！")
		return
		
	var wm = watermelon_scene.instantiate()
	
	# 获取屏幕尺寸
	var screen_size = get_viewport().get_visible_rect().size
	print("屏幕尺寸：", screen_size)
	
	# 从屏幕底部随机位置生成
	var spawn_x = randf_range(50, screen_size.x - 50)
	var spawn_y = screen_size.y + 50
	wm.position = Vector2(spawn_x, spawn_y)
	
	print("西瓜生成位置：", wm.position)
	
	# 设置向上的初始速度
	var velocity_x = randf_range(-150, 150)
	var velocity_y = randf_range(-800, -500)
	wm.linear_velocity = Vector2(velocity_x, velocity_y)
	
	# 连接信号
	if game_manager != null:
		wm.connect("sliced", Callable(game_manager, "update_stats"))
		print("信号连接成功")
	
	add_child(wm)
	print("西瓜添加到场景")

func _ready():
	print("WatermelonSpawner初始化...")
	if has_node("Timer"):
		$Timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		$Timer.wait_time = 2.0
		$Timer.start()
		print("Timer启动成功")
	else:
		print("错误：找不到Timer子节点！")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
