extends Node

# 游戏状态变量（简化版）
var blood_sugar := 50.0  # 血糖值（0-100）
var time_left := 60.0    
var is_paused := false   
var watermelon_count := 0  # 切了多少个西瓜

# UI节点引用（移除饥饿相关）
var glucose_bar: ProgressBar     
var timer_label: Label
var pause_label: Label
var pause_button: Button
var game_over_label: Label       
var restart_button: Button       
var watermelon_spawner: Node2D

# 字体资源
var chinese_font: FontFile
var font_loaded: bool = false

func _ready():
	load_chinese_font()
	await get_tree().process_frame
	setup_nodes()
	setup_progress_bars()
	update_ui()
	start_game()

func load_chinese_font():
	"""加载中文字体文件"""
	print("开始加载中文字体...")
	
	if ResourceLoader.exists("res://fonts/NotoSansSC-Regular.ttf"):
		chinese_font = load("res://fonts/NotoSansSC-Regular.ttf")
		if chinese_font:
			font_loaded = true
			print("✅ 直接加载字体文件成功")
			return
	
	chinese_font = preload("res://fonts/NotoSansSC-Regular.ttf") if ResourceLoader.exists("res://fonts/NotoSansSC-Regular.ttf") else null
	if chinese_font:
		font_loaded = true
		print("✅ preload加载字体成功")
		return
	
	copy_font_from_existing_labels()
	
	if not font_loaded:
		print("⚠️ 字体加载失败，将使用系统默认字体")

func copy_font_from_existing_labels():
	"""从现有Label复制字体"""
	print("尝试从现有Label复制字体...")
	
	var glucose_label = find_label_by_name(get_tree().current_scene, "GlucoseLabel")
	if glucose_label:
		var label_font = glucose_label.get_theme_font("font")
		if label_font:
			chinese_font = label_font
			font_loaded = true
			print("✅ 从GlucoseLabel复制字体成功")
			return

func apply_chinese_font_to_control(control: Control, font_size: int = 16):
	"""为控件应用中文字体和字体大小"""
	if not control:
		return
	
	if font_loaded and chinese_font:
		control.add_theme_font_override("font", chinese_font)
		control.add_theme_font_size_override("font_size", font_size)
		print("✅ 应用中文字体到: ", control.name)
	else:
		control.add_theme_font_size_override("font_size", font_size)
		print("⚠️ 只设置字体大小到: ", control.name)

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()

func toggle_pause():
	is_paused = !is_paused
	
	if pause_label:
		pause_label.visible = is_paused
	
	if pause_button:
		pause_button.text = "继续游戏" if is_paused else "暂停"
	
	pause_all_watermelons(is_paused)
	
	if is_paused:
		print("游戏暂停")
		if watermelon_spawner and watermelon_spawner.has_method("stop_spawning"):
			watermelon_spawner.stop_spawning()
	else:
		print("游戏继续")
		if watermelon_spawner and watermelon_spawner.has_method("start_spawning"):
			watermelon_spawner.start_spawning()

func pause_all_watermelons(paused: bool):
	var watermelons = get_tree().get_nodes_in_group("watermelons")
	
	for watermelon in watermelons:
		if watermelon is RigidBody2D:
			if paused:
				watermelon.set_meta("saved_gravity_scale", watermelon.gravity_scale)
				watermelon.set_meta("saved_linear_velocity", watermelon.linear_velocity)
				watermelon.set_meta("saved_angular_velocity", watermelon.angular_velocity)
				
				watermelon.gravity_scale = 0
				watermelon.linear_velocity = Vector2.ZERO
				watermelon.angular_velocity = 0
				watermelon.freeze = true
			else:
				var saved_gravity = watermelon.get_meta("saved_gravity_scale", 0.8)
				var saved_linear_vel = watermelon.get_meta("saved_linear_velocity", Vector2.ZERO)
				var saved_angular_vel = watermelon.get_meta("saved_angular_velocity", 0.0)
				
				watermelon.freeze = false
				watermelon.gravity_scale = saved_gravity
				watermelon.linear_velocity = saved_linear_vel
				watermelon.angular_velocity = saved_angular_vel

func _on_pause_button_pressed():
	toggle_pause()

func _on_restart_button_pressed():
	restart_game()

func setup_progress_bars():
	# 移除饥饿相关，只保留血糖
	if glucose_bar:
		glucose_bar.min_value = 0
		glucose_bar.max_value = 100
		glucose_bar.value = blood_sugar
		print("GlucoseBar 就绪")
	else:
		print("❌ 找不到 GlucoseBar")

