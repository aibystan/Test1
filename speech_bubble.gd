extends Control

signal konusma_bitti

@onready var balon_panel = $BalonPanel
@onready var mesaj_label = $BalonPanel/MarginContainer/MesajLabel

const YAZI_HIZI = 0.04

var _metinler: Array = []
var _suanki_index: int = 0
var _aktif: bool = false
var _yaziliyor: bool = false
var _tam_metin: String = ""
var _atlandi: bool = false   # X ile anında yükleme isteği
var _ilerle: bool = false    # Z/X ile sonraki metne geç isteği

func _ready():
	visible = false
	modulate.a = 0

func goster(metin: String, _sure: float = 2.0):
	goster_liste([metin])

func goster_liste(metinler: Array, _sure: float = 2.0):
	_metinler = metinler.duplicate()
	_suanki_index = 0
	_aktif = true
	_atlandi = false
	_ilerle = false
	_calistir()

func _calistir():
	# Metin hizalamasını zorla
	mesaj_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	mesaj_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	# Tüm metinleri sırayla göster
	while _suanki_index < _metinler.size():
		_tam_metin = str(_metinler[_suanki_index])
		_atlandi = false
		_ilerle = false
		
		# Balonu göster
		if not visible:
			mesaj_label.text = ""
			visible = true
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 1.0, 0.15)
			await tween.finished
		else:
			mesaj_label.text = ""
		
		# Typewriter
		_yaziliyor = true
		for i in range(_tam_metin.length()):
			if _atlandi:
				break
			mesaj_label.text = _tam_metin.substr(0, i + 1)
			await get_tree().create_timer(YAZI_HIZI).timeout
		
		# Tam metni göster (X ile atlandıysa da)
		mesaj_label.text = _tam_metin
		_yaziliyor = false
		
		# Oyuncunun Z ya da X'e basmasını bekle
		_ilerle = false
		while not _ilerle:
			await get_tree().process_frame
		
		_suanki_index += 1
	
	# Hepsi bitti
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	visible = false
	_aktif = false
	konusma_bitti.emit()

func _input(event):
	if not _aktif or not visible:
		return
	
	if event.is_action("tus_x") and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		if _yaziliyor:
			_atlandi = true   # Typewriter'ı atla
		else:
			_ilerle = true    # Sonraki metne geç
	
	elif event.is_action("tus_z") and event.is_pressed() and not event.is_echo():
		get_viewport().set_input_as_handled()
		if not _yaziliyor:
			_ilerle = true    # Sadece yazı bitince ilerlenir

func gizle():
	_aktif = false
	_yaziliyor = false
	_ilerle = true
	_atlandi = true
	if visible:
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		await tween.finished
		visible = false
