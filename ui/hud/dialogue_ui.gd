extends CanvasLayer

@onready var subtitle_label: Label = $Label

func _ready() -> void:
	hide_dialogue()

func show_text(text: String) -> void:
	subtitle_label.text = text
	_set_display_visible(true)

func _set_display_visible(is_visible: bool) -> void:
	visible = is_visible
	
func hide_dialogue() -> void:
	subtitle_label.text = ""
	_set_display_visible(false)