func setup_nodes():
	var root_node = get_tree().current_scene
	# 移除饥饿相关UI查找
	glucose_bar = find_progress_bar_by_name(root_node, "GlucoseBar")
	timer_label = find_label_by_name(root_node, "TimerLabel")
	pause_button = find_button_by_name(root_node, "PauseButton")
	
	setup_ui_font_sizes()
	
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
		apply_chinese_font_to_control(pause_button, 16)
		print("暂停按钮已连接并应用字体")
	else:
		print("❌ 找不到暂停按钮")
	
	create_pause_label()
	create_game_over_ui()
	watermelon_spawner = get_node_or_null("../WatermelonSpawner")

func setup_ui_font_sizes():
	if timer_label:
		apply_chinese_font_to_control(timer_label, 20)
	
	# 只设置血糖标签字体
	var glucose_label = find_label_by_name(get_tree().current_scene, "GlucoseLabel")
	if glucose_label:
		apply_chinese_font_to_control(glucose_label, 18)

func find_progress_bar_by_name(node: Node, target_name: String):
	if node.name == target_name and node is ProgressBar:
		return node
	for child in node.get_children():
		var result = find_progress_bar_by_name(child, target_name)
		if result:
			return result
	return null

func find_label_by_name(node: Node, target_name: String):
	if node.name == target_name and node is Label:
		return node
	for child in node.get_children():
		var result = find_label_by_name(child, target_name)
		if result:
			return result
	return null

func find_button_by_name(node: Node, target_name: String):
	if node.name == target_name and node is Button:
		return node
	for child in node.get_children():
		var result = find_button_by_name(child, target_name)
		if result:
			return result
	return null

func create_pause_label():
	var ui_node = get_node_or_null("../UI")
	if ui_node:
		pause_label = Label.new()
		pause_label.name = "PauseLabel"
		pause_label.text = "游戏暂停\n按空格键或点击继续游戏按钮"
		pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		apply_chinese_font_to_control(pause_label, 32)
		pause_label.modulate = Color.YELLOW
		
		pause_label.anchors_preset = Control.PRESET_CENTER
		pause_label.anchor_left = 0.5
		pause_label.anchor_right = 0.5
		pause_label.anchor_top = 0.5
		pause_label.anchor_bottom = 0.5
		pause_label.offset_left = -250
		pause_label.offset_right = 250
		pause_label.offset_top = -50
		pause_label.offset_bottom = 50
		
		pause_label.visible = false
		ui_node.add_child(pause_label)
		print("✅ 暂停标签已创建并应用字体")

func create_game_over_ui():
	var ui_node = get_node_or_null("../UI")
	if ui_node:
		game_over_label = Label.new()
		game_over_label.name = "GameOverLabel"
		game_over_label.text = "游戏结束"
		game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		apply_chinese_font_to_control(game_over_label, 48)
		game_over_label.modulate = Color.RED
		
		game_over_label.anchors_preset = Control.PRESET_CENTER
		game_over_label.anchor_left = 0.5
		game_over_label.anchor_right = 0.5
		game_over_label.anchor_top = 0.5
		game_over_label.anchor_bottom = 0.5
		game_over_label.offset_left = -200
		game_over_label.offset_right = 200
		game_over_label.offset_top = -100
		game_over_label.offset_bottom = -50
		
		game_over_label.visible = false
		ui_node.add_child(game_over_label)
		
		restart_button = Button.new()
		restart_button.name = "RestartButton"
		restart_button.text = "重新开始"
		
		apply_chinese_font_to_control(restart_button, 24)
		
		restart_button.anchors_preset = Control.PRESET_CENTER
		restart_button.anchor_left = 0.5
		restart_button.anchor_right = 0.5
		restart_button.anchor_top = 0.5
		restart_button.anchor_bottom = 0.5
		restart_button.offset_left = -80
		restart_button.offset_right = 80
		restart_button.offset_top = 20
		restart_button.offset_bottom = 60
		
		restart_button.visible = false
		restart_button.pressed.connect(_on_restart_button_pressed)
		ui_node.add_child(restart_button)
		print("✅ 游戏结束UI已创建并应用字体")

func start_game():
	print("游戏开始")
	
	var prebuilt_watermelon = get_node_or_null("../Watermelon")
	if prebuilt_watermelon:
		if prebuilt_watermelon.has_signal("sliced"):
			var connection_result = prebuilt_watermelon.connect("sliced", Callable(self, "on_watermelon_sliced"))
			if connection_result == OK:
				print("预制西瓜信号已连接")
			else:
				print("❌ 预制西瓜信号连接失败")
	
	if watermelon_spawner and watermelon_spawner.has_method("start_spawning"):
		watermelon_spawner.start_spawning()

