extends Node
class_name WikkipipInputManager

#-------------------------------------------------------------------------------------------------#

##Device Index [param -1] is the Mouse and Keyboard
##
##A wrapper for godot input events, specifically designed to differentiate between different devices activating an input action.
##[br]Can be used to directly replace default godot class [Input] and [method Node._input].
##Example, instead of using:
##[codeblock]
##func _input(event):
##    if Input.is_action_pressed("ui_accept"):
##        print("Hello world!")
##[/codeblock]
##Instead, try this:
##[codeblock]
##func _ready():
##    InputManager.inputPressed.connect(inputPressed)
##
##func inputPressed(actionName,deviceIndex):
##    if actionName == "ui_accept":
##        print("Hello world!")
##[/codeblock]

#-------------------------------------------------------------------------------------------------#

func setActionStrength(actionName: StringName, deviceIndex: int, inputStrength: float) -> void: ##[b]PRIVATE METHOD.[/b][br]Used privatley to set input strengths accessible by calling [method WikkipipInputManager.getActionStrength()].
	
	var deadzone = InputMap.action_get_deadzone(actionName) #Finds the already set deadzone (usually 0.5)
	
	for event in InputMap.action_get_events(actionName): #Iterates through all inputEvents that can trigger the inputAction
		if deviceIndex != -1: #If input device isnt keyboard or mouse
			if event is InputEventJoypadMotion:
				inputStrength *= event.axis_value #flips/rotates input strength relative to joypad axis direction
	
	emit_signal("inputEvent")
	
	if inputStrength >= deadzone:
		emit_signal("inputPressed",actionName,deviceIndex)
		INPUTS[actionName][deviceIndex] = inputStrength
	else:
		emit_signal("inputReleased",actionName,deviceIndex)
		INPUTS[actionName][deviceIndex] = 0

func getActionStrength(actionName: StringName, deviceIndex: int) -> bool: ##Returns the input strength of the device with index [param deviceIndex] relative to the corresponding action [param actionName].
	return INPUTS[actionName][deviceIndex]

var currentMouseVelocity: Vector2 = Vector2() ##Current relative velocity of mouse velocity. See [member InputEventMouseMotion.relative].
func getMouseVelocity() -> Vector2: ##Returns current relative velocity of mouse velocity. See [member InputEventMouseMotion.relative].
	return currentMouseVelocity

signal inputPressed(actionName: StringName, deviceIndex: int) ##Emitted when the input action [param actionName] just begins being pressed by device with index [param deviceIndex].
signal inputReleased(actionName: StringName, deviceIndex: int) ##Emitted when the input action [param actionName] just finishes being pressed by device with index [param deviceIndex].

signal mouseMotion(relative: Vector2, velocity: Vector2) ##Emitted when the mouse is moved. See [member InputEventMouseMotion.relative] and [member InputEventMouseMotion.velocity].

signal inputEvent() ##Emitted when [signal WikkipipInputManager.inputPressed], [signal WikkipipInputManager.inputReleased], or [signal WikkipipInputManager.mouseMotion] are emitted.

@export var INPUTS: Dictionary = { ##[b]PRIVATE VARIABLE. DO NOT DIRECTLY ACCESS.[/b][br]Use [method WikkipipInputManager.setActionStrength] and [method WikkipipInputManager.getActionStrength] to access instead.
#	actionName = {
#		deviceIndex = inputStrength
#	}
}

#-------------------------------------------------------------------------------------------------#

func _init(): # Runs at initiation of project
	
	var connectedDevices = Input.get_connected_joypads()
	connectedDevices.insert(0,-1)
	
	for actionName in InputMap.get_actions(): # Iterates through a list of the inputAction's names
		INPUTS[actionName] = {}
		for deviceIndex in connectedDevices: # Iterates through a list of connected devices
			for event in InputMap.action_get_events(actionName): # Iterates through a list of inputEvents for the inputAction
				setActionStrength(actionName,deviceIndex,0) # Sets the value of the actionName to 0 based on device

func _input(event): # Runs on every inputEvent
	emit_signal("inputEvent")
	
	var deviceIndex = event.device
	if event is InputEventWithModifiers: #If input is k&m, deviceIndex is set to -1
		deviceIndex = -1
	
	if event is InputEventMouseMotion: #If input is a mouse motion, emit mouseMotion signal
		currentMouseVelocity = event.relative
		emit_signal("mouseMotion",event.relative,event.velocity)
	
	var inputStrength = 0
	if event is InputEventKey:
		inputStrength = float(event.pressed) #inputStrength is 1.0 or 0.0 if key is pressed or not
	if event is InputEventJoypadButton:
		inputStrength = event.pressure #inputStrength ranges from 0.0 - 1.0
	if event is InputEventJoypadMotion:
		inputStrength = event.axis_value #inputStrength = 1.0 or 0.0 if key is pressed or not
	
	for actionName in InputMap.get_actions() : # Iterates through a list of the inputAction's names
		if event.is_action(actionName): # Checks if the inputEvent is for the given inputAction
			setActionStrength(actionName,deviceIndex,inputStrength) # Sets the events strength to the current inputStrength in the INPUTS dict
