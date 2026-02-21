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
var typewriter_hiz = 0.03
var input_bekle = false  # baslat sonrasi bir frame Z inputunu yut

# --- SEÇENEK SİSTEMİ ---
var secenekler_aktif = false
var secili_secenek = 0
var secenek_verileri = []
var secenek_container: Control = null
var secenek_dugmeleri: Array = []

signal diyalog_bitti

func _ready():
	visible = false
	_secenek_ui_olustur()

# Seçenek panelini kod içinde oluştur (tscn'ye dokunmadan)
func _secenek_ui_olustur():
	secenek_container = VBoxContainer.new()
	secenek_container.name = "SecenekContainer"
	secenek_container.anchor_left = 0.68
	secenek_container.anchor_top = -0.9
	secenek_container.anchor_right = 0.998
	secenek_container.anchor_bottom = 0.0
	secenek_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	secenek_container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	secenek_container.add_theme_constant_override("separation", 4)
	secenek_container.visible = false
	arkaplan.add_child(secenek_container)

	for i in range(4):
		var btn = Button.new()
		btn.name = "Secenek" + str(i)
		btn.custom_minimum_size = Vector2(0, 22)
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.08, 0.08, 0.08, 0.95)
		normal_style.border_color = Color(0.8, 0.8, 0.8, 0.6)
		normal_style.set_border_width_all(1)
		normal_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("focus", normal_style)

		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.9, 0.9, 0.2, 1.0)
		hover_style.border_color = Color(1, 1, 1, 1)
		hover_style.set_border_width_all(2)
		hover_style.set_content_margin_all(6)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", hover_style)

		btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		btn.add_theme_color_override("font_hover_color", Color(0, 0, 0, 1))

		# Font ayari -- yolunu kendi fontuna gore degistir
		var font = load("res://Fonts/card-master.otf")
		if font:
			btn.add_theme_font_override("font", font)
			btn.add_theme_font_size_override("font_size", 32)

		var idx = i

		secenek_container.add_child(btn)
		secenek_dugmeleri.append(btn)

func _process(delta):
	if not visible:
		return

	# --- SEÇENEK MODU ---
	if secenekler_aktif:
		_secenek_input_isle()
		return

	if not aktif_mesaj:
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
			if metin_label is RichTextLabel:
				metin_label.clear()
				metin_label.append_text(displayed_text)
			else:
				metin_label.text = displayed_text

	# Z tuşu - İlerle
	if input_bekle:
		input_bekle = false
		return
	if Input.is_action_just_pressed("tus_z"):
		if typewriter_aktif:
			metin_tamamla()
		else:
			sonraki_mesaj()

	# X tuşu - Sadece typewriter'ı tamamla
	if Input.is_action_just_pressed("tus_x"):
		if typewriter_aktif:
			metin_tamamla()

func _secenek_input_isle():
	var secenek_sayisi = secenek_verileri.size()
	if secenek_sayisi == 0:
		return

	if Input.is_action_just_pressed("ui_up"):
		secili_secenek = (secili_secenek - 1 + secenek_sayisi) % secenek_sayisi
		_secenekleri_guncelle()
	elif Input.is_action_just_pressed("ui_down"):
		secili_secenek = (secili_secenek + 1) % secenek_sayisi
		_secenekleri_guncelle()

	if Input.is_action_just_pressed("tus_z"):
		_secenek_sec(secili_secenek)

func _secenekleri_guncelle():
	for i in range(secenek_dugmeleri.size()):
		var btn = secenek_dugmeleri[i]
		if i < secenek_verileri.size():
			var is_secili = (i == secili_secenek)
			var bg = Color(0.9, 0.9, 0.2, 1.0) if is_secili else Color(0.08, 0.08, 0.08, 0.95)
			var font_renk = Color(0, 0, 0, 1) if is_secili else Color(1, 1, 1, 1)
			var border = Color(1, 1, 1, 1) if is_secili else Color(0.8, 0.8, 0.8, 0.6)
			var border_w = 2 if is_secili else 1
			var style = StyleBoxFlat.new()
			style.bg_color = bg
			style.border_color = border
			style.set_border_width_all(border_w)
			style.set_content_margin_all(6)
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_color_override("font_color", font_renk)

func _secenek_sec(index: int):
	if index >= secenek_verileri.size():
		return
	var secilen = secenek_verileri[index]
	secenekler_aktif = false
	secenek_container.visible = false
	secenek_verileri.clear()
	if secilen.has("callback") and secilen["callback"] is Callable:
		secilen["callback"].call()

# --- ANA FONKSİYONLAR ---

func baslat(isim: String, mesajlar: Array, callback = null):
	mesaj_kuyrugu.clear()
	aktif_mesaj = false
	secenekler_aktif = false
	secenek_container.visible = false
	callback_fonksiyon = callback
	isim_goster(isim)
	for mesaj in mesajlar:
		mesaj_kuyrugu.append(mesaj)
	visible = true
	input_bekle = true
	sonraki_mesaj()
	return self

# Seçenekleri göster
# secenekler: [{metin: "...", callback: Callable}, ...]  — min 2, max 4
func secenekleri_goster(secenekler: Array):
	var kirpilmis = secenekler.slice(0, 4)
	if kirpilmis.size() < 2:
		push_warning("Seçenek sistemi en az 2 seçenek gerektirir!")
		return

	secenek_verileri = kirpilmis
	secili_secenek = 0
	secenekler_aktif = true
	aktif_mesaj = false

	for i in range(secenek_dugmeleri.size()):
		var btn = secenek_dugmeleri[i]
		if i < kirpilmis.size():
			btn.text = kirpilmis[i]["metin"]
			btn.visible = true
		else:
			btn.visible = false

	secenek_container.visible = true
	_secenekleri_guncelle()

func sonraki_mesaj():
	if mesaj_kuyrugu.is_empty():
		diyalog_bitir()
		return
	aktif_mesaj = true
	var mesaj = mesaj_kuyrugu.pop_front()
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
	# Önce callback'i çağır (seçenek açabilir)
	if callback_fonksiyon:
		if callback_fonksiyon is Callable:
			callback_fonksiyon.call()
	# Callback seçenek açmadıysa kapat
	if not secenekler_aktif:
		visible = false
	diyalog_bitti.emit()

func diyalog_kapat():
	mesaj_kuyrugu.clear()
	secenekler_aktif = false
	secenek_container.visible = false
	diyalog_bitir()

func mesaj_goster(mesaj: String, _sure: float = 2.0):
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
