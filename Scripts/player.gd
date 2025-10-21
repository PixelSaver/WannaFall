extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const GRAVITY = Vector3.DOWN * 20.
@export var mouse_sensitivity : float = .01
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@export var ray : RayCast3D
var hold_in_crosshair : Hold = null
var attracting_holds : Array[Hold] = []

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	attract_to_holds(delta)
	
	
	move_and_slide()
	
	if ray.is_colliding() and ray.get_collider() is Hold:
		hold_in_crosshair = ray.get_collider()
	else:
		hold_in_crosshair = null
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotation.y -= event.relative.x * mouse_sensitivity
		var rot_y = head.rotation.x - event.relative.y * mouse_sensitivity
		rot_y = clamp(rot_y, -PI/2., PI/2.)
		head.rotation.x = rot_y
	elif Input.is_action_pressed("left_click") and hold_in_crosshair:
		hold_in_crosshair.click_held = Hold.Click.LEFT
		attracting_holds.append(hold_in_crosshair)
	elif Input.is_action_just_released("left_click"):
		print("released")
		for hold in attracting_holds:
			if hold.click_held == Hold.Click.LEFT:
				attracting_holds.erase(hold)

var spring_strength:float = 30
var damping:float = 3
func attract_to_holds(delta:float):
	if attracting_holds.size() == 0: return
	for hold in attracting_holds:
		var vec_to = self.global_position.direction_to(hold.global_position)
		var dist = self.global_position.distance_to(hold.global_position)
		velocity += vec_to * dist * spring_strength * delta
		velocity -= velocity * damping * delta
		
