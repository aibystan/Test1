extends Control

# --- REFERANSLAR ---
@onready var ana_menu = $AnaMenu
@onready var stat_panel = $StatsPanel

# Hedef seçim
@onready var hedef_panel = $HedefPanel
@onready var hedef_label = $HedefPanel/Label

# Act menü
@onready var act_panel = $ActPanel

var battle_manager: BattleManager
var aktif_karakter_index: int = 0

# Menü navigasyon
var menu_tipi: String = "ANA"  # ANA, HEDEF, ACT
var secili_index: int = 0
var secenekler: Array = []

# Hedef listesi
var hedef_listesi: Array = []

func _ready():
	visible = true
	ana_menu.visible = false
	hedef_panel.visible = false
	act_panel.visible = false

func _process(_delta):
	if not visible: return
	
	# Klavye kontrolü
	klavye_kontrol()

func klavye_kontrol():
	match menu_tipi:
		"ANA":
			ana_menu_kontrol()
		"HEDEF":
			hedef_menu_kontrol()
		"ACT":
			act_menu_kontrol()

# --- ANA MENÜ KONTROLÜ ---
func ana_menu_kontrol():
	# 1-5 tuşları veya ok tuşları
	if Input.is_action_just_pressed("ui_left"):
		secili_index -= 1
		if secili_index < 0:
			secili_index = 4
		ana_menu_guncelle()
	
	if Input.is_action_just_pressed("ui_right"):
		secili_index += 1
		if secili_index > 4:
			secili_index = 0
		ana_menu_guncelle()
	
	# Z ile seç
	if Input.is_action_just_pressed("tus_z"):
		ana_menu_sec()

func ana_menu_guncelle():
	# Butonları güncelle - seçili olanı vurgula
	var butonlar = [
		ana_menu.get_node("SaldirBtn"),
		ana_menu.get_node("SihirBtn"),
		ana_menu.get_node("EylemBtn"),
		ana_menu.get_node("ItemBtn"),
		ana_menu.get_node("InsafBtn")
	]
	
	for i in range(butonlar.size()):
		if i == secili_index:
			butonlar[i].modulate = Color(1, 1, 0)  # Sarı
		else:
			butonlar[i].modulate = Color(1, 1, 1)  # Beyaz

func ana_menu_sec():
	match secili_index:
		0: _on_saldir_pressed()
		1: _on_sihir_pressed()
		2: _on_eylem_pressed()
		3: _on_item_pressed()
		4: _on_insaf_pressed()

# --- HEDEF MENÜ KONTROLÜ ---
func hedef_menu_kontrol():
	if Input.is_action_just_pressed("ui_left"):
		secili_index -= 1
		if secili_index < 0:
			secili_index = hedef_listesi.size() - 1
		hedef_menu_guncelle()
	
	if Input.is_action_just_pressed("ui_right"):
		secili_index += 1
		if secili_index >= hedef_listesi.size():
			secili_index = 0
		hedef_menu_guncelle()
	
	# Z ile seç
	if Input.is_action_just_pressed("tus_z"):
		_on_hedef_secildi(secili_index)
	
	# X ile iptal
	if Input.is_action_just_pressed("tus_x"):
		hedef_panel.visible = false
		ana_menu.visible = true
		menu_tipi = "ANA"

func hedef_menu_guncelle():
	var text = "Hedef Seç:\n\n"
	for i in range(hedef_listesi.size()):
		if i == secili_index:
			text += "> " + hedef_listesi[i] + "\n"
		else:
			text += "  " + hedef_listesi[i] + "\n"
	hedef_label.text = text

# --- ACT MENÜ KONTROLÜ ---
func act_menu_kontrol():
	if Input.is_action_just_pressed("ui_up"):
		secili_index -= 1
		if secili_index < 0:
			secili_index = secenekler.size() - 1
		act_menu_guncelle()
	
	if Input.is_action_just_pressed("ui_down"):
		secili_index += 1
		if secili_index >= secenekler.size():
			secili_index = 0
		act_menu_guncelle()
	
	# Z ile seç
	if Input.is_action_just_pressed("tus_z"):
		_on_act_secildi(secenekler[secili_index])
	
	# X ile iptal
	if Input.is_action_just_pressed("tus_x"):
		act_panel.visible = false
		ana_menu.visible = true
		menu_tipi = "ANA"

