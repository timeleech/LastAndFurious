extends CharacterBody3D

@export var gravity = -20.0
@export var wheel_base = 1  # distance between front/rear axles
@export var steering_limit = 4.0  # front wheel max turning angle (deg)
@export var engine_power = 50.0
@export var braking = -5.0
@export var friction = -2.0
@export var drag = -2.0	
@export var max_speed_reverse = 15.0
@export var gas = 500

var acceleration = Vector3.ZERO  # current acceleration
var steer_angle = 0.0  # current wheel angle

@export var slip_speed = 9.0
@export var traction_slow = 0.75
@export var traction_fast = 0.02

var drifting = false

func _physics_process(delta):
	if is_on_floor():
		get_input()
		apply_friction(delta)
		calculate_steering(delta)
	acceleration.y = gravity
	velocity += acceleration * delta
	move_and_slide()
	if $FrontRay.is_colliding() or $RearRay.is_colliding():
		var nf = $FrontRay.get_collision_normal() if $FrontRay.is_colliding() else Vector3.UP
		var nr = $RearRay.get_collision_normal() if $RearRay.is_colliding() else Vector3.UP
		var n = ((nr + nf) / 2.0).normalized()
		var xform = align_with_y(global_transform, n)
		global_transform = global_transform.interpolate_with(xform, 0.1)
	
func apply_friction(delta):
	if velocity.length() < 0.2 and acceleration.length() == 0:
		velocity.x = 0
		velocity.z = 0
	var friction_force = velocity * friction * delta
	var drag_force = velocity * velocity.length() * drag * delta
	acceleration += drag_force + friction_force
	
func calculate_steering(delta):
	var rear_wheel = transform.origin + transform.basis.z * wheel_base / 2.0
	var front_wheel = transform.origin - transform.basis.z * wheel_base / 2.0
	rear_wheel += velocity * delta
	front_wheel += velocity.rotated(transform.basis.y, steer_angle) * delta
	var new_heading = rear_wheel.direction_to(front_wheel)
	var d = new_heading.dot(velocity.normalized())
	
	if not drifting and velocity.length() > slip_speed:
		drifting = true
	if drifting and velocity.length() < slip_speed and steer_angle == 0:
		drifting = false
	var traction = traction_fast if drifting else traction_slow
	
	if d > 0:
		velocity = lerp(velocity, new_heading * velocity.length(), traction)
	if d < 0:
		velocity = -new_heading * min(velocity.length(), max_speed_reverse)
	look_at(transform.origin + new_heading, transform.basis.y)	

func get_input():
	var turn = Input.get_action_strength("steer_left")
	turn -= Input.get_action_strength("steer_right")
	steer_angle = turn * deg_to_rad(steering_limit)
	$Bus/bus_wheel_fr.rotation.y = steer_angle*2
	$Bus/bus_wheel_fl.rotation.y = steer_angle*2
	acceleration = Vector3.ZERO
	if Input.is_action_pressed("accelerate"):
		acceleration = -transform.basis.z * engine_power
		%idle.playing = false
		if not %moving.is_playing():
			%moving.play()
	else:
		if not %idle.is_playing():
			%idle.play()
			%moving.playing = false
	if Input.is_action_pressed("brake"):
		acceleration = -transform.basis.z * braking
	if Input.is_action_pressed("slow-mo") and gas > 0:
		Engine.time_scale = 0.7
	else: Engine.time_scale = 1

		
	if Input.is_action_just_pressed("boost") and gas > 0:
		engine_power = 10000
		%boost.play()
		gas -= 75
	else:
		engine_power = 50
	if Input.is_action_pressed("SQUASH"):
		Input.action_press("slow-mo")
		$body.disabled = true
		$Bus.scale.x == 3
		$front.disabled = true
		$back.disabled = true
		$squashed.disabled = false
	else:
		$body.disabled = false
		$front.disabled = false
		$back.disabled = false
		$squashed.disabled = true
		

func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform
