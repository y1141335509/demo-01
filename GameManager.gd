extends Node

var hunger := 50
var sugar := 50
var time_left := 30.0

# UI节点引用
var hunger_bar: ProgressBar
var glucose_bar: ProgressBar  
var timer_label: Label
var watermelon_spawner: Node2D

func _ready():
	print("GameManager starting...")
	
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
	
	# 测试进度条更新（5秒后测试）
	await get_tree().create_timer(5.0).timeout
	test_progress_bars()

func test_progress_bars():
	print("=== 测试进度条更新 ===")
	hunger = 75
	sugar = 25
	update_ui()
	print("测试完成：设置 hunger=75, sugar=25")

func setup_progress_bars():
	if hunger_bar and hunger_bar is ProgressBar:
		hunger_bar.min_value = 0
		hunger_bar.max_value = 100
		hunger_bar.value = hunger
		print("HungerBar setup: min=", hunger_bar.min_value, " max=", hunger_bar.max_value, " value=", hunger_bar.value)
	
	if glucose_bar and glucose_bar is ProgressBar:
		glucose_bar.min_value = 0
		glucose_bar.max_value = 100
		glucose_bar.value = sugar
		print("GlucoseBar setup: min=", glucose_bar.min_value, " max=", glucose_bar.max_value, " value=", glucose_bar.value)

func setup_nodes():
	print("=== 开始查找节点 ===")
	print("GameManager path: ", get_path())
	print("所有根节点:")
	var root = get_tree().root
	for child in root.get_children():
		print("  根节点: ", child.name, " (", child.get_class(), ")")
		if child.name.to_lower().contains("main"):
			print("    Main节点的子节点:")
			for grandchild in child.get_children():
				print("      - ", grandchild.name, " (", grandchild.get_class(), ")")
				if grandchild.name.to_lower().contains("ui"):
					print("        UI节点的子节点:")
					for ui_child in grandchild.get_children():
						print("          - ", ui_child.name, " (", ui_child.get_class(), ")")
	
	# 尝试暴力搜索所有ProgressBar和Label
	print("=== 暴力搜索UI节点 ===")
	var all_progress_bars = []
	var all_labels = []
	
	find_nodes_recursive(get_tree().root, all_progress_bars, all_labels)
	
	print("找到的ProgressBar数量: ", all_progress_bars.size())
	for i in range(all_progress_bars.size()):
		var bar = all_progress_bars[i]
		print("  ProgressBar ", i, ": ", bar.get_path(), " value=", bar.value)
		if i == 0:
			hunger_bar = bar
			print("    -> 分配为 HungerBar")
		elif i == 1:
			glucose_bar = bar
			print("    -> 分配为 GlucoseBar")
	
	print("找到的Label数量: ", all_labels.size())
	for i in range(all_labels.size()):
		var label = all_labels[i]
		print("  Label ", i, ": ", label.get_path(), " text='", label.text, "'")
		if i == 0:
			timer_label = label
			print("    -> 分配为 TimerLabel")
	
	# 获取西瓜生成器
	watermelon_spawner = get_node_or_null("../WatermelonSpawner")
	if watermelon_spawner:
		print("WatermelonSpawner found")
	else:
		print("Warning: WatermelonSpawner not found")

func find_nodes_recursive(node: Node, progress_bars: Array, labels: Array):
	if node is ProgressBar:
		progress_bars.append(node)
	elif node is Label:
		labels.append(node)
	
	for child in node.get_children():
		find_nodes_recursive(child, progress_bars, labels)

func start_game():
	print("Starting game...")
	
	# 启动西瓜生成器
	if watermelon_spawner and watermelon_spawner.has_method("start_spawning"):
		watermelon_spawner.start_spawning()
		print("Watermelon spawner started")

func _process(delta):
	# 更新时间
	time_left -= delta
	
	# 更新UI
	if timer_label:
		timer_label.text = "Time: %.1f" % time_left
	
	# 检查游戏结束条件
	if time_left <= 0:
		game_over(true)
	elif hunger <= 0 or sugar >= 100:
		game_over(false)

func update_stats(h: int, s: int):
	var old_hunger = hunger
	var old_sugar = sugar
	
	hunger += h
	sugar += s
	hunger = clamp(hunger, 0, 100)
	sugar = clamp(sugar, 0, 100)
	
	print("=== 数值更新 ===")
	print("Hunger: ", old_hunger, " -> ", hunger, " (change: +", h, ")")
	print("Sugar: ", old_sugar, " -> ", sugar, " (change: +", s, ")")
	update_ui()

func update_ui():
	print("=== 更新UI ===")
	print("Current values: Hunger=", hunger, " Sugar=", sugar)
	
	if hunger_bar and is_instance_valid(hunger_bar):
		var old_value = hunger_bar.value
		hunger_bar.value = hunger
		print("HungerBar: ", old_value, " -> ", hunger_bar.value, " (expected: ", hunger, ")")
		
		# 强制刷新
		hunger_bar.queue_redraw()
	else:
		print("HungerBar not available or invalid")
	
	if glucose_bar and is_instance_valid(glucose_bar):
		var old_value = glucose_bar.value
		glucose_bar.value = sugar
		print("GlucoseBar: ", old_value, " -> ", glucose_bar.value, " (expected: ", sugar, ")")
		
		# 强制刷新
		glucose_bar.queue_redraw()
	else:
		print("GlucoseBar not available or invalid")

func game_over(success: bool):
	print("Game Over!")
	
	# 停止生成西瓜
	if watermelon_spawner and watermelon_spawner.has_method("stop_spawning"):
		watermelon_spawner.stop_spawning()
	
	# 暂停游戏
	get_tree().paused = true
	
	if success:
		print("恭喜通关！")
	else:
		if hunger <= 0:
			print("游戏结束：饿死了")
		elif sugar >= 100:
			print("游戏结束：糖尿病了")
		else:
			print("游戏结束：时间到了")
