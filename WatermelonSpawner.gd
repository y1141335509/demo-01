extends Node2D

var game_manager: Node
var spawn_timer: Timer
var is_spawning: bool = false

func _ready():
	print("WatermelonSpawner ready")
	
	# 获取GameManager引用
	game_manager = get_node("../GameManager")
	if not game_manager:
		print("Error: Cannot find GameManager")
		return
	
	# 创建定时器
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0
	spawn_timer.timeout.connect(_on_timer_timeout)
	add_child(spawn_timer)
	
	print("WatermelonSpawner initialized successfully")

func start_spawning():
	print("Starting watermelon spawning")
	is_spawning = true
	spawn_timer.start()

func stop_spawning():
	print("Stopping watermelon spawning")
	is_spawning = false
	spawn_timer.stop()

func _on_timer_timeout():
	if is_spawning:
		spawn_watermelon()

func spawn_watermelon():
	# 创建西瓜根节点
	var watermelon = RigidBody2D.new()
	watermelon.name = "Watermelon"
	
	# 设置物理属性
	watermelon.gravity_scale = 0.8  # 适中的重力
	watermelon.mass = 1.0
	watermelon.linear_damp = 0.1  # 少量空气阻力
	
	# 从屏幕底部开始，但给一个向上的初始速度让它能到达屏幕中央
	var from_left = randf() > 0.5
	var spawn_x: float
	var spawn_y: float = 400  # 调整这个值：400=屏幕中央，300=偏上，500=偏下
	
	if from_left:
		spawn_x = -50  # 调整这个值让西瓜从更左边开始：-100=更远，0=屏幕边缘
	else:
		spawn_x = 850  # 调整这个值：900=更远，800=屏幕右边缘
	
	watermelon.position = Vector2(spawn_x, spawn_y)
	
	# 添加视觉组件
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	image.fill(Color.GREEN)
	texture.set_image(image)
	sprite.texture = texture
	watermelon.add_child(sprite)
	
	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 32
	collision.shape = shape
	watermelon.add_child(collision)
	
	# 添加边界检测器（用于销毁屏幕外的西瓜）
	var boundary_checker = Area2D.new()
	boundary_checker.name = "BoundaryChecker"
	var boundary_collision = CollisionShape2D.new()
	var boundary_shape = CircleShape2D.new()
	boundary_shape.radius = 35
	boundary_collision.shape = boundary_shape
	boundary_checker.add_child(boundary_collision)
	watermelon.add_child(boundary_checker)
	
	# 添加西瓜脚本
	var script = GDScript.new()
	script.source_code = """
extends RigidBody2D

@export var hunger_value := 10
@export var sugar_value := 15

signal sliced(hunger: int, sugar: int)
var cuttable := true
var lifetime := 0.0
var max_lifetime := 10.0  # 10秒后自动销毁

func _ready():
	add_to_group("cuttable")
	print("Watermelon ready at: ", position)

func _process(delta):
	lifetime += delta
	
	# 检查是否超时或离开屏幕
	if lifetime > max_lifetime or position.y > 700 or position.x < -100 or position.x > 900:
		print("Watermelon destroyed (out of bounds or timeout)")
		queue_free()

func slice():
	if not cuttable:
		return 
	cuttable = false
	emit_signal("sliced", hunger_value, sugar_value)
	print("Watermelon sliced! Hunger: +", hunger_value, ", Sugar: +", sugar_value)
	
	# 创建切开的两瓣效果
	create_watermelon_halves()
	
	# 隐藏原始西瓜
	visible = false
	
	# 1秒后清除
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func create_watermelon_halves():
	# 创建左半边
	var left_half = RigidBody2D.new()
	left_half.position = position + Vector2(-20, 0)
	left_half.gravity_scale = 0.5
	
	var left_sprite = Sprite2D.new()
	var left_texture = ImageTexture.new()
	var left_image = Image.create(32, 64, false, Image.FORMAT_RGB8)
	left_image.fill(Color.DARK_GREEN)
	left_texture.set_image(left_image)
	left_sprite.texture = left_texture
	left_half.add_child(left_sprite)
	
	var left_collision = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(32, 64)
	left_collision.shape = left_shape
	left_half.add_child(left_collision)
	
	# 创建右半边
	var right_half = RigidBody2D.new()
	right_half.position = position + Vector2(20, 0)
	right_half.gravity_scale = 0.5
	
	var right_sprite = Sprite2D.new()
	var right_texture = ImageTexture.new()
	var right_image = Image.create(32, 64, false, Image.FORMAT_RGB8)
	right_image.fill(Color.DARK_GREEN)
	right_texture.set_image(right_image)
	right_sprite.texture = right_texture
	right_half.add_child(right_sprite)
	
	var right_collision = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(32, 64)
	right_collision.shape = right_shape
	right_half.add_child(right_collision)
	
	# 添加到场景
	get_parent().add_child(left_half)
	get_parent().add_child(right_half)
	
	# 给两瓣加上分离的速度
	left_half.linear_velocity = Vector2(-100, -50)
	right_half.linear_velocity = Vector2(100, -50)
	
	# 1.5秒后清除两瓣
	var left_timer = Timer.new()
	left_timer.wait_time = 1.5
	left_timer.one_shot = true
	left_timer.timeout.connect(left_half.queue_free)
	left_half.add_child(left_timer)
	left_timer.start()
	
	var right_timer = Timer.new()
	right_timer.wait_time = 1.5
	right_timer.one_shot = true
	right_timer.timeout.connect(right_half.queue_free)
	right_half.add_child(right_timer)
	right_timer.start()
"""
	watermelon.set_script(script)
	
	# 连接信号
	watermelon.connect("sliced", Callable(game_manager, "update_stats"))
	
	# 添加到场景
	get_parent().add_child(watermelon)
	
	# 计算抛射速度 - 确保西瓜能到达屏幕中央区域
	var launch_velocity: Vector2
	
	if from_left:
		# 从左边抛向屏幕中央偏右，向上的速度要足够大
		launch_velocity = Vector2(randf_range(200, 300), randf_range(-500, -300))
	else:
		# 从右边抛向屏幕中央偏左，向上的速度要足够大
		launch_velocity = Vector2(randf_range(-300, -200), randf_range(-500, -300))
	
	watermelon.linear_velocity = launch_velocity
	
	print("Watermelon launched from: ", watermelon.position, " with velocity: ", launch_velocity)
