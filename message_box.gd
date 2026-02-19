extends Panel

@onready var mesaj_label = $MarginContainer/MesajLabel

var flavor_metni: String = ""
var sonuc_timer: float = 0.0
var sonuc_suresi: float = 1.2

# Typewriter
var _tam_metin: String = ""
var _gosterilen_karakter: int = 0
var _typewriter_hizi: float = 0.01  # saniye/karakter
var _typewriter_timer: float = 0.0
var _typewriter_aktif: bool = false

func _process(delta):
	# Typewriter
	if _typewriter_aktif:
		_typewriter_timer -= delta
		if _typewriter_timer <= 0.0:
			_typewriter_timer = _typewriter_hizi
			_gosterilen_karakter += 1
			if _gosterilen_karakter >= _tam_metin.length():
				_gosterilen_karakter = _tam_metin.length()
				_typewriter_aktif = false
			mesaj_label.text = _tam_metin.substr(0, _gosterilen_karakter)

	# Sonuç timer
	if sonuc_timer > 0:
		sonuc_timer -= delta
		if sonuc_timer <= 0:
			# Sonuç bitti, flavor text'e typewriter ile dön
			_typewriter_baslat(flavor_metni)

func _typewriter_baslat(metin: String):
	if metin == "":
		mesaj_label.text = ""
		_typewriter_aktif = false
		return
	_tam_metin = metin
	_gosterilen_karakter = 0
	_typewriter_aktif = true
	_typewriter_timer = 0.0

func flavor_goster(metin: String):
	flavor_metni = metin
	if sonuc_timer <= 0:
		_typewriter_baslat(metin)

func sonuc_goster(sonuc: String):
	# Sonuç anında gösterilir (typewriter yok), sonra flavor'a döner
	_typewriter_aktif = false
	mesaj_label.text = sonuc
	sonuc_timer = sonuc_suresi

func mesaj_goster(mesaj: String, _sure: float = 2.0):
	flavor_goster(mesaj)

func temizle():
	flavor_metni = ""
	sonuc_timer = 0.0
	_typewriter_aktif = false
	mesaj_label.text = ""
