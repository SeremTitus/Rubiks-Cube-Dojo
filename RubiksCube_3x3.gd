extends Node3D

signal rubiks_Solved
	
@onready var AnimatePivot = %AnimatePivot
@onready var TempCubes =%TempCubes
@onready var MovesLabel =%MovesLabel
	
@onready var pivots=[%BasePivot, %TopPivot, %LeftPivot, %RightPivot, %FrontPivot, %BackPivot]
@onready var detectors=[%BaseDetect, %TopDetect, %LeftDetect, %RightDetect, %FrontDetect, %BackDetect]
@onready var rubiks3x3Notation= {
	#Notation: Pivot,Detector,rotation_Angle
	"R":[pivots[3],detectors[3],Vector3(-90,0,0)],
	"L":[pivots[2],detectors[2],Vector3(90,0,0)],
	"U":[pivots[1],detectors[1],Vector3(0,90,0)],
	"D":[pivots[0],detectors[0],Vector3(0,-90,0)],
	"F":[pivots[4],detectors[4],Vector3(0,0,90)],
	"B":[pivots[5],detectors[5],Vector3(0,0,-90)],
	}
@export var moves:Array#append here moves for the cube to move
@export var is_moving = false
@export var onreadyPivotsAndDetectorsPosition:Dictionary

var toggoleVisibilityTurnsX:int = -1

func _ready():
	#Set onreadyPivotsAndDetectorsPosition used to reset cube
	var PivotsAndDetectors:Array = []
	PivotsAndDetectors.append_array(pivots)
	PivotsAndDetectors.append_array(detectors)
	for PivotOrDetector in PivotsAndDetectors:
		onreadyPivotsAndDetectorsPosition[PivotOrDetector]=PivotOrDetector.global_transform
		
	
func cubesAddToPivot(Detector:Area3D ,Pivot:PinJoint3D):
	var cubes = Detector.get_overlapping_areas()
	for cube in cubes:
		cube.get_parent_node_3d().reparent(Pivot)
	
func allCubesRemoveFromPivot():
	for pivot in pivots:
		for cube in pivot.get_children() :
			cube.reparent(TempCubes)
		pivot.rotation_degrees = Vector3.ZERO
	
func rotatePivot(Pivot:PinJoint3D ,faceRotation :Vector3=Vector3.ZERO, times=1 ,Speed:float =1.0):
	if AnimatePivot.has_animation_library("FromScript"):
		AnimatePivot.remove_animation_library("FromScript")
	var newAnimation = Animation.new()
	newAnimation.add_track(Animation.TYPE_VALUE)
	newAnimation.track_set_path(0,NodePath(str(Pivot.get_path())+":rotation_degrees"))
	newAnimation.set_length((0.5*times))
	newAnimation.track_insert_key(0,0,Vector3.ZERO)
	newAnimation.track_insert_key(0,(newAnimation.get_length()-0.05),faceRotation*times)
	var newAnimLib = AnimationLibrary.new()
	newAnimLib.add_animation("new_anim"+str(times),newAnimation)#add str(times)as  work around to correct count error when substracting from toggoleVisibilityTurnsX
	AnimatePivot.add_animation_library("FromScript",newAnimLib)
	AnimatePivot.play("FromScript/new_anim"+str(times),-1,Speed)

func executeMove(speed:float = 1.0):
	#Only multiple repeated call in _physics_process(delta) or _process(delta) never in a loop
	#since Animation node resolves signal independly, loops lead to deadlock
	if is_moving or moves.is_empty():
		return FAILED
	var move:String = moves.pop_front()
	move.capitalize()
	var times:int=1
	var count:int = 0
	if len(moves) != 0:# Find series of moves similar to the current move
		while count < len(moves) and move == moves[count]:
			moves.pop_front()
			times += 1
			count += 1
	if move != null:
		var detector:Area3D
		var pivot:PinJoint3D
		var faceRotation:Vector3
		# Nesting ifs to detect prime of notations eg R' ,L" and set rotation to inverse
		if  ! rubiks3x3Notation.has(move):
			if len(move) == 2:
				if rubiks3x3Notation.has(move[0]) and move[1]=="'":
					detector = rubiks3x3Notation[move[0]][1]
					pivot = rubiks3x3Notation[move[0]][0]
					faceRotation =Vector3(int("-"+str(rubiks3x3Notation[move[0]][2].x)),int("-"+str(rubiks3x3Notation[move[0]][2].y)),int("-"+str(rubiks3x3Notation[move[0]][2].z)))
				else:
					return FAILED
			else:
				return FAILED
		else:
			detector = rubiks3x3Notation[move][1]
			pivot = rubiks3x3Notation[move][0]
			faceRotation =rubiks3x3Notation[move][2]
		#endif
		var sucessfullReparenting:bool = false
		var tolerance:int =0
		while ! sucessfullReparenting:
			#avoid reparenting issues
			allCubesRemoveFromPivot()
			cubesAddToPivot(detector,pivot)
			if pivot.get_child_count() == 9:
				sucessfullReparenting = true
			tolerance += 1
			if tolerance > 10 : return FAILED
		is_moving = true
		MovesLabel.text=""
		MovesLabel.text=move
		if times > 1:
			MovesLabel.text += str(times)
		rotatePivot(pivot,faceRotation,times,speed)
		return OK
	
func allCubesOfRubiks():
	var cubes:Array =[]
	var cubeareas:Array =[]
	for Detector in detectors:
		cubeareas.append_array(Detector.get_overlapping_areas())
	for cubearea in cubeareas:
		cubes.append(cubearea.get_parent_node_3d())
	return cubes
	
func ifRubiksSolvedEmit():
	var cubes:Array=allCubesOfRubiks()
	for cube in cubes:
		if cube.solved_position != cube.global_transform: return
	emit_signal("rubiks_Solved")
	
func  rubiksReset():
	if is_moving:
		return
	var cubes:Array=allCubesOfRubiks()
	for PivotOrDetector in onreadyPivotsAndDetectorsPosition:
		PivotOrDetector.global_transform = onreadyPivotsAndDetectorsPosition[PivotOrDetector]
	for cube in cubes:
		cube.global_transform = cube.solved_position
	moves.clear()
	
func toggoleVisibilityForXTurns(value:bool=!self.visible,X:int = 0):
	self.visible = value
	%Display.visible = value
	if X > 0:
		toggoleVisibilityTurnsX = X
	
func _on_animate_pivot_animation_finished(anim_name):
	MovesLabel.text=""
	is_moving = false
	#work around to turn to hide rubiks :used for hidden randomization
	var times:int = int(anim_name.erase(0,8))
	if toggoleVisibilityTurnsX > 0:
		toggoleVisibilityTurnsX -= 1*times
	if toggoleVisibilityTurnsX == 0:
		toggoleVisibilityForXTurns()
		toggoleVisibilityTurnsX -= 1
	
