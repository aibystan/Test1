extends CanvasLayer

# --- BAĞLANTILAR ---
@onready var grid_container = $SolPanel/GridContainer
@onready var aciklama_label = $AltPanel/AciklamaLabel

# Karakter bilgileri
@onready var isim_label = $SagPanel/KarakterBilgileri/IsimLabel
@onready var hp_label = $SagPanel/KarakterBilgileri/HPLabel
@onready var atk_label = $SagPanel/KarakterBilgileri/AtkLabel
@onready var silah_label = $SagPanel/KarakterBilgileri/SilahLabel
@onready var zirh_label = $SagPanel/KarakterBilgileri/ZirhLabel

# --- DEĞİŞKENLER ---
var secili_index = 0
var slot_butonlari = []

func _ready():
	visible = false

func _process(_delta):
	# Menüyü Açma/Kapatma (I Tuşu)
	if Input.is_action_just_pressed("inventory"):
		if visible:
			menuyu_kapat()
		else:
			menuyu_ac()
			
	# EĞER MENÜ AÇIKSA TUŞLARI DİNLE
	if visible:
		kontrol_mekanizmasi()

# --- MENÜYÜ YÖNETME ---
func menuyu_ac():
	visible = true
	secili_index = 0
	menuyu_yeniden_ciz()
	get_tree().paused = true 

func menuyu_kapat():
	visible = false
	get_tree().paused = false

# --- KLAVYE KONTROLLERİ ---
func kontrol_mekanizmasi():
	# X Tuşu: Menüden Çık
	if Input.is_action_just_pressed("tus_x"):
		menuyu_kapat()
		return

	# V TUŞU: Karakter Değiştir
	if Input.is_action_just_pressed("karakter_degistir"):
		Global.secili_karakter_index += 1
		if Global.secili_karakter_index >= Global.party_data.size():
			Global.secili_karakter_index = 0
		menuyu_yeniden_ciz()
		return

	# --- GRID NAVİGASYONU ---
	var toplam_esya = Global.inventory.size()
	if toplam_esya == 0: return
	
	var sutun_sayisi = 2
	var eski_index = secili_index

	# YUKARI
	if Input.is_action_just_pressed("ui_up"):
		secili_index -= sutun_sayisi
		if secili_index < 0:
			secili_index = eski_index
	
	# AŞAĞI
	if Input.is_action_just_pressed("ui_down"):
		secili_index += sutun_sayisi
		if secili_index >= toplam_esya:
			secili_index = eski_index
	
	# SOL
	if Input.is_action_just_pressed("ui_left"):
		if secili_index % sutun_sayisi != 0:
			secili_index -= 1
	
	# SAĞ
	if Input.is_action_just_pressed("ui_right"):
		if secili_index % sutun_sayisi != sutun_sayisi - 1 and secili_index < toplam_esya - 1:
			secili_index += 1
	
	if eski_index != secili_index:
		gorseli_guncelle()

	# Z Tuşu: Kullan
	if Input.is_action_just_pressed("tus_z"):
		esya_kullan()

# --- GÖRSEL GÜNCELLEME ---
func menuyu_yeniden_ciz():
	# Grid'i temizle
	for cocuk in grid_container.get_children():
		grid_container.remove_child(cocuk)
		cocuk.queue_free()
	
	slot_butonlari.clear()
	
	# 14 slot oluştur
	for i in range(Global.MAX_ENVANTER_KAPASITESI):
		var label = Label.new()
		label.custom_minimum_size = Vector2(130, 25)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		
		# Eğer eşya varsa göster
		if i < Global.inventory.size():
			var esya = Global.inventory[i]
			label.text = " " + esya.isim
			label.modulate = Color(1, 1, 1)
		else:
			label.text = ""
			label.modulate = Color(0.4, 0.4, 0.4)
		
		grid_container.add_child(label)
		slot_butonlari.append(label)
	
	karakter_bilgisini_goster()
	gorseli_guncelle()

func gorseli_guncelle():
	if Global.inventory.is_empty():
		aciklama_label.text = "Çantanız boş."
		return

	secili_index = clamp(secili_index, 0, Global.inventory.size() - 1)
	
	# Seçili slotu vurgula
	for i in range(slot_butonlari.size()):
		var label = slot_butonlari[i]
		
		if i == secili_index and i < Global.inventory.size():
			# Seçili - sarı ok + sarı renk
			label.text = "> " + Global.inventory[i].isim
			label.modulate = Color(1, 1, 0)
			aciklama_label.text = Global.inventory[i].aciklama
		elif i < Global.inventory.size():
			# Normal
			label.text = " " + Global.inventory[i].isim
			label.modulate = Color(1, 1, 1)

# --- EYLEMLER ---
func esya_kullan():
	if Global.inventory.is_empty(): return
	if secili_index >= Global.inventory.size(): return
	
	var secilen_esya = Global.inventory[secili_index]
	var suanki_karakter_ismi = Global.party_data[Global.secili_karakter_index]["isim"]
	
	if not secilen_esya.kullanabilir_karakterler.is_empty() and not suanki_karakter_ismi in secilen_esya.kullanabilir_karakterler:
		aciklama_label.text = "Bunu " + suanki_karakter_ismi + " kullanamaz!"
		return

	# TÜKETİLEBİLİR
	if secilen_esya.tur == ItemData.Tip.TUKETILEBILIR:
		Global.karakteri_iyilestir(secilen_esya.etki_degeri)
		Global.inventory.remove_at(secili_index)
		aciklama_label.text = secilen_esya.isim + " kullanıldı ve can yenilendi!"

	# SİLAH/ZIRH
	elif secilen_esya.tur == ItemData.Tip.SILAH or secilen_esya.tur == ItemData.Tip.ZIRH:
		var cikarilan_esya = Global.esya_kusan(secilen_esya)
		Global.inventory.remove_at(secili_index)
		
		if cikarilan_esya != null:
			Global.inventory.append(cikarilan_esya)
			aciklama_label.text = secilen_esya.isim + " kuşandı. " + cikarilan_esya.isim + " çantaya döndü."
		else:
			aciklama_label.text = secilen_esya.isim + " kuşandı."

	if secili_index >= Global.inventory.size():
		secili_index = max(0, Global.inventory.size() - 1)
	menuyu_yeniden_ciz()

# --- SAĞ PANEL ---
func karakter_bilgisini_goster():
	var karakter = Global.party_data[Global.secili_karakter_index]
	
	var toplam_atk = karakter["atk"]
	if karakter["silah"] != null:
		toplam_atk += karakter["silah"].etki_degeri
	
	# Karakter ismine ok işaretleri ekle (V tuşu için görsel ipucu)
	isim_label.text = "< " + karakter["isim"] + " > (V)"
	hp_label.text = "HP: %d/%d" % [karakter["hp"], karakter["max_hp"]]
	atk_label.text = "SALDIRI: %d" % toplam_atk 
	
	if karakter["silah"]: silah_label.text = "Silah: " + karakter["silah"].isim
	else: silah_label.text = "Silah: Yok"
		
	if karakter["zirh"]: zirh_label.text = "Zırh: " + karakter["zirh"].isim
	else: zirh_label.text = "Zırh: Yok"
