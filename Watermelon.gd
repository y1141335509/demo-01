extends Node2D

@export var watermelon_scene: PackedScene
@onready var game_manager := $"../GameManager"

var spawn_timer: Timer
var is_spawning = false

func _ready():
	print("WatermelonSpawner ready")
	
	# Create and setup timer
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = 2.0
	spawn_timer.timeout.connect(_on_timer_timeout)

func start_spawning():
	print("Starting watermelon spawning")
	is_spawning = true
	if spawn_timer:
		spawn_timer.start()

func stop_spawning():
	print("Stopping watermelon spawning")
	is_spawning = false
	if spawn_timer:
		spawn_timer.stop()

func _on_timer_timeout():
	if not is_spawning:
		return
		
	print("Spawning watermelon...")
	spawn_watermelon()

func spawn_watermelon():
	if not watermelon_scene:
		print("Error: No watermelon scene assigned")
		return
		
	if not game_manager:
		print("Error: GameManager not found")
		return
	
	var watermelon = watermelon_scene.instantiate()
	
	# Set random position
	watermelon.position = Vector2(randf_range(100, 700), 600)
	watermelon.linear_velocity = Vector2(randf_range(-100, 100), randf_range(-600, -400))
	
	# Connect signal
	watermelon.connect("sliced", Callable(game_manager, "update_stats"))
	
	# Add to main scene (parent of this spawner)
	get_parent().add_child(watermelon)
	
	print("Watermelon spawned at: ", watermelon.position)
