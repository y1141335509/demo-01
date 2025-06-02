extends RigidBody2D

@export var hunger_value := 10		# make this varable configurable in Inspector
@export var sugar_value := 15

# signal规定 节点之间的通信没有直接的依赖关系
signal sliced(hunger: int, sugar: int)
var cuttable := true

func slice():
	if not cuttable:
		return 
	cuttable = false
	# emit_signal 是用来忽略之前定义的signal的，用来触发相关的方法
	emit_signal("sliced", hunger_value, sugar_value)
	queue_free()

