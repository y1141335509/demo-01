extends Node

# 游戏状态变量（公开访问）
var satiety := 50.0      
var blood_sugar := 50.0  
var time_left := 30.0
var is_paused := false   # 公开变量，其他脚本可以访问   

# UI节点引用
var hunger_bar: ProgressBar      
var glucose_bar: ProgressBar     
var timer_label: Label
var pause_label: Label
var pause_button: Button
var game_over_label: Label       # 新增：游戏结束标签
var restart_button: Button       # 新增：重新开始按钮
var watermelon_spawner: Node2D

func _ready():
	# 等一帧确保所有节点都已就绪
	await get_tree().process_frame
	
	# 设置节点引用
	setup_nodes()
	
	# 强制设置进度条范围
	setup_progress_bars()
	
	# 初始化UI
	update_ui()
	
	# 启动游戏
	start_game()

func _input(event):
	# 处理暂停输入 - 使用 _input 而不是 _unhandled_input 来确保优先处理
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE:
			toggle_pause()
			get_viewport().set_input_as_handled()  # 标记事件已处理，防止重复触发

func toggle_pause():
	is_paused = !is_paused
	
	# 设置暂停状态但不暂停整个场景树
	if pause_label:
		pause_label.visible = is_paused
	
	# 更新暂停按钮文本
	if pause_button:
		pause_button.text = "继续游戏" if is_paused else "暂停"
	
	# 暂停/恢复所有西瓜的物理模拟
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
	# 获取所有西瓜节点
	var watermelons = get_tree().get_nodes_in_group("watermelons")
	
	for watermelon in watermelons:
		if watermelon is RigidBody2D:
			if paused:
				# 暂停时保存当前状态并停止物理模拟
				watermelon.set_meta("saved_gravity_scale", watermelon.gravity_scale)
				watermelon.set_meta("saved_linear_velocity", watermelon.linear_velocity)
				watermelon.set_meta("saved_angular_velocity", watermelon.angular_velocity)
				
				# 停止物理模拟
				watermelon.gravity_scale = 0
				watermelon.linear_velocity = Vector2.ZERO
				watermelon.angular_velocity = 0
				watermelon.freeze = true
			else:
				# 恢复时恢复之前的状态
				var saved_gravity = watermelon.get_meta("saved_gravity_scale", 0.8)
				var saved_linear_vel = watermelon.get_meta("saved_linear_velocity", Vector2.ZERO)
				var saved_angular_vel = watermelon.get_meta("saved_angular_velocity", 0.0)
				
				# 恢复物理模拟
				watermelon.freeze = false
				watermelon.gravity_scale = saved_gravity
				watermelon.linear_velocity = saved_linear_vel
				watermelon.angular_velocity = saved_angular_vel

func _on_pause_button_pressed():
	toggle_pause()

func _on_restart_button_pressed():
	restart_game()

func setup_progress_bars():
	if hunger_bar:
		hunger_bar.min_value = 0
		hunger_bar.max_value = 100
		hunger_bar.value = satiety
		print("HungerBar 就绪")
	else:
		print("❌ 找不到 HungerBar")
	
	if glucose_bar:
		glucose_bar.min_value = 0
		glucose_bar.max_value = 100
		glucose_bar.value = blood_sugar
		print("GlucoseBar 就绪")
	else:
		print("❌ 找不到 GlucoseBar")

func setup_nodes():
	# 使用更广泛的搜索来找到进度条
	var root_node = get_tree().current_scene
	hunger_bar = find_progress_bar_by_name(root_node, "HungerBar")
	glucose_bar = find_progress_bar_by_name(root_node, "GlucoseBar")
	timer_label = find_label_by_name(root_node, "TimerLabel")
	pause_button = find_button_by_name(root_node, "PauseButton")
	
	# 设置UI元素的字体大小
	setup_ui_font_sizes()
	
	# 连接暂停按钮信号
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
		print("暂停按钮已连接")
	else:
		print("❌ 找不到暂停按钮")
	
	# 创建暂停标签
	create_pause_label()
	
	# 创建游戏结束UI
	create_game_over_ui()
	
	# 获取西瓜生成器
	watermelon_spawner = get_node_or_null("../WatermelonSpawner")

