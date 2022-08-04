extends ScrollContainer

const CONFIG_PATH = "res://config.json"
const PROJECT_PREVIEW: PackedScene = preload("res://src/ProjectPreview.tscn")
const SCROLL_INCREMENT: float = 100.0

const PROJECT_GRID_SEPARATION: float = 15.0
const PROJECT_GRID_COLUMNS: int = 3
const MARGIN_H: float = 40.0
const MARGIN_V: float = 20.0

onready var project_container: VBoxContainer = $MarginContainer/VBoxContainer/ProjectContainer
onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
onready var subtitle_label: Label = $MarginContainer/VBoxContainer/SubtitleLabel
onready var project_fade_tween: Tween = $ProjectFadeTween
onready var expanded_element_container: Container = $CanvasLayer/MarginContainer

var config: Dictionary = {}
var scroll_target: float = 0.0

var expanded_project: ProjectPreview = null

func _ready():
	var error: int = loadConfig()
	if error != OK:
		get_tree().quit(error)
	
	get_v_scrollbar().connect("scrolling", self, "vScrolling")
	
	for property in ["custom_constants/margin_right", "custom_constants/margin_left"]:
		$MarginContainer.set(property, MARGIN_H)
		expanded_element_container.set(property, MARGIN_H)
	for property in ["custom_constants/margin_top", "custom_constants/margin_bottom"]:
		$MarginContainer.set(property, MARGIN_V)
		expanded_element_container.set(property, MARGIN_V)
	
	prepareScene()

func _process(delta: float):
	scroll_vertical = lerp(scroll_vertical, scroll_target, delta * 10.0)

func _input(event: InputEvent):
	
	if event is InputEventKey and event.pressed:
		match event.scancode:
			KEY_F11:
				OS.window_fullscreen = !OS.window_fullscreen
				return
			KEY_UP:
				if expanded_project == null:
					scroll_target = clamp(scroll_target - SCROLL_INCREMENT, 0, $MarginContainer/VBoxContainer.rect_size.y - rect_size.y)
			KEY_DOWN:
				if expanded_project == null:
					scroll_target = clamp(scroll_target + SCROLL_INCREMENT, 0, $MarginContainer/VBoxContainer.rect_size.y - rect_size.y)
	
	elif event is InputEventMouseButton and event.pressed and expanded_project == null:
		if event.button_index == BUTTON_WHEEL_UP:
			scroll_target = clamp(scroll_target - SCROLL_INCREMENT, 0, $MarginContainer/VBoxContainer.rect_size.y - rect_size.y)
			get_tree().set_input_as_handled()
		elif event.button_index == BUTTON_WHEEL_DOWN:
			scroll_target = clamp(scroll_target + SCROLL_INCREMENT, 0, $MarginContainer/VBoxContainer.rect_size.y - rect_size.y)
			get_tree().set_input_as_handled()

func loadConfig() -> int:
	
	var file: File = File.new()
	
	var error: int = file.open(CONFIG_PATH, File.READ)
	if error != OK:
		push_error("An error occurred while attempting to read config file at " + CONFIG_PATH + ": " + str(error))
		return error
	
	config = parse_json(file.get_as_text())
	file.close()
	
	for key in ["title", "subtitle", "projects"]:
		if not key in config:
			config[key] = null
	
	return OK

func prepareScene():
	
	if config["title"] != null:
		title_label.text = config["title"]
		title_label.visible = true
	else:
		title_label.visible = false
	
	if config["subtitle"] != null:
		subtitle_label.text = config["subtitle"]
		title_label.visible = true
	else:
		title_label.visible = false
	
	for node in project_container.get_children():
		disconnect("resized", node, "updateColumnCount")
		node.queue_free()
	
	if config["projects"] != null:
		
		var years: Dictionary = {}
		
		for project_data in config["projects"]:
			
			var year: int
			if not "year" in project_data or project_data["year"] == null:
				year = 0
			else:
				year = project_data["year"]
			
			var year_node: Control
			
			if year in years:
				year_node = years[year]
			else:
				year_node = VBoxContainer.new()
				year_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				year_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
				
				var year_label: Label = Label.new()
				year_label.text = str(year) if year > 0 else "Unknown"
				
				var font: DynamicFont = DynamicFont.new()
				font.size = 25
				font.font_data = preload("res://fonts/Montserrat-Light.ttf")
				year_label.set("custom_fonts/font", font)
				
				year_node.add_child(year_label)
				
				var project_grid: ResponsiveGridContainer = ResponsiveGridContainer.new(funcref(self, "getMainViewWidth"))
				connect("resized", project_grid, "updateColumnCount")
				
				for property in ["custom_constants/hseparation", "custom_constants/vseparation"]:
					project_grid.set(property, PROJECT_GRID_SEPARATION)
				project_grid.auto_update_interval = 1 if OS.get_name() == "HTML5" else 0
				project_grid.max_columns = PROJECT_GRID_COLUMNS
				project_grid.columns = PROJECT_GRID_COLUMNS
				project_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				project_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
				year_node.add_child(project_grid)
				
				years[year] = year_node
				year_node.name = str(year)
			
			var project: ProjectPreview = PROJECT_PREVIEW.instance()
			project.init(project_data, $CanvasLayer/MarginContainer)
			
			project.connect("EXPAND_REQUESTED", self, "onProjectExpandRequested", [project])
			project.connect("CONTRACT_START", self, "onProjectContracting", [project, false])
			project.connect("CONTRACT_FINISH", self, "onProjectContracting", [project, true])
			
			year_node.get_child(1).add_child(project)
		
		var years_sorted: Array = years.keys()
		years_sorted.sort()
		years_sorted.invert()
		for year in years_sorted:
			project_container.add_child(years[year])

func onProjectExpandRequested(project: ProjectPreview):
	if expanded_project != null:
		return
	
	expanded_project = project
	expanded_project.expandProject()
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_v_scrollbar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	setProjectsVisible(false)

func onProjectContracting(project: ProjectPreview, finished: bool):
	if project == expanded_project:
		setProjectsVisible(true)
		expanded_project = null
		mouse_filter = Control.MOUSE_FILTER_PASS
		get_v_scrollbar().mouse_filter = Control.MOUSE_FILTER_STOP

func setProjectsVisible(value: bool):
	if (project_container.modulate.a == 1.0 and value) or (project_container.modulate.a == 0.0 and not value):
		return
	
	project_fade_tween.stop_all()
	project_fade_tween.interpolate_property(project_container, "modulate:a", project_container.modulate.a, float(value), 0.25)
	project_fade_tween.start()

func getMainViewWidth() -> float:
	return OS.window_size.x - (MARGIN_H * 2.0)

func vScrolling():
	scroll_target = scroll_vertical
