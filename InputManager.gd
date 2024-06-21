extends Node
class_name WikkipipInputManager

#-------------------------------------------------------------------------------------------------#
##[br][b]KNOWN ISSUE.[/b] Scroll wheel inputs bound in the input map do not function. Instead, see [signal WikkipipInputManager.mouseEvent].
##
##[br]Device Index [param -1] is the Mouse and Keyboard
##[br]Device Index [param -2] is only used in [method WikkipipInputManager.getActionStrength], and can be used when referring to inputs from any/all devices.
##[br]Device Index [param -3] is only used in [method WikkipipInputManager.getActionStrength], and can be used to refer to every input device EXCEPT mouse and keyboard.
##[br]Other device indexs refer to game controllers plugged in during boot.
##[br]
##[br]WikkipipInputManager is an input wrapper for godot input events, specifically designed to differentiate between different devices activating an input action.
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
		if event is InputEventJoypadMotion and deviceIndex != -1:
				inputStrength *= event.axis_value #flips/rotates input strength relative to joypad axis direction
	
	emit_signal("inputEvent")
	
	if inputStrength >= deadzone:
		emit_signal("inputPressed",actionName,deviceIndex)
		INPUTS[actionName][deviceIndex] = inputStrength
	else:
		emit_signal("inputReleased",actionName,deviceIndex)
		INPUTS[actionName][deviceIndex] = 0

func getActionStrength(actionName: StringName, deviceIndex: int = -2) -> float: ##Returns the input strength of the device with index [param deviceIndex] relative to the corresponding action [param actionName].
	
	if deviceIndex == -2:
		var result = 0
		for deviceCheck in INPUTS[actionName]:
			
			result = max(result, INPUTS[actionName][deviceCheck])
		
		return result
	elif deviceIndex == -3:
		var result = 0
		for deviceCheck in INPUTS[actionName]:
			if deviceCheck == -1: continue
			result = max(result, INPUTS[actionName][deviceCheck])
		
		return result
	else:
		return INPUTS[actionName][deviceIndex]

var currentMouseVelocity: Vector2 = Vector2() ##Current relative velocity of mouse velocity. See [member InputEventMouseMotion.relative].
func getMouseVelocity() -> Vector2: ##Returns current relative velocity of mouse velocity. See [member InputEventMouseMotion.relative].
	return currentMouseVelocity

signal inputPressed(actionName: StringName, deviceIndex: int) ##Emitted when the input action [param actionName] just begins being pressed by device with index [param deviceIndex].
signal inputReleased(actionName: StringName, deviceIndex: int) ##Emitted when the input action [param actionName] just finishes being pressed by device with index [param deviceIndex].

signal mouseEvent(relative: Vector2) ##Emitted when the mouse is moved. See [member InputEventMouseMotion.relative].

signal inputEvent() ##Emitted when [signal WikkipipInputManager.inputPressed], [signal WikkipipInputManager.inputReleased], or [signal WikkipipInputManager.mouseEvent] are emitted.

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

func _process(_delta):
	currentMouseVelocity = currentMouseVelocity.lerp(Vector2(),0.5)

func _input(event): # Runs on every inputEvent
	emit_signal("inputEvent")
	
	var deviceIndex = event.device
	if event is InputEventWithModifiers: #If input is k&m, deviceIndex is set to -1
		deviceIndex = -1
	
	if event is InputEventMouseMotion: #If input is a mouse motion, emit mouseEvent signal
		currentMouseVelocity = event.relative
		emit_signal("mouseEvent",event)
	
	var inputStrength = 0
	if event is InputEventKey or event is InputEventJoypadButton:
		inputStrength = float(event.pressed) #Binary input based on button pressure
	if event is InputEventJoypadMotion:
		inputStrength = event.axis_value #Analog input based in button pressure. Ranges 0.0 - 1.0
	
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_WHEEL_UP) or (event.button_index == MOUSE_BUTTON_WHEEL_DOWN) or (event.button_index == MOUSE_BUTTON_WHEEL_LEFT) or (event.button_index == MOUSE_BUTTON_WHEEL_RIGHT):
			emit_signal("mouseEvent",event)
			return
		else:
			inputStrength = float(event.pressed)
	
	for actionName in InputMap.get_actions() : # Iterates through a list of the inputAction's names
		if event.is_action(actionName): # Checks if the inputEvent is for the given inputAction
			setActionStrength(actionName,deviceIndex,inputStrength) # Sets the events strength to the current inputStrength in the INPUTS dict
