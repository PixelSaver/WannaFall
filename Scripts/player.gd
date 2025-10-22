extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 10
const GRAVITY = Vector3.DOWN * 20

@export_category("Holding Physics Tweaks")
@export var mouse_sensitivity: float = 0.01
@export var spring_strength: float = 100.0
@export var spring_damping: float = 0.85
@export var grab_range: float = 3.0
@export var min_hold_distance: float = 0.3

@export_category("Misc")
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@export var ray : RayCast3D

var hold_in_crosshair: Hold = null
var left_hand_hold: Hold = null
var right_hand_hold: Hold = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var is_grabbing = left_hand_hold != null or right_hand_hold != null
	
	# Cant gravitate during jump, the climbing forces deals with that
	if not is_grabbing and not is_on_floor():
		velocity += GRAVITY * delta

	# Handle jump, only on the ground
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_grabbing:
		# Climbing mode
		apply_climbing_forces(delta)
		
		# Smaller directional movement when grabbing??
		#TODO Try making this true in the air
		if direction:
			velocity += direction * SPEED * 0.3 * delta
		
		velocity *= spring_damping
	else:
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	
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
	
	# Left hand grab
	if Input.is_action_just_pressed("left_click"):
		if hold_in_crosshair and left_hand_hold == null:
			left_hand_hold = hold_in_crosshair
			left_hand_hold.click_held = Hold.Click.LEFT
	
	elif Input.is_action_just_released("left_click"):
		if left_hand_hold:
			left_hand_hold.click_held = Hold.Click.NONE
			left_hand_hold = null
	
	# Right hand grab
	if Input.is_action_just_pressed("right_click"):
		if hold_in_crosshair and right_hand_hold == null:
			right_hand_hold = hold_in_crosshair
			right_hand_hold.click_held = Hold.Click.RIGHT
	
	elif Input.is_action_just_released("right_click"):
		if right_hand_hold:
			right_hand_hold.click_held = Hold.Click.NONE
			right_hand_hold = null

func apply_climbing_forces(delta: float) -> void:
	var holds = [left_hand_hold, right_hand_hold].filter(func(h): return h != null)
	
	if holds.size() == 0:
		return
	
	# average target position
	var target_pos = Vector3.ZERO
	for hold in holds:
		target_pos += hold.global_position
	target_pos /= holds.size()
	
	var to_target = target_pos - global_position
	var distance = to_target.length()
	
	if distance > min_hold_distance:
		var spring_force = to_target.normalized() * spring_strength * (distance - min_hold_distance)
		velocity += spring_force * delta
	
	
	#velocity += -GRAVITY * delta
