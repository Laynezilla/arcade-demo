extends CharacterBody2D

const run_velocity = 300.0
const run_friction = 0.04
const jump_velocity = -350.0
const wall_jump_velocity = 100.0
const wall_friction = 0.3
const wall_hold_fall_velocity = 10.0
const max_fall_velocity = 500.0
const max_wall_slide_velocity = 250.0
const wall_jump_input_lockout = 0.35
const air_jumps = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var _animation_player = $AnimationPlayer
@onready var raycast_2d = $RayCast2D
var was_on_wall_only = false
var was_on_floor = false
var high_jump = false
var direction: float
var wall_jumped = false
var wall_jump_timer: float
var wall_jump_direction: float
var air_jumped = 0
var floor_jumped = false

func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("ui_left", "ui_right")
	if !wall_jumped:
		if direction:
			velocity.x = direction * run_velocity
		else:
			velocity.x = move_toward(velocity.x, 0, run_velocity * run_friction)
	else:
		wall_jump_timer -= delta
		if direction == wall_jump_direction:
			velocity.x = direction * run_velocity
		else:
			velocity.x -= (wall_jump_direction * wall_jump_velocity) / wall_jump_input_lockout * delta
		if wall_jump_timer <= 0:
			wall_jumped = false

	# Add the gravity.
	if !is_on_floor():
		if is_on_wall_only():
			if direction+get_wall_normal()[0] == 0:
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
		else:
			was_on_wall_only = false
			velocity.y = min(velocity.y + (gravity * delta), max_fall_velocity)
		was_on_floor = false
		if !raycast_2d.is_colliding():
			high_jump = true

	# Handle jump.
	if is_on_floor() or is_on_wall():
		air_jumped = 0
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = jump_velocity
			floor_jumped = true
		elif is_on_wall_only():
			wall_jump_direction = get_wall_normal()[0]
			velocity.y = jump_velocity
			velocity.x = wall_jump_direction * wall_jump_velocity
			wall_jumped = true
			wall_jump_timer = wall_jump_input_lockout
		elif air_jumped < air_jumps:
			velocity.y = jump_velocity
			air_jumped += 1
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y = 0
		wall_jumped = false
		floor_jumped = false

	# debug zone
	#print(_animation_player.get_current_animation()," at ",_animation_player.get_current_animation_position())
	#print(velocity.x,", ",velocity.y)
	#print(was_on_floor,", ",velocity.x)
	#print("is colliding: ", raycast_2d.is_colliding(), " collider body: ", raycast_2d.get_collision_point(), " collision normal: ", raycast_2d.get_collision_normal())
	#print("is on floor: ", is_on_floor(), " is on wall only: ", is_on_wall_only())
	#print(direction)
	#print(get_wall_normal()[0], " is on wall: ", is_on_wall(), get_position().x)
	#print(get_position().x)
	update_animation()
	move_and_slide()

func update_animation():
	if direction != 0:
		animated_sprite_2d.flip_h = (direction < 0)
	if is_on_floor():
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
	if !is_on_floor():
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

	if is_on_floor():
		was_on_floor = true
		high_jump = false
	if is_on_wall_only():
		was_on_wall_only = true
