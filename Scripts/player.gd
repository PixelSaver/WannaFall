extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var mouse_sensitivity : float = .01
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@export var ray : RayCast3D
var hold_in_crosshair : Hold = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

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

	move_and_slide()
	
	if ray.is_colliding() and ray.get_collider().get_parent() is Hold:
		print("FOUND HOLD")
		hold_in_crosshair = ray.get_collider().get_parent()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotation.y -= event.relative.x * mouse_sensitivity
		var rot_y = head.rotation.x - event.relative.y * mouse_sensitivity
		rot_y = clamp(rot_y, -PI/2., PI/2.)
		head.rotation.x = rot_y
