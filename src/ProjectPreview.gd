extends Control
class_name ProjectPreview

signal EXPAND_REQUESTED
signal CONTRACT_START
signal CONTRACT_FINISH

const OPTIONAL_KEYS = ["name", "desc", "image"]

var main_element_container: Control
var expanded_project: Control = null
var contracting: bool = false

func init(data: Dictionary, _main_element_container: Control):
	
	main_element_container = _main_element_container
	
	for key in OPTIONAL_KEYS:
		if not key in data:
			data[key] = null
	
	if data["name"] != null:
		$MarginContainer/HBoxContainer/InfoColumn/TitleLabel.text = data["name"]
	else:
		$MarginContainer/HBoxContainer/InfoColumn/TitleLabel.queue_free()
	
	if data["desc"] != null:
		$MarginContainer/HBoxContainer/InfoColumn/DescLabel.text = data["desc"]
	else:
		$MarginContainer/HBoxContainer/InfoColumn/DescLabel.queue_free() 
	
	if data["image"] != null:
		$MarginContainer/HBoxContainer/MainImage.texture = load("res://" + data["image"])
	else:
		$MarginContainer/HBoxContainer/MainImage.queue_free()

func _ready():
	set_process(false)
	set_process_input(false)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE and expanded_project != null:
		contractProject()
		get_tree().set_input_as_handled()

func onPressed():
	emit_signal("EXPAND_REQUESTED")

func _process(delta: float):
	if expanded_project != null:
		
		if contracting:
			
			expanded_project.rect_size.x = lerp(expanded_project.rect_size.x, rect_size.x, delta * 10)
			expanded_project.rect_size.y = lerp(expanded_project.rect_size.y, rect_size.y, delta * 10)
			expanded_project.rect_global_position.x = lerp(expanded_project.rect_global_position.x, rect_global_position.x, delta * 10)
			expanded_project.rect_global_position.y = lerp(expanded_project.rect_global_position.y, rect_global_position.y, delta * 10)
			
			if abs(expanded_project.rect_size.x - rect_size.x) <= 1.0 and abs(expanded_project.rect_size.y - rect_size.y) <= 1.0:
				expanded_project.queue_free()
				expanded_project = null
				contracting = false
				set_process(false)
				emit_signal("CONTRACT_FINISH")
			
		else:
			var margins: Rect2 = Rect2(
				main_element_container.get("custom_constants/margin_left"), main_element_container.get("custom_constants/margin_top"),
				main_element_container.get("custom_constants/margin_right"), main_element_container.get("custom_constants/margin_bottom")
			)
			
			margins.size = main_element_container.rect_size - margins.size - margins.position
			
			expanded_project.rect_size.x = lerp(expanded_project.rect_size.x, margins.size.x, delta * 10)
			expanded_project.rect_size.y = lerp(expanded_project.rect_size.y, margins.size.y, delta * 10)
			expanded_project.rect_position.x = lerp(expanded_project.rect_position.x, margins.position.x, delta * 10)
			expanded_project.rect_position.y = lerp(expanded_project.rect_position.y, margins.position.y, delta * 10)
			
			if abs(expanded_project.rect_size.x - margins.size.x) <= 1.0 and abs(expanded_project.rect_size.y - margins.size.y) <= 1.0:
				expanded_project.rect_size = margins.size
				
				expanded_project.get_parent().remove_child(expanded_project)
				main_element_container.add_child(expanded_project)
				
				set_process(false)

func expandProject():
	expanded_project = duplicate(0)
	expanded_project.mouse_filter = Control.MOUSE_FILTER_STOP
#	expanded_project.disabled = true
	get_tree().root.add_child(expanded_project)
	expanded_project.rect_global_position = rect_global_position
	
	set_process(true)
	set_process_input(true)

func contractProject():
	assert(expanded_project != null)
	contracting = true
	set_process(true)
	emit_signal("CONTRACT_START")
