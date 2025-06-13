extends RigidBody2D

@export var hunger_value := 10
@export var sugar_value := 15

signal sliced(hunger: int, sugar: int)
var cuttable := true
var lifetime := 0.0
var max_lifetime := 15.0

func _ready():
	add_to_group("cuttable")
	add_to_group("watermelons")  # 添加到西瓜组，用于暂停管理
	print("预制西瓜就绪")

func _process(delta):
	lifetime += delta
	
	# 检查是否超时或离开屏幕
	if lifetime > max_lifetime or position.y > 700 or position.x < -100 or position.x > 900:
		queue_free()

func slice():
	if not cuttable:
		return 
	
	cuttable = false
	print("🍉 预制西瓜被切!")
	
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
	# 创建左半边
	var half_left = RigidBody2D.new()
	half_left.position = global_position + Vector2(-20, 0)
	half_left.gravity_scale = 0.8
	half_left.mass = 0.5
	
	var sprite_left = Sprite2D.new()
	var texture_left = ImageTexture.new()
	var image_left = Image.create(32, 64, false, Image.FORMAT_RGB8)
	image_left.fill(Color.DARK_GREEN)
	texture_left.set_image(image_left)
	sprite_left.texture = texture_left
	half_left.add_child(sprite_left)
	
	var collision_left = CollisionShape2D.new()
	var shape_left = RectangleShape2D.new()
	shape_left.size = Vector2(32, 64)
	collision_left.shape = shape_left
	half_left.add_child(collision_left)
	
	# 创建右半边
	var half_right = RigidBody2D.new()
	half_right.position = global_position + Vector2(20, 0)
	half_right.gravity_scale = 0.8
	half_right.mass = 0.5
	
	var sprite_right = Sprite2D.new()
	var texture_right = ImageTexture.new()
	var image_right = Image.create(32, 64, false, Image.FORMAT_RGB8)
	image_right.fill(Color.DARK_GREEN)
	texture_right.set_image(image_right)
	sprite_right.texture = texture_right
	half_right.add_child(sprite_right)
	
	var collision_right = CollisionShape2D.new()
	var shape_right = RectangleShape2D.new()
	shape_right.size = Vector2(32, 64)
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
