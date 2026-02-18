extends CanvasLayer

# --- REFERANSLAR ---
@onready var message_box = $MessageBox
@onready var stat_panel = $StatsPanel
@onready var ana_menu = $AnaMenuPanel
@onready var hedef_panel = $HedefPanel
@onready var act_panel = $ActPanel

var battle_manager: BattleManager
var aktif_karakter_index: int = 0

# Menü navigasyon
var menu_tipi: String = "ANA"
var secili_index: int = 0
var secenekler: Array = []
var hedef_listesi: Array = []

# Animasyon pozisyonları (CanvasLayer için basitleştirilmiş)
var paneller_yukari = true

func _ready():
	visible = true
	panelleri_gizle_animsiz()

func panelleri_gizle_animsiz():
	# Başlangıçta paneller ekran dışında
	stat_panel.position.y = 720  # Ekran dışı
	ana_menu.position.y = 720
	ana_menu.visible = false
	hedef_panel.visible = false
	act_panel.visible = false

func _process(_delta):
	if not visible: return
	klavye_kontrol()

func klavye_kontrol():
	match menu_tipi:
		"ANA":
			ana_menu_kontrol()
		"HEDEF":
			hedef_menu_kontrol()
		"ACT":
			act_menu_kontrol()

# --- PANEL ANİMASYONLARI ---
func panelleri_goster():
	# Paneller yukarı kayar
	var tween = create_tween().set_parallel(true)
	tween.tween_property(stat_panel, "position:y", 580, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ana_menu, "position:y", 580, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	ana_menu.visible = true

func panelleri_gizle():
	# Paneller aşağı kayar
	var tween = create_tween().set_parallel(true)
	tween.tween_property(stat_panel, "position:y", 720, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(ana_menu, "position:y", 720, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	ana_menu.visible = false

# --- ANA MENÜ KONTROLÜ ---
func ana_menu_kontrol():
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
	
	if Input.is_action_just_pressed("tus_z"):
		ana_menu_sec()

func ana_menu_guncelle():
	var butonlar = [
		ana_menu.get_node("MarginContainer/HBoxContainer/SaldirBtn"),
		ana_menu.get_node("MarginContainer/HBoxContainer/SihirBtn"),
		ana_menu.get_node("MarginContainer/HBoxContainer/EylemBtn"),
		ana_menu.get_node("MarginContainer/HBoxContainer/ItemBtn"),
		ana_menu.get_node("MarginContainer/HBoxContainer/InsafBtn")
	]
	
	for i in range(butonlar.size()):
		if i == secili_index:
			butonlar[i].modulate = Color(1, 1, 0)
		else:
			butonlar[i].modulate = Color(1, 1, 1)

func ana_menu_sec():
	match secili_index:
		0: _on_saldir_pressed()
		1: _on_sihir_pressed()
		2: _on_eylem_pressed()
		3: _on_item_pressed()
		4: _on_insaf_pressed()

# --- HEDEF/ACT MENÜ (önceki gibi) ---
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
	
	if Input.is_action_just_pressed("tus_z"):
		_on_hedef_secildi(secili_index)
	
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
	hedef_panel.get_node("MarginContainer/Label").text = text

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
	
	if Input.is_action_just_pressed("tus_z"):
		_on_act_secildi(secenekler[secili_index])
	
	if Input.is_action_just_pressed("tus_x"):
		act_panel.visible = false
		ana_menu.visible = true
		menu_tipi = "ANA"

func act_menu_guncelle():
	var label = act_panel.get_node("MarginContainer/Label")
	var text = "Act Seç:\n\n"
	for i in range(secenekler.size()):
		if i == secili_index:
			text += "> " + secenekler[i] + "\n"
		else:
			text += "  " + secenekler[i] + "\n"
	label.text = text

# --- TURN SİSTEMİ ---
func turn_menusu_goster(karakter: Dictionary):
	menu_tipi = "ANA"
	secili_index = 0
	
	stat_guncelle()
	ana_menu_guncelle()
	
	# Panelleri yukarı kaydır
	panelleri_goster()
	
	# Mesaj göster
	if message_box:
		message_box.mesaj_goster(karakter["isim"] + "'ın sırası!", 1.5)

func stat_guncelle():
	if Global.party_data.size() > 0:
		var k1 = Global.party_data[0]
		var k1_panel = stat_panel.get_node("MarginContainer/HBoxContainer/Karakter1")
		k1_panel.get_node("IsimLabel").text = k1["isim"]
		k1_panel.get_node("HPLabel").text = "HP: %d/%d" % [k1["hp"], k1["max_hp"]]
		k1_panel.get_node("QutLabel").text = "Qut: %d/%d" % [Global.current_qut, Global.max_qut]
	
	if Global.party_data.size() > 1:
		var k2 = Global.party_data[1]
		var k2_panel = stat_panel.get_node("MarginContainer/HBoxContainer/Karakter2")
		k2_panel.get_node("IsimLabel").text = k2["isim"]
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

func hedef_secim_goster(dusmanlar: Array):
	ana_menu.visible = false
	hedef_panel.visible = true
	menu_tipi = "HEDEF"
	secili_index = 0
	
	hedef_listesi.clear()
	var hedef_index_map = []
	
	for i in range(dusmanlar.size()):
		var dusman_dict = dusmanlar[i]
		if not dusman_dict["data"].oldu_mu():
			var isim = dusman_dict["data"].isim
			var hp = dusman_dict["data"].current_hp
			hedef_listesi.append(isim + " (HP: " + str(hp) + ")")
			hedef_index_map.append(i)
	
	set_meta("hedef_index_map", hedef_index_map)
	hedef_menu_guncelle()

func _on_hedef_secildi(index: int):
	hedef_panel.visible = false
	ana_menu.visible = false
	menu_tipi = "ANA"
	
	if battle_manager:
		var index_map = get_meta("hedef_index_map", [])
		if index < index_map.size():
			var gercek_index = index_map[index]
			battle_manager.hedef_secildi(gercek_index)
		
		# Turn bittikten sonra UI'yi gizle
		await battle_manager.turn_bitti
		panelleri_gizle()

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
