extends CharacterBody2D

const UP_DIRECTION := Vector2.UP

# For movement
@export var speed := 100.0              # horizontal movement speed
@export var jump_strength := 350.0      # vertical jump strength
@export var gravity := 900.0            # force of gravity

var _has_jumped := false                # has character used up their jump
var _jumped_last_frame := false         # used to lower height of 1 frame jump
var _velocity := Vector2.ZERO           # used to deal with velocity without class variable

# For improved sense of control
@export var jump_buffer_time := 0.1     # Amount of time jump input is kept before touching ground
var _jump_buffer_timer := 0.0           # Amount of time since jump input was pressed
@export var coyote_time := 0.1          # Amount of time jump input is kept after touching ground
var _coyote_timer := 0.0                # Amount of time since ground was touched

# For animation
@onready var _pivot: Node2D = $PlayerSkin
@onready var _animation_player: AnimationPlayer = $PlayerSkin/AnimationPlayer
@onready var _start_scale: Vector2 = _pivot.scale
@onready var _raycasts: Array = [$RightOuterCast, $RightInnerCast, $LeftInnerCast, $LeftOuterCast]

# For saving
var _save_position : Vector2


func _physics_process(delta) -> void:
	# Jump
	_jump_buffer_timer -= delta
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	# Update coyote time
	_coyote_timer -= delta
	if is_on_floor():
		_coyote_timer = coyote_time
	
	# Read horizontal input
	var _horizontal_direction = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left"))
	
	# Head bump avoidance
	if _raycasts[0].is_colliding() and not (_raycasts[1].is_colliding() or _raycasts[2].is_colliding() or _raycasts[3].is_colliding()):
		global_position.x -= 5 #TODO: avoid magic numbers
	elif _raycasts[3].is_colliding() and not (_raycasts[2].is_colliding() or _raycasts[1].is_colliding() or _raycasts[0].is_colliding()):
		global_position.x += 5
	
	# Apply velocity changes
	_velocity.x = _horizontal_direction * speed
	_velocity.y += gravity * delta
	
	# Update state variables
	var is_falling := _velocity.y > 0.0 and not is_on_floor()
	var is_jumping := (Input.is_action_just_pressed("jump") \
		or _jump_buffer_timer > 0.0) and (is_on_floor() or _coyote_timer > 0.0)
	var is_jump_cancelled := Input.is_action_just_released("jump") and _velocity.y < 0.0 \
		or _jumped_last_frame and not Input.is_action_pressed("jump")
	var is_idling := is_on_floor() and is_zero_approx(_velocity.x)
	var is_running := is_on_floor() and not is_zero_approx(_velocity.x)
	_jumped_last_frame = is_jumping
	
	# Update state and move
	if is_jumping:
		_has_jumped = true
		_velocity.y = -jump_strength
	elif is_jump_cancelled:
		_velocity.y *= 0.5
	elif is_idling or is_running:
		_has_jumped = false
	set_velocity(_velocity)
	move_and_slide()
	_velocity = get_velocity()
	
	# Flip sprite
	if not is_zero_approx(_velocity.x):
		_pivot.scale.x = sign(_velocity.x) * _start_scale.x
	
	# Update animation
	if is_jumping:
		_animation_player.play("idle")
	elif is_running:
		_animation_player.play("idle")
	elif is_falling:
		_animation_player.play("idle")
	elif is_idling:
		_animation_player.play("idle")
		

func _ready():
	_save_position = global_position

#func _process(delta):
#	pass

func _die():
	print("died")
	global_position = _save_position


func _on_death_box_body_entered(_body):
	_die()
