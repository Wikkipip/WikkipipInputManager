# WikkipipInputManager
WikkipipInputManager is an input wrapper for godot input events, specifically designed to differentiate between different devices activating an input action.
Can be used to directly replace default godot class [Input] and [method Node._input].
## Examples
Instead of using:
```
func _input(event):
    if Input.is_action_pressed("ui_accept"):
        print("Hello world!")
```
Instead, try this:
```
func _ready():
    InputManager.inputPressed.connect(inputPressed)

func inputPressed(actionName,deviceIndex):
    if actionName == "ui_accept":
        print("Hello world!")
```