func _process(delta):
	if is_paused:
		return
	
	# 新的游戏逻辑：血糖随时间缓慢下降（代表饥饿）
	var blood_sugar_decrease_rate = 1.5  # 每秒减少0.8点血糖
	blood_sugar -= delta * blood_sugar_decrease_rate
	blood_sugar = clamp(blood_sugar, 0.0, 100.0)
	
	time_left -= delta
	
	# 实时更新UI
	if Engine.get_process_frames() % 15 == 0:  # 更频繁的更新
		if timer_label:
			timer_label.text = "Time: %.1f" % time_left
		update_ui()
	
	# 检查游戏结束条件
	if time_left <= 0:
		# 时间结束时，根据切西瓜数量和血糖判断结局
		judge_final_result()
	elif blood_sugar < 10:
		game_over(false, "饿死了")  # 血糖过低 = 饿死
	elif blood_sugar > 90:
		game_over(false, "糖尿病了")  # 血糖过高 = 糖尿病

func judge_final_result():
	"""时间结束时判断最终结果"""
	if blood_sugar >= 10 and blood_sugar <= 90:  # 血糖在合理范围
		game_over(true, "平衡掌握得很好")
	elif blood_sugar < 10:
			game_over(false, "未获得足够的西瓜导致血糖失衡")
	else:
		game_over(false, "切的西瓜太多引发糖尿病")

func on_watermelon_sliced(hunger_restore: int, sugar_increase: int):
	print("西瓜被切! 血糖+", sugar_increase, " (总计:", watermelon_count + 1, "个)")
	
	# 增加西瓜计数
	watermelon_count += 1
	
	var old_blood_sugar = blood_sugar
	
	# 切西瓜只影响血糖
	var sugar_multiplier = 1.0
	blood_sugar += float(sugar_increase) * sugar_multiplier
	blood_sugar = clamp(blood_sugar, 0.0, 100.0)
	
	print("血糖: %.0f->%.0f (切了%d个西瓜)" % [old_blood_sugar, blood_sugar, watermelon_count])
	
	force_update_ui()

func force_update_ui():
	# 只更新血糖进度条
	if glucose_bar and is_instance_valid(glucose_bar):
		glucose_bar.value = blood_sugar
		print("GlucoseBar -> %.0f" % blood_sugar)
		
		# 血糖颜色指示
		if blood_sugar > 80:
			glucose_bar.modulate = Color.RED  # 危险：糖尿病风险
		elif blood_sugar > 60:
			glucose_bar.modulate = Color.ORANGE  # 警告
		elif blood_sugar < 20:
			glucose_bar.modulate = Color.RED  # 危险：饥饿
		elif blood_sugar < 40:
			glucose_bar.modulate = Color.YELLOW  # 警告
		else:
			glucose_bar.modulate = Color.GREEN  # 健康
	else:
		print("❌ GlucoseBar 无效")

func update_ui():
	if glucose_bar and is_instance_valid(glucose_bar):
		glucose_bar.value = blood_sugar
		if blood_sugar > 80:
			glucose_bar.modulate = Color.RED
		elif blood_sugar > 60:
			glucose_bar.modulate = Color.ORANGE
		elif blood_sugar < 20:
			glucose_bar.modulate = Color.RED
		elif blood_sugar < 40:
			glucose_bar.modulate = Color.YELLOW
		else:
			glucose_bar.modulate = Color.GREEN

func game_over(success: bool, reason: String = ""):
	print("游戏结束: ", reason)
	
	if watermelon_spawner and watermelon_spawner.has_method("stop_spawning"):
		watermelon_spawner.stop_spawning()
	
	pause_all_watermelons(true)
	is_paused = true
	
	if pause_label:
		pause_label.visible = false
	if pause_button:
		pause_button.visible = false
	
	if game_over_label:
		if success:
			game_over_label.text = "恭喜通关!\n时间: %.1f秒\n切了%d个西瓜" % [60.0 - time_left, watermelon_count]
			game_over_label.modulate = Color.GREEN
		else:
			game_over_label.text = "游戏结束\n%s\n切了%d个西瓜" % [reason, watermelon_count]
			game_over_label.modulate = Color.RED
		game_over_label.visible = true
	
	if restart_button:
		restart_button.visible = true
	
	if success:
		print("恭喜通关! 切了%d个西瓜" % watermelon_count)
	else:
		print("游戏失败: %s (切了%d个西瓜)" % [reason, watermelon_count])

func restart_game():
	print("重新开始游戏")
	
	# 重置所有游戏状态
	blood_sugar = 50.0
	time_left = 60.0
	is_paused = false
	watermelon_count = 0  # 重置西瓜计数
	
	clear_all_watermelons()
	
	if game_over_label:
		game_over_label.visible = false
	if restart_button:
		restart_button.visible = false
	
	if pause_button:
		pause_button.visible = true
		pause_button.text = "暂停"
	
	update_ui()
	
	if watermelon_spawner and watermelon_spawner.has_method("start_spawning"):
		watermelon_spawner.start_spawning()

func clear_all_watermelons():
	var watermelons = get_tree().get_nodes_in_group("watermelons")
	for watermelon in watermelons:
		if is_instance_valid(watermelon):
			watermelon.queue_free()
