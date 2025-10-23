extends CharacterBody3D
class_name Player

signal can_grab(hold:Hold, left:Hold, right:Hold)

const SPEED = 5.0
const JUMP_VELOCITY = 10
const GRAVITY = Vector3.DOWN * 20

@export_category("Holding Physics Tweaks")
@export var mouse_sensitivity: float = 0.01
@export var spring_strength: float = 60.0
@export var spring_damping: float = 0.85
@export var swing_force: float = 15.
@export var grab_range: float = 3.0
@export var min_hold_distance: float = 0.3

@export_category("Air Control")
@export var air_control: float = 0.15
@export var air_drag: float = 0.98 

@export_category("Stamina")
@export var max_stamina: float = 10.0
## Per second when hanging
@export var stamina_drain_rate: float = 1.0
## Per second when grounded or both hands free
@export var stamina_regen_rate: float = 2.0  
## Extra stamina used when jumping
@export var grab_jump_stamina_cost: float = 1.0
@export var grab_jump_force: float = 8.0
## Stamina waits to regen until this cooldown is over
@export var grab_jump_cooldown: float = 0.15  

var l_stamina: float = 10.0
var r_stamina: float = 10.0
var l_can_grab: bool = true
var r_can_grab: bool = true

@export_category("Misc")
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@export var ray : RayCast3D

var hold_in_crosshair: Hold = null
var left_hand_hold: Hold = null
var right_hand_hold: Hold = null
var is_grabbing : bool = false

enum ClimbState { GROUND, HANGING, PULLING_UP, AIR }
var climb_state = ClimbState.GROUND

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	l_stamina = max_stamina
	r_stamina = max_stamina

func _physics_process(delta: float) -> void:
	if ray.is_colliding() and ray.get_collider() is Hold:
		hold_in_crosshair = ray.get_collider()
	else:
		hold_in_crosshair = null
	can_grab.emit(hold_in_crosshair, left_hand_hold, right_hand_hold)
	
	is_grabbing = left_hand_hold != null or right_hand_hold != null
	
	if is_grabbing:
		handle_climbing_movement(delta)
	elif is_on_floor():
		handle_ground_movement(delta)
	else:
		handle_air_movement(delta)
	
	update_stamina(delta)
	
	move_and_slide()

func update_stamina(delta:float):
	var is_hanging:bool = (left_hand_hold != null or right_hand_hold != null) and not is_on_floor()
	var both_hands_holding:bool = left_hand_hold != null and right_hand_hold != null
	
	if is_hanging:
		var drain = stamina_drain_rate * delta
		
		# Spreads stamina rate across both hands
		if both_hands_holding:
			drain *= .5
		
		if left_hand_hold:
			l_stamina = max(0, l_stamina - drain)
		if right_hand_hold:
			r_stamina = max(0, r_stamina - drain)
	elif is_on_floor():
		if not left_hand_hold:
			l_stamina = min(max_stamina, l_stamina + stamina_regen_rate*delta)
		if not right_hand_hold:
			r_stamina = min(max_stamina, r_stamina + stamina_regen_rate*delta)
	

func handle_ground_movement(delta:float):
	climb_state = ClimbState.GROUND
	
	# Apply gravity
	if not is_on_floor():
		velocity += GRAVITY * delta
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Movement
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

func handle_air_movement(delta: float):
	climb_state = ClimbState.AIR
	
	velocity += GRAVITY * delta
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# air_control makes control less responsive in air
	if direction:
		velocity.x += direction.x * SPEED * air_control * delta
		velocity.z += direction.z * SPEED * air_control * delta
	
	velocity.x *= air_drag
	velocity.z *= air_drag
	
	# Cap horizontal
	var horizontal_vel = Vector2(velocity.x, velocity.z)
	var max_air_speed = SPEED * 1.5
	if horizontal_vel.length() > max_air_speed:
		horizontal_vel = horizontal_vel.normalized() * max_air_speed
		velocity.x = horizontal_vel.x
		velocity.z = horizontal_vel.y

func handle_climbing_movement(delta:float):
	var holds = [left_hand_hold, right_hand_hold].filter(func(h): return h != null)
	
	if holds.size() == 0:
		return
	
	# average target position
	var target_pos = Vector3.ZERO
	for hold in holds:
		target_pos += hold.global_position
	target_pos /= holds.size()
	
	# Distinction between going up and hanging
	var is_pulling_up = -head.rotation.x > 0.5
	if is_pulling_up:
		climb_state = ClimbState.PULLING_UP
	else:
		climb_state = ClimbState.HANGING
	
	velocity += GRAVITY * delta * 0.3
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (head.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity += direction * swing_force * delta
	
	var to_target = target_pos - global_position
	var distance = to_target.length()
	
	if distance > min_hold_distance:
		var spring_force = to_target.normalized() * spring_strength * (distance - min_hold_distance)
		if is_pulling_up:
			spring_force *= 2.0
		velocity += spring_force * delta
	
	var damping = 0.92 if is_pulling_up else spring_damping
	velocity *= damping
	
	# Handle jump, only on the ground
	if Input.is_action_just_pressed("jump") and is_on_floor():
		#TODO Implement grab jump, so jump from hold
		#perform_grab_jump
		pass
		velocity.y = JUMP_VELOCITY

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