func act_menu_guncelle():
	var label = act_panel.get_node("Label")
	var text = "Act Seç:\n\n"
	for i in range(secenekler.size()):
		if i == secili_index:
			text += "> " + secenekler[i] + "\n"
		else:
			text += "  " + secenekler[i] + "\n"
	label.text = text

# --- MENÜ FONKSİYONLARI ---
func turn_menusu_goster(karakter: Dictionary):
	ana_menu.visible = true
	hedef_panel.visible = false
	act_panel.visible = false
	menu_tipi = "ANA"
	secili_index = 0
	
	stat_guncelle()
	ana_menu_guncelle()

func stat_guncelle():
	# Karakter 1
	if Global.party_data.size() > 0:
		var k1 = Global.party_data[0]
		var k1_panel = stat_panel.get_node("Karakter1")
		if k1_panel.has_node("IsimLabel"):
			k1_panel.get_node("IsimLabel").text = k1["isim"]
		if k1_panel.has_node("HPLabel"):
			k1_panel.get_node("HPLabel").text = "HP: %d/%d" % [k1["hp"], k1["max_hp"]]
		if k1_panel.has_node("QutLabel"):
			k1_panel.get_node("QutLabel").text = "Qut: %d/%d" % [Global.current_qut, Global.max_qut]
	
	# Karakter 2
	if Global.party_data.size() > 1:
		var k2 = Global.party_data[1]
		var k2_panel = stat_panel.get_node("Karakter2")
		if k2_panel.has_node("IsimLabel"):
			k2_panel.get_node("IsimLabel").text = k2["isim"]
		if k2_panel.has_node("HPLabel"):
			k2_panel.get_node("HPLabel").text = "HP: %d/%d" % [k2["hp"], k2["max_hp"]]

# --- BUTON FONKSİYONLARI ---
func _on_saldir_pressed():
	if battle_manager:
		battle_manager.player_eylem_sec("SALDIR")

func _on_sihir_pressed():
	if battle_manager:
		battle_manager.player_eylem_sec("SIHIR")

func _on_eylem_pressed():
	if battle_manager:
		battle_manager.player_eylem_sec("EYLEM")

func _on_item_pressed():
	if battle_manager:
		battle_manager.player_eylem_sec("ITEM")

func _on_insaf_pressed():
	if battle_manager:
		battle_manager.player_eylem_sec("INSAF")

# --- HEDEF SEÇİM ---
func hedef_secim_goster(dusmanlar: Array):
	ana_menu.visible = false
	hedef_panel.visible = true
	menu_tipi = "HEDEF"
	secili_index = 0
	
	# Hedef listesi oluştur
	hedef_listesi.clear()
	for dusman_dict in dusmanlar:
		if not dusman_dict["data"].oldu_mu():
			var isim = dusman_dict["data"].isim
			var hp = dusman_dict["data"].current_hp
			hedef_listesi.append(isim + " (HP: " + str(hp) + ")")
	
	hedef_menu_guncelle()

func _on_hedef_secildi(index: int):
	hedef_panel.visible = false
	menu_tipi = "ANA"
	
	if battle_manager:
		battle_manager.hedef_secildi(index)

# --- ACT MENÜ ---
func act_secenekleri_goster(acts: Array):
	ana_menu.visible = false
	act_panel.visible = true
	menu_tipi = "ACT"
	secili_index = 0
	
	secenekler = acts.duplicate()
	act_menu_guncelle()

func _on_act_secildi(act_ismi: String):
	act_panel.visible = false
	menu_tipi = "ANA"
	
	if battle_manager:
		battle_manager.act_secildi(act_ismi, 0)
