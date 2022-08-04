tool
extends GridContainer
class_name ResponsiveGridContainer

export var max_columns: int = 0 setget setMaxColumns
export var auto_update_interval: float = 0 setget setAutoUpdateInterval

var get_width: FuncRef
var auto_update_timer: Timer = null

func _init(get_width_function: FuncRef):
	get_width = get_width_function

func _notification(what: int):
	if what == NOTIFICATION_SORT_CHILDREN:
		updateColumnCount()

func updateColumnCount():
	columns = min(max_columns, getIdealColunmCount())

func getIdealColunmCount() -> int:
	
	var ret: int = 0
	var total_width: float = 0.0
	var max_width: float = get_width.call_func()
	
	for child in get_children():
		
		if not child is Control:
			continue
		
		total_width += child.rect_min_size.x
		ret += 1
		
		if total_width >= max_width:
			break
	
	return int(max(1, ret - 1))

func setMaxColumns(value: int):
	if max_columns == value:
		return
	max_columns = value
	updateColumnCount()

func setAutoUpdateInterval(value: float):
	value = max(0.0, value)
	
	if value == auto_update_interval:
		return
	
	auto_update_interval = value
	
	if auto_update_interval == 0.0:
		if auto_update_timer != null:
			auto_update_timer.queue_free()
			auto_update_timer = null
	else:
		if auto_update_timer == null:
			auto_update_timer = Timer.new()
			auto_update_timer.one_shot = false
			auto_update_timer.connect("timeout", self, "updateColumnCount")
			add_child(auto_update_timer)
		
		if auto_update_timer.is_inside_tree():
			auto_update_timer.start(auto_update_interval)
		else:
			auto_update_timer.autostart = true
			auto_update_timer.wait_time = auto_update_interval