func setup_ui_font_sizes():
	# 设置定时器标签字体大小
	if timer_label:
		timer_label.add_theme_font_size_override("font_size", 20)
	
	# 设置暂停按钮字体大小
	if pause_button:
		pause_button.add_theme_font_size_override("font_size", 16)
	
	# 查找并设置进度条标签的字体大小
	var hunger_label = find_label_by_name(get_tree().current_scene, "HungerLabel")
	var glucose_label = find_label_by_name(get_tree().current_scene, "GlucoseLabel")
	
	if hunger_label:
		hunger_label.add_theme_font_size_override("font_size", 18)
	
	if glucose_label:
		glucose_label.add_theme_font_size_override("font_size", 18)

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
		pause_label.text = "游戏暂停\\n按空格键或点击'继续游戏'按钮"
		pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pause_label.add_theme_font_size_override("font_size", 32)
		pause_label.modulate = Color.YELLOW
		
		# 设置位置（屏幕中央）
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

func create_game_over_ui():
	var ui_node = get_node_or_null("../UI")
	if ui_node:
		# 创建游戏结束标签
		game_over_label = Label.new()
		game_over_label.name = "GameOverLabel"
		game_over_label.text = "游戏结束"
		game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		game_over_label.add_theme_font_size_override("font_size", 48)
		game_over_label.modulate = Color.RED
		
		# 设置位置（屏幕中央偏上）
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
		
		# 创建重新开始按钮
		restart_button = Button.new()
		restart_button.name = "RestartButton"
		restart_button.text = "重新开始"
		restart_button.add_theme_font_size_override("font_size", 24)
		
		# 设置位置（屏幕中央偏下）
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

func start_game():
	print("游戏开始")
	
	# 连接预制西瓜的信号
	var prebuilt_watermelon = get_node_or_null("../Watermelon")
	if prebuilt_watermelon:
		if prebuilt_watermelon.has_signal("sliced"):
			var connection_result = prebuilt_watermelon.connect("sliced", Callable(self, "on_watermelon_sliced"))
			if connection_result == OK:
				print("预制西瓜信号已连接")
			else:
				print("❌ 预制西瓜信号连接失败")
	
	# 启动西瓜生成器
	if watermelon_spawner and watermelon_spawner.has_method("start_spawning"):
		watermelon_spawner.start_spawning()

func _process(delta):
	# 暂停时不处理游戏逻辑
	if is_paused:
		return
	
	# 饥饿度下降 - 可调节的参数
	var hunger_decrease_rate = 0.1  # 每秒减少0.1点 (你可以在这里调节)
	satiety -= delta * hunger_decrease_rate
	satiety = clamp(satiety, 0.0, 100.0)
	
	# 更新时间
	time_left -= delta
	
	# 更新UI（每30帧更新一次以优化性能）
	if Engine.get_process_frames() % 30 == 0:
		if timer_label:
			timer_label.text = "Time: %.1f" % time_left
		update_ui()
	
	# 检查游戏结束条件
	if time_left <= 0:
		game_over(true, "时间到")
	elif satiety <= 0:
		game_over(false, "饿死了")
	elif blood_sugar >= 100:
		game_over(false, "糖尿病了")

func on_watermelon_sliced(hunger_restore: int, sugar_increase: int):
	print("🍉 西瓜被切! 饥饿+", hunger_restore, " 血糖+", sugar_increase)
	
	var old_satiety = satiety
	var old_blood_sugar = blood_sugar
	
	# 切西瓜的效果 - 可调节的参数
	var hunger_multiplier = 1.0  # 饥饿恢复倍数 (你可以在这里调节)
	var sugar_multiplier = 1.0   # 血糖增加倍数 (你可以在这里调节)
	
	satiety += float(hunger_restore) * hunger_multiplier
	blood_sugar += float(sugar_increase) * sugar_multiplier
	
	# 限制范围
	satiety = clamp(satiety, 0.0, 100.0)
	blood_sugar = clamp(blood_sugar, 0.0, 100.0)
	
	print("饥饿: %.0f->%.0f, 血糖: %.0f->%.0f" % [old_satiety, satiety, old_blood_sugar, blood_sugar])
	
	# 立即更新UI
	force_update_ui()

