extends Node

# 游戏状态变量
var satiety := 50.0      
var blood_sugar := 50.0  
var time_left := 30.0
var is_paused := false   

# UI节点引用
var hunger_bar: ProgressBar      
var glucose_bar: ProgressBar     
var timer_label: Label
var pause_label: Label
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
	# 处理暂停输入
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ESCAPE:
			toggle_pause()

func toggle_pause():
	is_paused = !is_paused
	get_tree().paused = is_paused
	
	if pause_label:
		pause_label.visible = is_paused
	
	if is_paused:
		if watermelon_spawner and watermelon_spawner.has_method("stop_spawning"):
			watermelon_spawner.stop_spawning()
	else:
		if watermelon_spawner and watermelon_spawner.has_method("start_spawning"):
			watermelon_spawner.start_spawning()

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
	
	# 创建暂停标签
	create_pause_label()
	
	# 获取西瓜生成器
	watermelon_spawner = get_node_or_null("../WatermelonSpawner")

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

func create_pause_label():
	var ui_node = get_node_or_null("../UI")
	if ui_node:
		pause_label = Label.new()
		pause_label.name = "PauseLabel"
		pause_label.text = "游戏暂停\\n按空格键继续"
		pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pause_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# 设置位置（屏幕中央）
		pause_label.anchors_preset = Control.PRESET_CENTER
		pause_label.anchor_left = 0.5
		pause_label.anchor_right = 0.5
		pause_label.anchor_top = 0.5
		pause_label.anchor_bottom = 0.5
		pause_label.offset_left = -200
		pause_label.offset_right = 200
		pause_label.offset_top = -50
		pause_label.offset_bottom = 50
		
		pause_label.visible = false
		ui_node.add_child(pause_label)

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
	
	# 饥饿度下降
	satiety -= delta * 0.1
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
	
	# 切西瓜的效果
	satiety += float(hunger_restore)
	blood_sugar += float(sugar_increase)
	
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
	
	# 暂停游戏
	is_paused = true
	get_tree().paused = true
	
	# 根据成功/失败显示不同消息
	if success:
		print("🎉 恭喜通关!")
	else:
		print("💀 游戏失败")
