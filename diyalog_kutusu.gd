extends CanvasLayer

# Overworld NPC diyalogları için
@onready var metin_label = $Arkaplan/MetinLabel
@onready var isim_label = $Arkaplan/IsimLabel
@onready var arkaplan = $Arkaplan

var mesaj_kuyrugu: Array = []
var aktif_mesaj = false
var callback_fonksiyon = null
var tam_metin = ""
var typewriter_aktif = false
var char_index = 0.0
var typewriter_hiz = 0.03  # Daha hızlı

signal diyalog_bitti

func _ready():
	visible = false

func _process(delta):
	if not visible or not aktif_mesaj:
		return
	
	# Typewriter animasyonu
	if typewriter_aktif:
		char_index += delta / typewriter_hiz
		var current_chars = int(char_index)
		if current_chars >= tam_metin.length():
			current_chars = tam_metin.length()
			typewriter_aktif = false
		
		if metin_label:
			var displayed_text = tam_metin.substr(0, current_chars)
			# RichTextLabel için
			if metin_label is RichTextLabel:
				metin_label.clear()
				metin_label.append_text(displayed_text)
			else:
				metin_label.text = displayed_text
	
	# Z tuşu - İlerle
	if Input.is_action_just_pressed("tus_z"):
		if typewriter_aktif:
			# Typewriter varsa hemen tamamla
			metin_tamamla()
		else:
			# Sonraki mesaj
			sonraki_mesaj()
	
	# X tuşu - Hızlı geçiş (sonraki mesaja geç, kapatma)
	if Input.is_action_just_pressed("tus_x"):
		if typewriter_aktif:
			# Typewriter varsa tamamla
			metin_tamamla()
		else:
			# Sonraki mesaja geç (Z ile aynı)
			sonraki_mesaj()

func baslat(isim: String, mesajlar: Array, callback = null):
	mesaj_kuyrugu.clear()
	aktif_mesaj = false
	callback_fonksiyon = callback
	
	# İsmi göster
	isim_goster(isim)
	
	# Mesajları kuyruğa ekle
	for mesaj in mesajlar:
		mesaj_kuyrugu.append(mesaj)
	
	# Görünür yap
	visible = true
	
	# İlk mesajı göster
	sonraki_mesaj()
	
	return self

func sonraki_mesaj():
	if mesaj_kuyrugu.is_empty():
		diyalog_bitir()
		return
	
	aktif_mesaj = true
	var mesaj = mesaj_kuyrugu.pop_front()
	
	# Typewriter başlat
	tam_metin = mesaj
	char_index = 0.0
	typewriter_aktif = true
	
	if metin_label:
		if metin_label is RichTextLabel:
			metin_label.clear()
		else:
			metin_label.text = ""

func metin_tamamla():
	typewriter_aktif = false
	char_index = float(tam_metin.length())
	if metin_label:
		if metin_label is RichTextLabel:
			metin_label.clear()
			metin_label.append_text(tam_metin)
		else:
			metin_label.text = tam_metin

func diyalog_bitir():
	aktif_mesaj = false
	visible = false
	
	# Callback varsa çağır
	if callback_fonksiyon:
		if callback_fonksiyon is Callable:
			callback_fonksiyon.call()
	
	diyalog_bitti.emit()

func diyalog_kapat():
	mesaj_kuyrugu.clear()
	diyalog_bitir()

func mesaj_goster(mesaj: String, _sure: float = 2.0):
	# Eski API uyumluluğu
	mesaj_kuyrugu.append(mesaj)
	if not aktif_mesaj:
		visible = true
		sonraki_mesaj()

func temizle():
	mesaj_kuyrugu.clear()
	if metin_label:
		if metin_label is RichTextLabel:
			metin_label.clear()
		else:
			metin_label.text = ""
	aktif_mesaj = false
	visible = false

func isim_goster(isim: String):
	if isim_label:
		isim_label.text = isim
		isim_label.visible = true

func isim_gizle():
	if isim_label:
		isim_label.visible = false
