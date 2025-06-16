extends Node2D

var game_manager: Node
var spawn_timer: Timer
var is_spawning: bool = false

# 四种西瓜类型
enum WatermelonType {
	NORMAL,    # 普通西瓜
	GOLDEN,    # 金色西瓜
	SWEET,     # 甜味西瓜
	MINI,      # 迷你西瓜
	GIANT      # 巨型西瓜
}

# 西瓜图片资源
var watermelon_textures: Dictionary = {}

func _ready():
	print("西瓜生成器就绪")
	
	# 加载西瓜图片资源
	load_watermelon_textures()
	
	game_manager = get_node("../GameManager")
	if not game_manager:
		print("错误: 找不到GameManager")
		return
	
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 2.0
	spawn_timer.timeout.connect(_on_timer_timeout)
	add_child(spawn_timer)

func load_watermelon_textures():
	"""加载西瓜图片资源"""
	print("正在加载西瓜图片资源...")
	
	# 定义图片路径
	var texture_paths = {
		WatermelonType.NORMAL: "res://sprites/watermelons/normal_watermelon_100.png",
		WatermelonType.GOLDEN: "res://sprites/watermelons/golden_watermelon_100.png",
		WatermelonType.SWEET: "res://sprites/watermelons/pink_watermelon_100.png",
		WatermelonType.MINI: "res://sprites/watermelons/mini_watermelon_64.png",
		WatermelonType.GIANT: "res://sprites/watermelons/giant_watermelon_128.png"
	}
	
	# 尝试加载每个图片
	for type in texture_paths:
		var path = texture_paths[type]
		if ResourceLoader.exists(path):
			watermelon_textures[type] = load(path)
			print("✅ 已加载: ", get_watermelon_type_name(type))
		else:
			print("⚠️ 图片不存在: ", path)
			# 创建fallback纹理
			watermelon_textures[type] = create_fallback_texture(type)

func create_fallback_texture(type: WatermelonType) -> ImageTexture:
	"""为缺失的图片创建fallback纹理"""
	var texture = ImageTexture.new()
	var size = get_base_size_for_type(type)
	var color = get_color_for_type(type)
	
	var image = Image.create(int(size), int(size), false, Image.FORMAT_RGB8)
	image.fill(color)
	texture.set_image(image)
	
	print("🔄 为", get_watermelon_type_name(type), "创建了fallback纹理")
	return texture

func get_color_for_type(type: WatermelonType) -> Color:
	"""获取每种西瓜类型的颜色"""
	match type:
		WatermelonType.NORMAL:
			return Color.GREEN
		WatermelonType.GOLDEN:
			return Color.GOLD
		WatermelonType.SWEET:
			return Color.PINK
		WatermelonType.MINI:
			return Color.LIGHT_GREEN
		WatermelonType.GIANT:
			return Color.DARK_GREEN
		_:
			return Color.GREEN

func get_base_size_for_type(type: WatermelonType) -> float:
	"""获取每种西瓜类型的基础大小"""
	match type:
		WatermelonType.NORMAL:
			return 100.0  # 修复：匹配你的实际图片尺寸
		WatermelonType.GOLDEN:
			return 100.0  # 修复：匹配你的实际图片尺寸
		WatermelonType.SWEET:
			return 100.0  # 修复：匹配你的实际图片尺寸
		WatermelonType.MINI:
			return 64.0   # 修复：匹配你的实际图片尺寸
		WatermelonType.GIANT:
			return 128.0  # 大一些
		_:
			return 100.0

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
	var watermelon = RigidBody2D.new()
	watermelon.name = "Watermelon"
	
	watermelon.gravity_scale = 0.8
	watermelon.mass = 1.0
	watermelon.linear_damp = 0.1
	
	var from_left = randf() > 0.5
	var spawn_x: float
	var spawn_y: float = 400
	
	if from_left:
		spawn_x = -50
	else:
		spawn_x = 850
	
	watermelon.position = Vector2(spawn_x, spawn_y)
	
	# 随机选择西瓜类型
	var watermelon_type = get_random_watermelon_type()
	setup_watermelon_by_type(watermelon, watermelon_type)
	
	watermelon.add_to_group("cuttable")
	watermelon.add_to_group("watermelons")
	
	watermelon.add_user_signal("sliced", [
		{"name": "hunger", "type": TYPE_INT},
		{"name": "sugar", "type": TYPE_INT}
	])
	
	watermelon.set_meta("cuttable", true)
	watermelon.set_meta("is_sliced", false)
	watermelon.set_meta("spawn_time", Time.get_time_dict_from_system())
	
	var slice_callable = _slice_dynamic_watermelon.bind(watermelon)
	watermelon.set_meta("slice_method", slice_callable)
	
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = 15.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(watermelon.queue_free)
	watermelon.add_child(lifetime_timer)
	
	var boundary_timer = Timer.new()
	boundary_timer.wait_time = 0.5
	boundary_timer.timeout.connect(_check_watermelon_boundary.bind(watermelon))
	watermelon.add_child(boundary_timer)
	
	get_parent().add_child(watermelon)
	
	lifetime_timer.start()
	boundary_timer.start()
	
	var connection_result = watermelon.connect("sliced", Callable(game_manager, "on_watermelon_sliced"))
	if connection_result == OK:
		print("✅ 动态西瓜信号连接成功")
	else:
		print("❌ 动态西瓜信号连接失败")
	
	var launch_velocity: Vector2
	
	if from_left:
		launch_velocity = Vector2(randf_range(200, 300), randf_range(-500, -300))
	else:
		launch_velocity = Vector2(randf_range(-300, -200), randf_range(-500, -300))
	
	watermelon.linear_velocity = launch_velocity

