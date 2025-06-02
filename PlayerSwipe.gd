extends Node2D


var swipe_path = []
var swipe_timer := 0.0		# sets variable initial value and type
var SWIPE_TIMEOUT := 0.2

func _unhandled_input(event):
	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		swipe_timer = 0.0
		swipe_path.append(event.position)
		check_hit(event.position)

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("cuttable") # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	swipe_timer += delta
	if swipe_timer > SWIPE_TIMEOUT:
		swipe_path.clear()

func check_hit(pos):
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_point(pos, 32)
	for item in result:
		if item.has("collider") and "cuttable" in item.collider:
			item.collider.slice()

































