extends Node

var hunger := 50
var sugar := 50
var time_left := 30.0

# @onready表示 delay the initialization of a variable until the node containing it is added to the scene tree.
@onready var hunger_bar: ProgressBar = $"../UI/HungerBar"
@onready var glucose_bar: ProgressBar = $"../UI/GlucoseBar" 
@onready var timer_label: Label = $"../UI/TimerLabel"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_left -= delta
	timer_label.text = "Time: %.1f" % time_left
	if time_left <= 0:
		game_over(true)
	if hunger <= 0 or sugar >= 100:
		game_over(false)

func update_stats(h: int, s: int):
	hunger += h
	sugar += s
	hunger = clamp(hunger, 0, 100)
	sugar = clamp(sugar, 0, 100)
	hunger_bar.value = hunger
	glucose_bar.value = sugar

func game_over(success):
	# get_tree() 返回 SceneTree 这样一个 singleton instance，这样的 instance 只会在游戏的 runtime中出现一次
	get_tree().paused = true
	if success:
		print("通关啦！")
	else:
		print("完蛋：代谢失衡")

