func get_random_watermelon_type() -> WatermelonType:
	var rand_value = randf()
	
	if rand_value < 0.60:    # 60% 概率
		return WatermelonType.NORMAL
	elif rand_value < 0.80:  # 20% 概率
		return WatermelonType.SWEET
	elif rand_value < 0.90:  # 10% 概率
		return WatermelonType.MINI
	elif rand_value < 0.98:  # 8% 概率
		return WatermelonType.GOLDEN
	else:                    # 2% 概率
		return WatermelonType.GIANT

func setup_watermelon_by_type(watermelon: RigidBody2D, type: WatermelonType):
	var sprite = Sprite2D.new()
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	
	# 获取对应的纹理
	var texture = watermelon_textures.get(type)
	if texture:
		sprite.texture = texture
	else:
		print("❌ 找不到纹理，使用fallback")
		sprite.texture = create_fallback_texture(type)
	
	# 重要修复：根据实际图片尺寸和类型设置碰撞区域
	var collision_radius = 30.0  # 基础碰撞半径
	var sprite_scale = 1.0       # sprite缩放
	
	match type:
		WatermelonType.NORMAL:
			# 普通西瓜：100x100像素
			sprite_scale = 1.0
			collision_radius = 45.0  # 修复：增大碰撞区域，100*0.45=45
			watermelon.set_meta("hunger_value", 10)
			watermelon.set_meta("sugar_value", 15)
			watermelon.mass = 1.0
			
		WatermelonType.GOLDEN:
			# 金色西瓜：100x100像素
			sprite_scale = 1.0
			collision_radius = 45.0  # 修复：增大碰撞区域
			watermelon.set_meta("hunger_value", 25)
			watermelon.set_meta("sugar_value", 5)
			watermelon.mass = 1.2
			
		WatermelonType.SWEET:
			# 甜味西瓜：100x100像素
			sprite_scale = 1.0
			collision_radius = 45.0  # 修复：增大碰撞区域
			watermelon.set_meta("hunger_value", 8)
			watermelon.set_meta("sugar_value", 30)
			watermelon.mass = 1.0
			
		WatermelonType.MINI:
			# 迷你西瓜：64x64像素
			sprite_scale = 1.0
			collision_radius = 28.0  # 修复：64*0.44=28，稍微增大
			watermelon.set_meta("hunger_value", 5)
			watermelon.set_meta("sugar_value", 8)
			watermelon.mass = 0.5
			
		WatermelonType.GIANT:
			# 巨型西瓜：128x128像素
			sprite_scale = 1.0
			collision_radius = 58.0  # 修复：128*0.45=58
			watermelon.set_meta("hunger_value", 35)
			watermelon.set_meta("sugar_value", 40)
			watermelon.mass = 2.0
	
	# 应用sprite设置
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	
	# 设置碰撞形状（圆形适合西瓜）
	shape.radius = collision_radius
	collision.shape = shape
	
	# 添加组件到西瓜
	watermelon.add_child(sprite)
	watermelon.add_child(collision)
	
	# 存储类型信息
	watermelon.set_meta("watermelon_type", type)
	
	print("创建了", get_watermelon_type_name(type), "，sprite缩放:", sprite_scale, "，碰撞半径:", collision_radius)

func _check_watermelon_boundary(watermelon: RigidBody2D):
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
	
	if game_manager and game_manager.is_paused:
		print("游戏暂停中，无法切割动态西瓜")
		return
	
	print("动态西瓜被切!")
	
	watermelon.set_meta("cuttable", false)
	watermelon.set_meta("is_sliced", true)
	
	watermelon.remove_from_group("cuttable")
	
	var collision_shapes = watermelon.get_children().filter(func(node): return node is CollisionShape2D)
	for collision_node in collision_shapes:
		collision_node.set_deferred("disabled", true)
	
	# 发送信号
	var hunger_value = watermelon.get_meta("hunger_value", 10)
	var sugar_value = watermelon.get_meta("sugar_value", 15)
	var watermelon_type = watermelon.get_meta("watermelon_type", WatermelonType.NORMAL)
	
	# 根据西瓜类型显示不同的切割信息
	var type_name = get_watermelon_type_name(watermelon_type)
	print("切割了", type_name, "! 饥饿+", hunger_value, " 血糖+", sugar_value)
	
	watermelon.emit_signal("sliced", hunger_value, sugar_value)
	
	# 隐藏西瓜
	watermelon.visible = false
	
	# 1秒后删除
	get_tree().create_timer(1.0).timeout.connect(watermelon.queue_free)

# 获取西瓜类型名称的辅助函数
func get_watermelon_type_name(type: WatermelonType) -> String:
	match type:
		WatermelonType.NORMAL:
			return "普通西瓜"
		WatermelonType.GOLDEN:
			return "金色西瓜"
		WatermelonType.SWEET:
			return "甜味西瓜"
		WatermelonType.MINI:
			return "迷你西瓜"
		WatermelonType.GIANT:
			return "巨型西瓜"
		_:
			return "未知西瓜"