func force_update_ui():
	# 强制更新进度条
	if hunger_bar and is_instance_valid(hunger_bar):
		hunger_bar.value = satiety
		print("HungerBar -> %.0f" % satiety)
		
		# 颜色变化
		if satiety < 20:
			hunger_bar.modulate = Color.RED
		elif satiety < 50:
			hunger_bar.modulate = Color.YELLOW
		else:
			hunger_bar.modulate = Color.GREEN
	else:
		print("❌ HungerBar 无效")
	
	if glucose_bar and is_instance_valid(glucose_bar):
		glucose_bar.value = blood_sugar
		print("GlucoseBar -> %.0f" % blood_sugar)
		
		# 颜色变化
		if blood_sugar > 80:
			glucose_bar.modulate = Color.RED
		elif blood_sugar > 60:
			glucose_bar.modulate = Color.YELLOW
		else:
			glucose_bar.modulate = Color.GREEN
	else:
		print("❌ GlucoseBar 无效")

func update_ui():
	if hunger_bar and is_instance_valid(hunger_bar):
		hunger_bar.value = satiety
		if satiety < 20:
			hunger_bar.modulate = Color.RED
		elif satiety < 50:
			hunger_bar.modulate = Color.YELLOW
		else:
			hunger_bar.modulate = Color.GREEN
	
	if glucose_bar and is_instance_valid(glucose_bar):
		glucose_bar.value = blood_sugar
		if blood_sugar > 80:
			glucose_bar.modulate = Color.RED
		elif blood_sugar > 60:
			glucose_bar.modulate = Color.YELLOW
		else:
			glucose_bar.modulate = Color.GREEN

func game_over(success: bool, reason: String = ""):
	print("游戏结束: ", reason)
	
	# 停止生成西瓜
	if watermelon_spawner and watermelon_spawner.has_method("stop_spawning"):
		watermelon_spawner.stop_spawning()
	
	# 暂停所有西瓜
	pause_all_watermelons(true)
	
	# 设置为暂停状态
	is_paused = true
	
	# 隐藏暂停相关UI
	if pause_label:
		pause_label.visible = false
	if pause_button:
		pause_button.visible = false
	
	# 显示游戏结束UI
	if game_over_label:
		if success:
			game_over_label.text = "🎉 恭喜通关！\\n时间: %.1f秒" % (30.0 - time_left)
			game_over_label.modulate = Color.GREEN
		else:
			game_over_label.text = "💀 游戏结束\\n" + reason
			game_over_label.modulate = Color.RED
		game_over_label.visible = true
	
	if restart_button:
		restart_button.visible = true
	
	# 根据成功/失败显示不同消息
	if success:
		print("🎉 恭喜通关!")
	else:
		print("💀 游戏失败")

func restart_game():
	print("重新开始游戏")
	
	# 重置游戏状态
	satiety = 50.0
	blood_sugar = 50.0
	time_left = 30.0
	is_paused = false
	
	# 清除所有西瓜
	clear_all_watermelons()
	
	# 隐藏游戏结束UI
	if game_over_label:
		game_over_label.visible = false
	if restart_button:
		restart_button.visible = false
	
	# 显示暂停按钮
	if pause_button:
		pause_button.visible = true
		pause_button.text = "暂停"
	
	# 更新UI
	update_ui()
	
	# 重新启动游戏
	if watermelon_spawner and watermelon_spawner.has_method("start_spawning"):
		watermelon_spawner.start_spawning()

func clear_all_watermelons():
	# 清除所有西瓜
	var watermelons = get_tree().get_nodes_in_group("watermelons")
	for watermelon in watermelons:
		if is_instance_valid(watermelon):
			watermelon.queue_free()
