extends PanelContainer
class_name ProjectPreview

const OPTIONAL_KEYS = ["name", "image"]

func init(data: Dictionary):
	
	for key in OPTIONAL_KEYS:
		if not key in data:
			data[key] = null
	
	if data["name"] != null:
		$HBoxContainer/InfoColumn/TitleLabel.text = data["name"]
	
	if data["image"] != null:
		$HBoxContainer/MainImage.texture = load("res://" + data["image"])
	else:
		$HBoxContainer/MainImage.queue_free()
	
