extends Control

@onready var RubicsCube =%RubiksCube
var left_click_hold_start:Vector2

var speedUpForXTurns:int = -1 #used to randomize in max speed
var speed:float = 1.0 :set = set_speed

func set_speed(value):
	speed = value

func _process(_delta):
	if RubicsCube.executeMove(speed) == OK and speedUpForXTurns > 0:
		speedUpForXTurns -= 1
	if  speedUpForXTurns == 0:
		speedUpForXTurns = -1
		speed = %Speed.value
	RubicsCube.ifRubiksSolvedEmit()
	
func appendMoveToRubiks(move:String):
	RubicsCube.moves.append(move)
	

func _input(event):
	#3D rotate the rubiks 
	# ! Working progress
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				left_click_hold_start = get_local_mouse_position()
			else:
				left_click_hold_start=Vector2.ZERO
	elif left_click_hold_start  != Vector2.ZERO and event is InputEventMouseMotion:
		var mousePosition = get_local_mouse_position()
		var distace_moved=Vector2(mousePosition.x-left_click_hold_start.x,left_click_hold_start.y-mousePosition.y)
		distace_moved = distace_moved.clamp(Vector2(-3,-3),Vector2(3,3))
		%RotationBody.set_rotation_degrees(%RotationBody.rotation_degrees +Vector3(distace_moved.x,distace_moved.y,0))
	
	if event is InputEventKey and event.is_pressed():
		match event.physical_keycode:
			KEY_O:
				#reset rotationbody only by clicking O
				if ! event.is_command_or_control_pressed():
					%RotationBody.set_rotation_degrees(Vector3.ZERO)
			#maping keys to rubiks notation
			KEY_R:
				if event.shift_pressed:
					appendMoveToRubiks("R'")
				elif ! event.is_command_or_control_pressed():
					appendMoveToRubiks("R")
			KEY_L:
				if event.shift_pressed:
					appendMoveToRubiks("L'")
				elif ! event.is_command_or_control_pressed():
					appendMoveToRubiks("L")
			KEY_U:
				if event.shift_pressed:
					appendMoveToRubiks("U'")
				elif ! event.is_command_or_control_pressed():
					appendMoveToRubiks("U")
			KEY_D:
				if event.shift_pressed:
					appendMoveToRubiks("D'")
				elif ! event.is_command_or_control_pressed():
					appendMoveToRubiks("D")
			KEY_F:
				if event.shift_pressed:
					appendMoveToRubiks("F'")
				elif ! event.is_command_or_control_pressed():
					appendMoveToRubiks("F")
			KEY_B:
				if event.shift_pressed:
					appendMoveToRubiks("B'")
				elif ! event.is_command_or_control_pressed():
					appendMoveToRubiks("B")
			
	
func _on_reset_button_down():
	if ! RubicsCube.is_moving:
		var tempRotationBoby:Vector3 =%RotationBody.rotation_degrees
		%RotationBody.set_rotation_degrees(Vector3.ZERO)#prevent global_positioning errors
		RubicsCube.rubiksReset()
		%RotationBody.set_rotation_degrees(tempRotationBoby)
	
func randomizeRubiks():
	var randomizationTurns:int =20
	var allPossibleMoves=["R","L","U","D","F","B","R'","L'","U'","D'","F'","B'"]
	var randomMoves:Array=[]
	randomMoves.append_array(allPossibleMoves)
	randomMoves.append_array(allPossibleMoves)
	randomMoves.append_array(allPossibleMoves)
	randomize()
	randomMoves.shuffle()
	randomMoves.resize(randomizationTurns)
	RubicsCube.moves = randomMoves
	if %HideBeforeRandomize.button_pressed:
		RubicsCube.toggoleVisibilityForXTurns(false,randomizationTurns)
	speed = 4
	speedUpForXTurns = randomizationTurns
	
	
