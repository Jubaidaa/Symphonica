extends CharacterBody2D

# ---------------------- CONSTANTS ----------------------
const SPEED = 500
const JUMP_VELOCITY = -900
const CUSTOM_GRAVITY = 2000

# Dash
const MAX_DASHES = 2
const DASH_SPEED = 1200
const DASH_DURATION = 0.2

# Sprint
const SPRINT_SPEED = 1000
const DECELERATION = 1500  # For dash & sprint direction changes

# Crouch
const CROUCH_SPEED = 300
const NORMAL_SCALE = Vector2(1, 1)
const CROUCH_SCALE = Vector2(0.8, 0.8)

# RectangleShape2D sizes for normal vs crouch
const NORMAL_COLLISION_SIZE = Vector2(32, 64)
const CROUCH_COLLISION_SIZE = NORMAL_COLLISION_SIZE * 0.8

# ---------------------- VARIABLES -----------------------
var dash_count = 0
var is_dashing = false
var dash_time_left = 0.0

var is_sprinting = false

var is_crouching = false

var collision_shape = null

func _ready():
	collision_shape = $CollisionShape2D
	# Ensure normal size on startup
	scale = NORMAL_SCALE
	collision_shape.shape.set_size(NORMAL_COLLISION_SIZE)

func _physics_process(delta):
	# 1) Gravity
	if not is_on_floor():
		velocity.y += CUSTOM_GRAVITY * delta
	else:
		# Reset dash count on floor
		dash_count = 0

	# 2) Jump
	if (Input.is_key_pressed(KEY_SPACE) and is_on_floor()) \
			or (Input.is_key_pressed(KEY_UP) and is_on_floor()):
		velocity.y = JUMP_VELOCITY

	# 3) Fast fall (optional)
	if Input.is_key_pressed(KEY_DOWN) and not is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY * -5

	# 4) Crouch logic (CTRL), only if on floor
	if is_on_floor():
		if Input.is_key_pressed(KEY_CTRL):
			if not is_crouching:
				start_crouch()
		else:
			if is_crouching:
				stop_crouch()

	# 5) Horizontal direction
	var direction = Input.get_axis("ui_left", "ui_right")

	# ------------------------------------------------------
	# 6) SINGLE KEY FOR DASH & SPRINT (SHIFT)
	#    BUT BLOCKED IF CROUCHING
	# ------------------------------------------------------
	if Input.is_key_pressed(KEY_SHIFT):
		# If NOT dashing, NOT sprinting, NOT crouching, and we have direction:
		if not is_dashing and not is_sprinting and not is_crouching and direction != 0:
			# Decide dash vs. sprint
			if dash_count < MAX_DASHES:
				perform_dash(direction)
			else:
				start_sprint()
	else:
		# SHIFT released => stop sprint if we were sprinting
		if is_sprinting:
			stop_sprint()

	# 7) Dash countdown
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false

	# 8) Movement: dash > sprint > crouch > normal
	if is_dashing:
		_apply_horizontal_velocity(direction, DASH_SPEED, delta)
	elif is_sprinting:
		_apply_horizontal_velocity(direction, SPRINT_SPEED, delta)
	else:
		# Crouch or normal
		if is_crouching:
			if direction != 0:
				velocity.x = direction * CROUCH_SPEED
			else:
				velocity.x = 0
		else:
			if direction != 0:
				velocity.x = direction * SPEED
			else:
				velocity.x = 0

	# 9) Move & slide
	move_and_slide()

#
# -------------------- Dash & Sprint ----------------------
#

func perform_dash(direction):
	# If crouching, skip
	if is_crouching:
		return

	is_dashing = true
	dash_count += 1
	dash_time_left = DASH_DURATION
	velocity.x = direction * DASH_SPEED

func start_sprint():
	# If crouching, skip
	if is_crouching:
		return

	is_sprinting = true

func stop_sprint():
	is_sprinting = false

# ----------------------- Crouch --------------------------

func start_crouch():
	is_crouching = true
	scale = CROUCH_SCALE
	collision_shape.shape.set_size(CROUCH_COLLISION_SIZE)

func stop_crouch():
	is_crouching = false
	scale = NORMAL_SCALE
	collision_shape.shape.set_size(NORMAL_COLLISION_SIZE)

# ------------- Horizontal Deceleration Helper ------------
func _apply_horizontal_velocity(direction, target_speed, delta):
	if direction == 0:
		# No input => decelerate to 0
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		return

	var desired_x = direction * target_speed
	if sign(desired_x) != sign(velocity.x) and abs(velocity.x) > 10:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, desired_x, DECELERATION * delta)
