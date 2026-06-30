extends CanvasLayer

@onready var subtitle_label: Label = $Label

func _ready() -> void:
	hide()

func show_text(text: String) -> void:
	subtitle_label.text = text
	show()

func hide_dialogue() -> void:
	hide()
