extends Node2D

var swipe_path = []
var swipe_timer := 0.0
var SWIPE_TIMEOUT := 0.5
var is_swiping := false

# 拖痕绘制相关（增强版）
var trail_points = []
var trail_lifetime := 0.8
var trail_width := 5.0

# 新增：切割特效
var slice_effects = []

func _ready():
	pass

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_swiping = true
				swipe_path.clear()
				trail_points.clear()
				play_swipe_start_sound()
			else:
				is_swiping = false
				if swipe_path.size() > 5:  # 只有足够长的滑动才播放音效
					play_swipe_end_sound()
	
	elif event is InputEventMouseMotion and is_swiping:
		swipe_timer = 0.0
		swipe_path.append(event.position)
		
		# 添加拖痕点（增强版）
		var current_time = Time.get_time_dict_from_system()
		var time_value = current_time.get("second", 0) + current_time.get("msec", 0) / 1000.0
		
		trail_points.append({
			"position": event.position,
			"time": time_value,
			"pressure": randf_range(0.8, 1.2)  # 模拟压力变化
		})
		
		# 清理过老的拖痕点
		var now = Time.get_time_dict_from_system()
		var now_value = now.get("second", 0) + now.get("msec", 0) / 1000.0
		trail_points = trail_points.filter(func(point): return now_value - point["time"] < trail_lifetime)
		
		queue_redraw()
		check_hit(event.position)

func _process(delta):
	swipe_timer += delta
	if swipe_timer > SWIPE_TIMEOUT:
		swipe_path.clear()
		trail_points.clear()
		queue_redraw()
	
	# 更新切割特效
	update_slice_effects(delta)

func _draw():
	# 绘制增强版拖痕
	if trail_points.size() > 1:
		var current_time_dict = Time.get_time_dict_from_system()
		var current_time = current_time_dict.get("second", 0) + current_time_dict.get("msec", 0) / 1000.0
		
		for i in range(trail_points.size() - 1):
			var point1 = trail_points[i]
			var point2 = trail_points[i + 1]
			
			# 根据时间计算透明度
			var alpha = 1.0 - (current_time - point1["time"]) / trail_lifetime
			alpha = clamp(alpha, 0.0, 1.0)
			
			# 根据压力计算宽度
			var width = trail_width * point1["pressure"] * alpha
			
			# 创建渐变色
			var base_color = Color.CYAN
			var edge_color = Color.YELLOW
			var color = base_color.lerp(edge_color, alpha)
			color.a = alpha * 0.8
			
			# 绘制带宽度的线段
			draw_line(point1["position"], point2["position"], color, width)
			
			# 添加内部高亮
			var inner_color = Color.WHITE
			inner_color.a = alpha * 0.6
			draw_line(point1["position"], point2["position"], inner_color, width * 0.3)
	
	# 绘制切割特效
	draw_slice_effects()

func check_hit(pos):
	# 获取世界空间状态
	var space_state = get_world_2d().direct_space_state
	
	# 创建查询参数
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	# 执行查询
	var results = space_state.intersect_point(query)
	
	if results.size() > 0:
		for result in results:
			var body = result["collider"]
			
			if body.is_in_group("cuttable"):
				# 检查是否有slice方法
				if body.has_method("slice"):
					body.slice()
					create_enhanced_slice_effect(pos)
					create_screen_shake()
					return
				else:
					# 检查动态西瓜
					var slice_method = body.get_meta("slice_method", null)
					if slice_method:
						slice_method.call()
						create_enhanced_slice_effect(pos)
						create_screen_shake()
						return

func create_enhanced_slice_effect(pos):
	print("增强切割特效位置: ", pos)
	
	# 添加到特效列表
	var effect = {
		"position": pos,
		"time": 0.0,
		"lifetime": 0.3,
		"rings": []
	}
	
	# 创建多个扩散环
	for i in range(3):
		effect.rings.append({
			"radius": 0.0,
			"max_radius": 30.0 + i * 15.0,
			"color": Color.YELLOW.lerp(Color.RED, i * 0.3),
			"delay": i * 0.1
		})
	
	slice_effects.append(effect)
	
	# 创建冲击波粒子
	create_impact_particles(pos)

