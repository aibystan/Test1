extends CanvasLayer

# --- BAĞLANTILAR ---
@onready var esya_listesi_kutusu = $SolPanel/KaydirmaKutusu/EsyaListesi
@onready var aciklama_label = $AltPanel/AciklamaLabel
@onready var altin_label = $SagPanel/AltinLabel
@onready var parti_konteyneri = $SagPanel/PartiKonteyneri

# --- DEĞİŞKENLER ---
var satilik_esyalar: Array[ItemData] = []
var secili_index = 0
var input_kilitli = false

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func dukkani_ac(urunler_listesi: Array[ItemData]):
	satilik_esyalar = urunler_listesi
	visible = true
	secili_index = 0
	get_tree().paused = true
	input_kilitli = true
	await get_tree().create_timer(0.1).timeout
	menuyu_yeniden_ciz()
	await get_tree().create_timer(0.5).timeout
	input_kilitli = false

func menuyu_kapat():
	visible = false
	get_tree().paused = false

func _process(_delta):
	if not visible: return
	if input_kilitli: return

	if Input.is_action_just_pressed("tus_x"):
		menuyu_kapat()

	if satilik_esyalar.is_empty(): return

	if Input.is_action_just_pressed("ui_up"):
		secili_index = max(0, secili_index - 1)
		menuyu_yeniden_ciz()
		
	if Input.is_action_just_pressed("ui_down"):
		secili_index = min(satilik_esyalar.size() - 1, secili_index + 1)
		menuyu_yeniden_ciz()

	if Input.is_action_just_pressed("tus_z"):
		esya_satin_al()

func menuyu_yeniden_ciz():
	# --- SOL: Eşya listesi ---
	for cocuk in esya_listesi_kutusu.get_children():
		if cocuk.name != "SablonLabel":
			cocuk.queue_free()
	
	if not esya_listesi_kutusu.has_node("SablonLabel"):
		return
		
	var sablon = esya_listesi_kutusu.get_node("SablonLabel")
		
	for i in range(satilik_esyalar.size()):
		var esya = satilik_esyalar[i]
		var yeni_label = sablon.duplicate()
		yeni_label.name = "Urun_" + str(i)
		yeni_label.visible = true
		var metin = esya.isim + " (" + str(esya.fiyat) + " G)"
		if i == secili_index:
			yeni_label.text = "> " + metin
			yeni_label.modulate = Color(1, 1, 0)
			if aciklama_label is RichTextLabel:
				aciklama_label.clear()
				aciklama_label.append_text(esya.aciklama)
			else:
				aciklama_label.text = esya.aciklama
		else:
			yeni_label.text = "   " + metin
			yeni_label.modulate = Color(1, 1, 1)
		esya_listesi_kutusu.add_child(yeni_label)
	
	altin_label.text = "Paranız: " + str(Global.altin) + " G"
	
	# --- SAĞ: Parti paneli ---
	_parti_panelini_ciz()

func _parti_panelini_ciz():
	# Temizle
	for cocuk in parti_konteyneri.get_children():
		cocuk.queue_free()
	
	var secili_esya = satilik_esyalar[secili_index] if secili_index < satilik_esyalar.size() else null
	
	for karakter in Global.party_data:
		var panel = _karakter_karti_olustur(karakter, secili_esya)
		parti_konteyneri.add_child(panel)

func _karakter_karti_olustur(karakter: Dictionary, esya: ItemData) -> Control:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Karakterin bu eşyayı kullanıp kullanamayacağını belirle
	var kullanabilir = true
	if esya and esya.kullanabilir_karakterler.size() > 0:
		kullanabilir = karakter["isim"] in esya.kullanabilir_karakterler
	
	var renk_normal = Color(1, 1, 1) if kullanabilir else Color(0.5, 0.5, 0.5)
	var renk_isim = Color(1, 1, 0) if kullanabilir else Color(0.4, 0.4, 0.4)
	
	# İsim satırı
	var isim_lbl = Label.new()
	isim_lbl.text = karakter["isim"]
	isim_lbl.modulate = renk_isim
	isim_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(isim_lbl)
	
	# HP
	var hp_lbl = Label.new()
	hp_lbl.text = "HP: " + str(karakter["hp"]) + "/" + str(karakter["max_hp"])
	hp_lbl.modulate = renk_normal
	hp_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(hp_lbl)
	
	# QUT
	var qut_lbl = Label.new()
	qut_lbl.text = "QUT: " + str(karakter.get("qut", 0)) + "/" + str(karakter.get("max_qut", 200))
	qut_lbl.modulate = renk_normal
	qut_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(qut_lbl)
	
	# ATK (bonus göster)
	var atk_lbl = Label.new()
	var atk_bonus = 0
	if esya and esya.tur == ItemData.Tip.SILAH and kullanabilir:
		atk_bonus = esya.etki_degeri
		# Mevcut silahla kıyasla
		if karakter.get("silah") != null:
			atk_bonus -= karakter["silah"].etki_degeri
	atk_lbl.text = "ATK: " + str(karakter["atk"]) + _bonus_metni(atk_bonus)
	atk_lbl.modulate = _bonus_rengi(atk_bonus, renk_normal, kullanabilir)
	atk_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(atk_lbl)
	
	# DEF (bonus göster)
	var def_lbl = Label.new()
	var def_bonus = 0
	if esya and esya.tur == ItemData.Tip.ZIRH and kullanabilir:
		def_bonus = esya.etki_degeri
		if karakter.get("zirh") != null:
			def_bonus -= karakter["zirh"].etki_degeri
	def_lbl.text = "DEF: " + str(karakter["def"]) + _bonus_metni(def_bonus)
	def_lbl.modulate = _bonus_rengi(def_bonus, renk_normal, kullanabilir)
	def_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(def_lbl)
	
	return vbox

func _bonus_metni(bonus: int) -> String:
	if bonus > 0: return " (+" + str(bonus) + ")"
	if bonus < 0: return " (" + str(bonus) + ")"
	return ""

func _bonus_rengi(bonus: int, normal: Color, kullanabilir: bool) -> Color:
	if not kullanabilir: return Color(0.5, 0.5, 0.5)
	if bonus > 0: return Color(0.3, 1.0, 0.3)  # Yeşil
	if bonus < 0: return Color(1.0, 0.4, 0.4)  # Kırmızı
	return normal

func esya_satin_al():
	if secili_index >= satilik_esyalar.size():
		return
		
	var secilen_esya = satilik_esyalar[secili_index]
	
	if Global.envanter_dolu_mu():
		mesaj_goster("Envanteriniz dolu! Yer açın.")
		return
	
	if Global.altin >= secilen_esya.fiyat:
		Global.altin -= secilen_esya.fiyat
		Global.envantere_ekle(secilen_esya)
		mesaj_goster("Satın alındı: " + secilen_esya.isim)
		menuyu_yeniden_ciz()
	else:
		mesaj_goster("Yetersiz Bakiye! Paran yetmiyor.")

func mesaj_goster(mesaj: String):
	if aciklama_label is RichTextLabel:
		aciklama_label.clear()
		aciklama_label.append_text(mesaj)
	else:
		aciklama_label.text = mesaj
