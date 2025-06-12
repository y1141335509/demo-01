extends Node2D

var swipe_path = []
var swipe_timer := 0.0
var SWIPE_TIMEOUT := 0.5
var is_swiping := false

# 拖痕绘制相关
var trail_points = []
var trail_lifetime := 0.3

func _ready():
	print("PlayerSwipe ready")

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_swiping = true
				swipe_path.clear()
				trail_points.clear()
				print("Started swiping")
			else:
				is_swiping = false
				print("Stopped swiping")
	
	elif event is InputEventMouseMotion and is_swiping:
		swipe_timer = 0.0
		swipe_path.append(event.position)
		
		# 添加拖痕点 - 使用更简单的时间获取方式
		var current_time = Time.get_time_dict_from_system()
		var time_value = current_time.get("second", 0) + current_time.get("msec", 0) / 1000.0
		
		trail_points.append({
			"position": event.position,
			"time": time_value
		})
		
		# 清理过老的拖痕点
		var now = Time.get_time_dict_from_system()
		var now_value = now.get("second", 0) + now.get("msec", 0) / 1000.0
		trail_points = trail_points.filter(func(point): return now_value - point["time"] < trail_lifetime)
		
		queue_redraw()  # 重绘拖痕
		check_hit(event.position)

func _process(delta):
	swipe_timer += delta
	if swipe_timer > SWIPE_TIMEOUT:
		swipe_path.clear()
		trail_points.clear()
		queue_redraw()

func _draw():
	# 绘制拖痕
	if trail_points.size() > 1:
		var current_time_dict = Time.get_time_dict_from_system()
		var current_time = current_time_dict.get("second", 0) + current_time_dict.get("msec", 0) / 1000.0
		
		for i in range(trail_points.size() - 1):
			var point1 = trail_points[i]
			var point2 = trail_points[i + 1]
			
			# 根据时间计算透明度
			var alpha = 1.0 - (current_time - point1["time"]) / trail_lifetime
			alpha = clamp(alpha, 0.0, 1.0)
			
			var color = Color.YELLOW
			color.a = alpha
			
			# 绘制线段
			draw_line(point1["position"], point2["position"], color, 3.0)

func check_hit(pos):
	# 获取世界空间状态
	var space_state = get_world_2d().direct_space_state
	
	# 创建查询参数
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1  # 检查第1层
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	# 执行查询
	var results = space_state.intersect_point(query)
	
	for result in results:
		var body = result["collider"]
		if body and body.is_in_group("cuttable"):
			print("Hit cuttable object: ", body.name)
			if body.has_method("slice"):
				body.slice()
				# 创建切割特效
				create_slice_effect(pos)
			break

func create_slice_effect(pos):
	# 创建切割特效粒子
	print("Slice effect at: ", pos)
	
	# 可以在这里添加粒子效果或者简单的视觉反馈
	# 暂时用console输出作为反馈
