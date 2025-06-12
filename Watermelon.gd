extends RigidBody2D

@export var hunger_value := 10		# make this varable configurable in Inspector
@export var sugar_value := 15

# signal规定 节点之间的通信没有直接的依赖关系
signal sliced(hunger: int, sugar: int)
var cuttable := true

func _ready():
	# 在游戏开始后，确保所有的西瓜都受到重力的影响
	gravity_scale = 1.0
	
	# 设置碰撞层，确保可以被检测到
	collision_layer = 1
	collision_mask = 1

func slice():
	if not cuttable:
		return 
	cuttable = false
	# emit_signal 是用来忽略之前定义的signal的，用来触发相关的方法
	emit_signal("sliced", hunger_value, sugar_value)
	
	# 添加切开的视觉效果
	modulate = Color.RED
	
	# 删除延迟，让玩家看到效果
	var timer = Timer.new()
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	queue_free()
	timer.start()
	

