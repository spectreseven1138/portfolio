extends ScrollContainer

const CONFIG_PATH = "res://config.json"
const PROJECT_PREVIEW: PackedScene = preload("res://src/ProjectPreview.tscn")

onready var project_container: VBoxContainer = $VBoxContainer/ProjectContainer

var config: Dictionary = {}

func _ready():
	var error: int = loadConfig()
	if error != OK:
		get_tree().quit(error)
	
	prepareScene()

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
		$VBoxContainer/TitleLabel.text = config["title"]
	
	if config["subtitle"] != null:
		$VBoxContainer/SubtitleLabel.text = config["subtitle"]
	
	for node in project_container.get_children():
		node.queue_free()
	
	if config["projects"] != null:
		
		for project_data in config["projects"]:
			
			var year: int
			if not "year" in project_data or project_data["year"] == null:
				year = 0
			else:
				year = project_data["year"]
			
			var year_node: Control = null
			for node in project_container.get_children():
				if node.name == str(year):
					year_node = node
					break
			
			if year_node == null:
				year_node = VBoxContainer.new()
				year_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				year_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
				
				var label: Label = Label.new()
				label.text = str(year) if year > 0 else "Unknown"
				year_node.add_child(label)
				
				var project_grid: GridContainer = GridContainer.new()
				project_grid.columns = 2
				project_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				project_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
				year_node.add_child(project_grid)
				
				project_container.add_child(year_node)
				year_node.name = str(year)
			
			var project: ProjectPreview = PROJECT_PREVIEW.instance()
			project.init(project_data)
			
			year_node.get_child(1).add_child(project)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.scancode == KEY_F11:
		OS.window_fullscreen = !OS.window_fullscreen

func _process(delta: float):
	pass
