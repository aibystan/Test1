extends Control

@onready var balon_panel = $BalonPanel
@onready var mesaj_label = $BalonPanel/MarginContainer/MesajLabel

func _ready():
	visible = false
	modulate.a = 0

func goster(mesaj: String, sure: float = 1.5):
	mesaj_label.text = mesaj
	visible = true
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	# Bekle
	await get_tree().create_timer(sure).timeout
	
	# Fade out
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	visible = false

func gizle():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
