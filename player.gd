extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -350.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var _animation_player = $AnimationPlayer

func _physics_process(delta):

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	update_animation(direction,is_on_floor(),velocity.x,velocity.y,is_on_wall(),false,false)
	move_and_slide()

# wall animation not working right now
# need a way to set touched_ground and touched_wall variables. kinda looks like we need a finite state machine? idk
func update_animation(direction,on_ground,velocity_x,velocity_y,on_wall,touched_ground,touched_wall):
	if direction != 0:
		animated_sprite_2d.flip_h = (direction < 0)
	if on_ground:
		if velocity_x == 0 and !touched_ground:
			_animation_player.play("idle")
		elif velocity_x == 0 and touched_ground:
			_animation_player.play("land")
			_animation_player.queue("idle")
		elif velocity_x != 0:
			_animation_player.play("run")
	if !on_ground:
		if !on_wall:
			_animation_player.play("jump")
			_animation_player.pause()
			if velocity_y == 0:
				_animation_player.seek(0.1,true)
			if velocity_y > 0:
				_animation_player.seek(0.0,true)
			if velocity_y < 0:
				_animation_player.seek(0.2,true)
		else:
			if touched_wall:
				_animation_player.play("wall_land")
			else:
				_animation_player.play("wall_slide")
