extends RigidBody2D

@export var hunger_value := 10
@export var sugar_value := 15
@export var watermelon_texture_path := "res://sprites/watermelons/normal_watermelon.png"

signal sliced(hunger: int, sugar: int)
var cuttable := true
var lifetime := 0.0
var max_lifetime := 15.0

func _ready():
	add_to_group("cuttable")
	add_to_group("watermelons")
	
	# 应用西瓜图片（如果存在）
	apply_watermelon_sprite()
	
	print("预制西瓜就绪")

func apply_watermelon_sprite():
	"""为预制西瓜应用图片纹理"""
	var sprite_node = get_node_or_null("Sprite2D")
	if not sprite_node:
		print("❌ 找不到Sprite2D节点")
		return
	
	# 尝试加载指定的纹理
	if ResourceLoader.exists(watermelon_texture_path):
		var texture = load(watermelon_texture_path)
		if texture:
			sprite_node.texture = texture
			print("✅ 已为预制西瓜应用纹理:", watermelon_texture_path)
			
			# 调整碰撞形状以匹配新纹理
			adjust_collision_shape_improved(sprite_node, texture)
		else:
			print("❌ 无法加载纹理:", watermelon_texture_path)
	else:
		print("⚠️ 纹理文件不存在:", watermelon_texture_path)
		# 创建fallback纹理
		create_fallback_sprite(sprite_node)

func create_fallback_sprite(sprite_node: Sprite2D):
	"""为预制西瓜创建fallback纹理"""
	var texture = ImageTexture.new()
	var image = Image.create(100, 100, false, Image.FORMAT_RGB8)  # 修复：使用100x100
	image.fill(Color.GREEN)
	texture.set_image(image)
	sprite_node.texture = texture
	print("🔄 为预制西瓜创建了fallback纹理")
	
	# 同时调整碰撞
	adjust_collision_shape_improved(sprite_node, texture)

func adjust_collision_shape_improved(sprite_node: Sprite2D, texture: Texture2D):
	"""改进的碰撞形状调整 - 修复切割判定问题"""
	var collision_node = get_node_or_null("CollisionShape2D")
	if not collision_node:
		print("❌ 找不到CollisionShape2D节点")
		return
	
	# 获取纹理尺寸
	var texture_size = texture.get_size()
	var sprite_scale = sprite_node.scale
	
	# 计算实际显示尺寸
	var actual_width = texture_size.x * sprite_scale.x
	var actual_height = texture_size.y * sprite_scale.y
	
	# 关键修复：根据实际图片尺寸计算合适的碰撞半径
	var base_size = min(actual_width, actual_height)
	var radius: float
	
	# 根据图片尺寸调整碰撞半径倍数
	if base_size <= 64:
		# 64x64 mini西瓜
		radius = base_size * 0.44  # 约28像素
	elif base_size <= 100:
		# 100x100 普通西瓜
		radius = base_size * 0.45  # 约45像素
	elif base_size <= 128:
		# 128x128 巨型西瓜
		radius = base_size * 0.45  # 约58像素
	else:
		# 更大的西瓜
		radius = base_size * 0.4
	
	# 设置圆形碰撞形状
	if collision_node.shape is CircleShape2D:
		var circle_shape = collision_node.shape as CircleShape2D
		circle_shape.radius = radius
		print("✅ 调整碰撞半径为:", radius, "(图片尺寸:", texture_size, ")")
	else:
		# 如果不是圆形，创建新的圆形碰撞
		var new_shape = CircleShape2D.new()
		new_shape.radius = radius
		collision_node.shape = new_shape
		print("🔄 创建了新的圆形碰撞，半径:", radius, "(图片尺寸:", texture_size, ")")

func _process(delta):
	lifetime += delta
	
	# 检查是否超时或离开屏幕
	if lifetime > max_lifetime or position.y > 700 or position.x < -100 or position.x > 900:
		queue_free()

