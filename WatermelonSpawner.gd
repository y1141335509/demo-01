extends Node2D

var game_manager: Node
var spawn_timer: Timer
var is_spawning: bool = false

func _ready():
	print("西瓜生成器就绪")
	
	# 获取GameManager引用
	game_manager = get_node("../GameManager")
	if not game_manager:
		print("错误: 找不到GameManager")
		return
	
	# 创建定时器
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0
	spawn_timer.timeout.connect(_on_timer_timeout)
	add_child(spawn_timer)

func start_spawning():
	is_spawning = true
	spawn_timer.start()

func stop_spawning():
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
	watermelon.gravity_scale = 0.8
	watermelon.mass = 1.0
	watermelon.linear_damp = 0.1
	
	# 设置位置
	var from_left = randf() > 0.5
	var spawn_x: float
	var spawn_y: float = 400
	
	if from_left:
		spawn_x = -50
	else:
		spawn_x = 850
	
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
	
	# 直接设置必要的属性和信号
	watermelon.add_to_group("cuttable")
	print("动态西瓜已加入 cuttable 组")
	
	# 添加自定义信号
	watermelon.add_user_signal("sliced", [
		{"name": "hunger", "type": TYPE_INT},
		{"name": "sugar", "type": TYPE_INT}
	])
	
	# 设置西瓜属性
	watermelon.set_meta("cuttable", true)
	watermelon.set_meta("is_sliced", false)
	watermelon.set_meta("hunger_value", 10)
	watermelon.set_meta("sugar_value", 15)
	watermelon.set_meta("spawn_time", Time.get_time_dict_from_system())
	
	# 添加slice方法到西瓜
	var slice_callable = _slice_dynamic_watermelon.bind(watermelon)
	watermelon.set_meta("slice_method", slice_callable)
	
	# 添加定时器来处理生命周期
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = 15.0  # 15秒后自动销毁
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(watermelon.queue_free)
	watermelon.add_child(lifetime_timer)
	lifetime_timer.start()
	
	# 添加边界检查定时器
	var boundary_timer = Timer.new()
	boundary_timer.wait_time = 0.5  # 每0.5秒检查一次
	boundary_timer.timeout.connect(_check_watermelon_boundary.bind(watermelon))
	watermelon.add_child(boundary_timer)
	boundary_timer.start()
	
	# 添加到场景
	get_parent().add_child(watermelon)
	
	# 连接信号
	var connection_result = watermelon.connect("sliced", Callable(game_manager, "on_watermelon_sliced"))
	if connection_result == OK:
		print("✅ 动态西瓜信号连接成功")
	else:
		print("❌ 动态西瓜信号连接失败")
	
	# 计算抛射速度
	var launch_velocity: Vector2
	
	if from_left:
		launch_velocity = Vector2(randf_range(200, 300), randf_range(-500, -300))
	else:
		launch_velocity = Vector2(randf_range(-300, -200), randf_range(-500, -300))
	
	watermelon.linear_velocity = launch_velocity

func _check_watermelon_boundary(watermelon: RigidBody2D):
	# 检查西瓜是否离开屏幕
	if not is_instance_valid(watermelon):
		return
	
	if watermelon.position.y > 700 or watermelon.position.x < -100 or watermelon.position.x > 900:
		watermelon.queue_free()

func _slice_dynamic_watermelon(watermelon: RigidBody2D):
	if not is_instance_valid(watermelon):
		return
	
	var cuttable = watermelon.get_meta("cuttable", true)
	var is_sliced = watermelon.get_meta("is_sliced", false)
	
	if not cuttable or is_sliced:
		return
	
	print("🍉 动态西瓜被切!")
	
	watermelon.set_meta("cuttable", false)
	watermelon.set_meta("is_sliced", true)
	
	# 从 cuttable 组中移除
	watermelon.remove_from_group("cuttable")
	
	# 禁用碰撞
	var collision_shapes = watermelon.get_children().filter(func(node): return node is CollisionShape2D)
	for collision_node in collision_shapes:
		collision_node.set_deferred("disabled", true)
	
	# 发送信号
	var hunger_value = watermelon.get_meta("hunger_value", 10)
	var sugar_value = watermelon.get_meta("sugar_value", 15)
	watermelon.emit_signal("sliced", hunger_value, sugar_value)
	
	# 隐藏西瓜
	watermelon.visible = false
	
	# 1秒后删除
	get_tree().create_timer(1.0).timeout.connect(watermelon.queue_free)
