extends CharacterBody2D

const run_velocity = 300.0
const run_friction = 0.07
const jump_velocity = -350.0
const wall_jump_velocity = 100.0
const wall_friction = 0.3
const wall_hold_fall_velocity = 10.0
const max_fall_velocity = 500.0
const max_wall_slide_velocity = 250.0
const wall_jump_input_lockout = 0.35
const air_jumps = 1
const air_dashes = 2
const dash_velocity = 500.0
const max_dash_distance = 100.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var _animation_player = $AnimationPlayer
@onready var raycast_2d = $HighJumpRay
@onready var touch_right_ray = $TouchRightRay
@onready var touch_left_ray = $ToughLeftRay
@onready var health_bar = $HealthBar

var was_on_wall_only = false
var was_on_floor = false
var high_jump = false
var direction: float
var wall_jumped = false
var wall_jump_timer: float
var wall_jump_direction: float
var air_jumped = 0
var floor_jumped = false
var dashing = false
var air_dashed = 0
var direction_facing = 1
var dash_distance = 0.0
var max_air_velocity = 0.0
var health = 100

func _physics_process(delta):

	# Gravity
	if !is_on_floor():
		if is_on_wall_only():
			if is_pushing_wall():
				if !was_on_wall_only:
					velocity.y = 0
				else:
					velocity.y = wall_hold_fall_velocity
			else:
				if !floor_jumped:
					velocity.y = min(velocity.y + (gravity * delta * wall_friction), max_wall_slide_velocity)
				else:
					was_on_wall_only = false
					velocity.y = min(velocity.y + (gravity * delta), max_fall_velocity)
		elif dashing and !Input.is_action_pressed("ui_accept"):
			velocity.y = 0
		else:
			was_on_wall_only = false
			velocity.y = min(velocity.y + (gravity * delta), max_fall_velocity)
		was_on_floor = false
		if !raycast_2d.is_colliding():
			high_jump = true

	# L/R movement
	direction = Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		direction_facing = direction
	if !wall_jumped and !dashing:
		if direction:
			if is_on_floor():
				velocity.x = direction * run_velocity
			else:
				max_air_velocity = max(abs(velocity.x), abs(run_velocity))
				velocity.x = direction * max_air_velocity
		else:
			velocity.x = move_toward(velocity.x, 0, run_velocity * run_friction)
	elif wall_jumped:
		wall_jump_timer -= delta
		if direction == wall_jump_direction:
			velocity.x = direction * run_velocity
		else:
			velocity.x -= (wall_jump_direction * wall_jump_velocity) / wall_jump_input_lockout * delta
		if wall_jump_timer <= 0:
			wall_jumped = false

	# Jumping
	if is_on_floor() or is_on_wall():
		air_jumped = 0
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = jump_velocity
			floor_jumped = true
			lose_health(20)
		elif is_on_wall_only():
			wall_jump_direction = get_wall_normal()[0]
			velocity.y = jump_velocity
			velocity.x = wall_jump_direction * wall_jump_velocity
			wall_jumped = true
			wall_jump_timer = wall_jump_input_lockout
		elif air_jumped < air_jumps:
			velocity.y = jump_velocity
			air_jumped += 1
	if Input.is_action_just_released("ui_accept"):
		if velocity.y < 0:
			velocity.y = 0
		wall_jumped = false
		floor_jumped = false

	# Dashing
	if Input.is_action_just_pressed("ui_dash") and !dashing:
		if is_on_floor():
			velocity.x = dash_velocity * direction_facing
			dashing = true
		elif air_dashed < air_dashes:
			velocity.x = dash_velocity * direction_facing
			dashing = true
			air_dashed += 1
	elif dashing:
		dash_distance += dash_velocity * delta
		if dash_distance >= max_dash_distance:
			if is_on_floor():
				velocity.x = 0
			dashing = false
			dash_distance = 0
	if Input.is_action_just_released("ui_dash"):
		dashing = false
		dash_distance = 0
	if is_on_floor() or is_on_wall():
		air_dashed = 0

	# debug zone
	#print(_animation_player.get_current_animation()," at ",_animation_player.get_current_animation_position())
	#print(velocity.x,", ",velocity.y)
	#print(was_on_floor,", ",velocity.x)
	#print("is colliding: ", raycast_2d.is_colliding(), " collider body: ", raycast_2d.get_collision_point(), " collision normal: ", raycast_2d.get_collision_normal())
	#print("is on floor: ", is_on_floor(), " is on wall only: ", is_on_wall_only())
	#print(direction)
	#print(get_wall_normal()[0], " is on wall: ", is_on_wall(), get_position().x)
	#print(get_position().x)
	#print(direction_facing.target_position)
	#print(dash_distance)
	#print(velocity.x)
	#print(direction, ", ", ceil(get_wall_normal()[0]))
	#print(is_pushing_wall(), ", ", is_on_wall())
	#print("health: ", health, ", ", health_bar.value)
	update_animation()
	move_and_slide()
	update_health()

func update_animation():
	if direction != 0:
		animated_sprite_2d.flip_h = (direction < 0)
	if dashing:
		_animation_player.play("run")
		_animation_player.pause()
		_animation_player.seek(0.51,true)
	elif is_on_floor():
		if velocity.x != 0:
			_animation_player.play("run")
		else:
			if was_on_floor:
				if _animation_player.current_animation != "land":
					_animation_player.play("idle")
			else:
				if high_jump:
					_animation_player.play("land")
					_animation_player.queue("idle")
	elif !is_on_floor():
		if !is_on_wall():
			_animation_player.play("jump")
			_animation_player.pause()
			if velocity.y >= -100 and velocity.y <= 100:
				_animation_player.seek(0.1,true)
			if velocity.y < -100:
				_animation_player.seek(0.0,true)
			if velocity.y > 100:
				_animation_player.seek(0.2,true)
		else:
			if !was_on_wall_only:
				_animation_player.play("wall_land")
			elif velocity.y > 50:
				if _animation_player.current_animation != "wall_slide":
					_animation_player.play("wall_slide")
				else:
					_animation_player.play("wall_slide")
					_animation_player.pause()
					_animation_player.seek(0.35,true)

# conditional var reset
	if is_on_floor():
		was_on_floor = true
		high_jump = false
	if is_on_wall_only():
		was_on_wall_only = true
	if is_on_floor() or is_on_wall():
		max_air_velocity = 0.0

func is_pushing_wall():
	if (direction == -1 and touch_left_ray.is_colliding()) or (direction == 1 and touch_right_ray.is_colliding()):
		return true
	else:
		return false

func update_health():
	if health <= health_bar.min_value:
		health = health_bar.min_value
	if health >= health_bar.max_value:
		health = health_bar.max_value
	health_bar.value = health

func lose_health(damage):
	health -= damage
	update_health()

func gain_health(heal):
	health += heal
	update_health()