func slice():
	if not cuttable:
		return 
	
	cuttable = false
	print("预制西瓜被切!")
	
	# 发送信号给 GameManager
	emit_signal("sliced", hunger_value, sugar_value)
	
	# 立即从 cuttable 组中移除
	remove_from_group("cuttable")
	
	# 禁用碰撞
	var collision_shape = get_node_or_null("CollisionShape2D")
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# 创建切开的两瓣效果
	create_split_effect()
	
	# 隐藏原始西瓜
	visible = false
	
	# 1秒后清除
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(queue_free)
	add_child(cleanup_timer)
	cleanup_timer.start()

func create_split_effect():
	"""创建西瓜被切开的效果"""
	var sprite_node = get_node_or_null("Sprite2D")
	var original_texture = null
	var original_scale = Vector2(1, 1)
	
	if sprite_node and sprite_node.texture:
		original_texture = sprite_node.texture
		original_scale = sprite_node.scale
	
	# 创建左半边
	var half_left = RigidBody2D.new()
	half_left.position = global_position + Vector2(-20, 0)
	half_left.gravity_scale = 0.8
	half_left.mass = 0.5
	
	var sprite_left = Sprite2D.new()
	if original_texture:
		sprite_left.texture = original_texture
		sprite_left.scale = original_scale * 0.5  # 稍微缩小分裂片段
		# 通过区域显示只显示左半部分
		sprite_left.region_enabled = true
		var texture_size = original_texture.get_size()
		sprite_left.region_rect = Rect2(0, 0, texture_size.x * 0.5, texture_size.y)
	else:
		# fallback：使用简单颜色块
		var texture_left = ImageTexture.new()
		var image_left = Image.create(50, 100, false, Image.FORMAT_RGB8)  # 调整为实际比例
		image_left.fill(Color.DARK_GREEN)
		texture_left.set_image(image_left)
		sprite_left.texture = texture_left
	
	half_left.add_child(sprite_left)
	
	var collision_left = CollisionShape2D.new()
	var shape_left = RectangleShape2D.new()
	shape_left.size = Vector2(25, 50)  # 调整分裂片段碰撞大小
	collision_left.shape = shape_left
	half_left.add_child(collision_left)
	
	# 创建右半边
	var half_right = RigidBody2D.new()
	half_right.position = global_position + Vector2(20, 0)
	half_right.gravity_scale = 0.8
	half_right.mass = 0.5
	
	var sprite_right = Sprite2D.new()
	if original_texture:
		sprite_right.texture = original_texture
		sprite_right.scale = original_scale * 0.5
		# 显示右半部分
		sprite_right.region_enabled = true
		var texture_size = original_texture.get_size()
		sprite_right.region_rect = Rect2(texture_size.x * 0.5, 0, texture_size.x * 0.5, texture_size.y)
	else:
		# fallback：使用简单颜色块
		var texture_right = ImageTexture.new()
		var image_right = Image.create(50, 100, false, Image.FORMAT_RGB8)
		image_right.fill(Color.DARK_GREEN)
		texture_right.set_image(image_right)
		sprite_right.texture = texture_right
	
	half_right.add_child(sprite_right)
	
	var collision_right = CollisionShape2D.new()
	var shape_right = RectangleShape2D.new()
	shape_right.size = Vector2(25, 50)
	collision_right.shape = shape_right
	half_right.add_child(collision_right)
	
	# 添加到场景
	get_parent().add_child(half_left)
	get_parent().add_child(half_right)
	
	# 给两瓣加上分离的速度
	half_left.linear_velocity = Vector2(-150, -100)
	half_right.linear_velocity = Vector2(150, -100)
	
	# 3秒后清除两瓣
	var timer_left = Timer.new()
	timer_left.wait_time = 3.0
	timer_left.one_shot = true
	timer_left.timeout.connect(func(): 
		if is_instance_valid(half_left):
			half_left.queue_free()
	)
	half_left.add_child(timer_left)
	timer_left.start()
	
	var timer_right = Timer.new()
	timer_right.wait_time = 3.0
	timer_right.one_shot = true
	timer_right.timeout.connect(func(): 
		if is_instance_valid(half_right):
			half_right.queue_free()
	)
	half_right.add_child(timer_right)
	timer_right.start()