func create_impact_particles(pos):
	var particles = CPUParticles2D.new()
	particles.position = pos
	
	# 粒子设置
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = 0.5
	particles.one_shot = true
	
	# 发射设置
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10.0
	
	# 粒子外观
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.8
	particles.color = Color.YELLOW
	
	# 物理设置
	particles.direction = Vector2(0, 0)  # 全方向发射
	particles.spread = 360.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.linear_accel_min = -100.0
	particles.linear_accel_max = -50.0
	
	add_child(particles)
	
	# 清理
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(particles.queue_free)
	particles.add_child(timer)
	timer.start()

func update_slice_effects(delta):
	for i in range(slice_effects.size() - 1, -1, -1):
		var effect = slice_effects[i]
		effect.time += delta
		
		# 更新每个环
		for ring in effect.rings:
			if effect.time > ring.delay:
				var ring_progress = (effect.time - ring.delay) / effect.lifetime
				ring.radius = ring.max_radius * ease_out_expo(ring_progress)
		
		# 清理过期特效
		if effect.time > effect.lifetime:
			slice_effects.remove_at(i)
	
	if slice_effects.size() > 0:
		queue_redraw()

func draw_slice_effects():
	for effect in slice_effects:
		for ring in effect.rings:
			if ring.radius > 0:
				var alpha = 1.0 - (effect.time / effect.lifetime)
				var color = ring.color
				color.a = alpha * 0.7
				
				# 绘制环形
				draw_arc(effect.position, ring.radius, 0, TAU, 32, color, 3.0)
				
				# 绘制内部填充（透明度更低）
				if ring.radius > 5:
					color.a = alpha * 0.2
					draw_arc(effect.position, ring.radius * 0.7, 0, TAU, 32, color, ring.radius * 0.6)

func ease_out_expo(x: float) -> float:
	return 1.0 - pow(2, -10 * x) if x != 1.0 else 1.0

func create_screen_shake():
	# 创建屏幕震动效果
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_pos = camera.global_position
		
		# 使用Timer序列来创建震动效果，而不是tween_delay
		_create_shake_sequence(camera, original_pos, 0)

func _create_shake_sequence(camera: Camera2D, original_pos: Vector2, shake_index: int):
	if shake_index >= 5:  # 震动5次后恢复
		var final_tween = camera.create_tween()
		final_tween.tween_property(camera, "global_position", original_pos, 0.1)
		return
	
	# 当前震动
	var shake_offset = Vector2(randf_range(-3, 3), randf_range(-3, 3))
	var shake_tween = camera.create_tween()
	shake_tween.tween_property(camera, "global_position", original_pos + shake_offset, 0.02)
	
	# 使用Timer创建下一次震动的延迟
	var shake_timer = Timer.new()
	shake_timer.wait_time = 0.02
	shake_timer.one_shot = true
	shake_timer.timeout.connect(func(): 
		_create_shake_sequence(camera, original_pos, shake_index + 1)
		shake_timer.queue_free()
	)
	add_child(shake_timer)
	shake_timer.start()

func play_swipe_start_sound():
	# 播放滑动开始音效
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# 这里需要添加实际的音效文件
	# var swipe_sound = preload("res://sounds/swipe_start.ogg")
	# audio_player.stream = swipe_sound
	# audio_player.play()
	
	audio_player.finished.connect(audio_player.queue_free)

func play_swipe_end_sound():
	# 播放滑动结束音效
	var audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	# 这里需要添加实际的音效文件
	# var swipe_sound = preload("res://sounds/swipe_end.ogg")
	# audio_player.stream = swipe_sound
	# audio_player.play()
	
	audio_player.finished.connect(audio_player.queue_free)
