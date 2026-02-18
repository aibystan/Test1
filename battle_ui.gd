extends CanvasLayer

# --- REFERANSLAR ---
@onready var message_box = $MessageBox
@onready var stats_panel = $StatsPanel
@onready var ana_menu_panel = $AnaMenuPanel
@onready var hedef_panel = $HedefPanel
@onready var act_panel = $ActPanel

var battle_manager: BattleManager

var menu_tipi: String = "ANA"
var secili_index: int = 0
var secenekler: Array = []
var hedef_listesi: Array = []

# Ekran boyutları
const SW = 640   # Screen Width
const SH = 360   # Screen Height
const PH = 90    # Panel Height (piksel)

func _ready():
	visible = true
	_panelleri_ayarla()
	ana_menu_panel.visible = false
	hedef_panel.visible = false
	act_panel.visible = false


func _panelleri_ayarla():
	# StatsPanel: sol yarı, ekranın altında
	stats_panel.set_position(Vector2(0, SH))        # başta ekran dışında
	stats_panel.set_size(Vector2(SW / 2, PH))
	
	# AnaMenuPanel: sağ yarı, ekranın altında
	ana_menu_panel.set_position(Vector2(SW / 2, SH)) # başta ekran dışında
	ana_menu_panel.set_size(Vector2(SW / 2, PH))
	
	# HedefPanel: ortada, savaş alanı üzerinde
	hedef_panel.set_position(Vector2(SW / 2 - 100, SH / 2 - 50))
	hedef_panel.set_size(Vector2(200, 120))
	
	# ActPanel
	act_panel.set_position(Vector2(SW / 2 - 100, SH / 2 - 80))
	act_panel.set_size(Vector2(200, 160))

func _process(_delta):
	if not visible: return
	klavye_kontrol()

func klavye_kontrol():
	match menu_tipi:
		"ANA": ana_menu_kontrol()
		"HEDEF": hedef_menu_kontrol()
		"ACT": act_menu_kontrol()

# --- ANİMASYONLAR ---
func panelleri_goster():
	ana_menu_panel.visible = true
	var hedef_y = float(SH - PH)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(stats_panel, "position:y", hedef_y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ana_menu_panel, "position:y", hedef_y, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func panelleri_gizle():
	if message_box:
		message_box.visible = false
	var tween = create_tween().set_parallel(true)
	tween.tween_property(stats_panel, "position:y", float(SH), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(ana_menu_panel, "position:y", float(SH), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	ana_menu_panel.visible = false

# --- ANA MENÜ ---
func ana_menu_kontrol():
	if Input.is_action_just_pressed("ui_left"):
		secili_index -= 1
		if secili_index < 0: secili_index = 4
		ana_menu_guncelle()
	if Input.is_action_just_pressed("ui_right"):
		secili_index = (secili_index + 1) % 5
		ana_menu_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		ana_menu_sec()

func ana_menu_guncelle():
	var hbox = ana_menu_panel.get_node("MarginContainer/HBoxContainer")
	var isimler = ["SaldirBtn","SihirBtn","EylemBtn","ItemBtn","InsafBtn"]
	for i in range(isimler.size()):
		hbox.get_node(isimler[i]).modulate = Color(1,1,0) if i == secili_index else Color(1,1,1)

func ana_menu_sec():
	match secili_index:
		0: if battle_manager: battle_manager.player_eylem_sec("SALDIR")
		1: if battle_manager: battle_manager.player_eylem_sec("SIHIR")
		2: if battle_manager: battle_manager.player_eylem_sec("EYLEM")
		3: if battle_manager: battle_manager.player_eylem_sec("ITEM")
		4: if battle_manager: battle_manager.player_eylem_sec("INSAF")

# --- HEDEF MENÜ ---
func hedef_menu_kontrol():
	if Input.is_action_just_pressed("ui_left"):
		secili_index -= 1
		if secili_index < 0: secili_index = hedef_listesi.size() - 1
		hedef_menu_guncelle()
	if Input.is_action_just_pressed("ui_right"):
		secili_index = (secili_index + 1) % hedef_listesi.size()
		hedef_menu_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		_on_hedef_secildi(secili_index)
	if Input.is_action_just_pressed("tus_x"):
		hedef_panel.visible = false
		ana_menu_panel.visible = true
		menu_tipi = "ANA"

func hedef_menu_guncelle():
	var text = "Hedef Seç:\n\n"
	for i in range(hedef_listesi.size()):
		text += ("> " if i == secili_index else "  ") + hedef_listesi[i] + "\n"
	hedef_panel.get_node("MarginContainer/Label").text = text

# --- ACT MENÜ ---
func act_menu_kontrol():
	if Input.is_action_just_pressed("ui_up"):
		secili_index -= 1
		if secili_index < 0: secili_index = secenekler.size() - 1
		act_menu_guncelle()
	if Input.is_action_just_pressed("ui_down"):
		secili_index = (secili_index + 1) % secenekler.size()
		act_menu_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		_on_act_secildi(secenekler[secili_index])
	if Input.is_action_just_pressed("tus_x"):
		act_panel.visible = false
		ana_menu_panel.visible = true
		menu_tipi = "ANA"

func act_menu_guncelle():
	var text = "Act Seç:\n\n"
	for i in range(secenekler.size()):
		text += ("> " if i == secili_index else "  ") + secenekler[i] + "\n"
	act_panel.get_node("MarginContainer/Label").text = text

# --- TURN SİSTEMİ ---
func turn_menusu_goster(karakter: Dictionary):
	menu_tipi = "ANA"
	secili_index = 0
	stat_guncelle()
	ana_menu_guncelle()
	if message_box:
		message_box.visible = true
	panelleri_goster()

func stat_guncelle():
	if Global.party_data.size() > 0:
		var k1 = Global.party_data[0]
		var p = stats_panel.get_node("MarginContainer/HBoxContainer/Karakter1")
		p.get_node("IsimLabel").text = k1["isim"]
		p.get_node("HPLabel").text = "HP: %d/%d" % [k1["hp"], k1["max_hp"]]
		p.get_node("QutLabel").text = "Qut: %d/%d" % [Global.current_qut, Global.max_qut]
	if Global.party_data.size() > 1:
		var k2 = Global.party_data[1]
		var p = stats_panel.get_node("MarginContainer/HBoxContainer/Karakter2")
		p.get_node("IsimLabel").text = k2["isim"]
		p.get_node("HPLabel").text = "HP: %d/%d" % [k2["hp"], k2["max_hp"]]

# --- HEDEF / ACT GÖSTER ---
func hedef_secim_goster(dusmanlar: Array):
	ana_menu_panel.visible = false
	hedef_panel.visible = true
	menu_tipi = "HEDEF"
	secili_index = 0
	hedef_listesi.clear()
	var hedef_index_map = []
	for i in range(dusmanlar.size()):
		var d = dusmanlar[i]
		if not d["data"].oldu_mu():
			hedef_listesi.append(d["data"].isim + " (HP: " + str(d["data"].current_hp) + ")")
			hedef_index_map.append(i)
	set_meta("hedef_index_map", hedef_index_map)
	hedef_menu_guncelle()

func _on_hedef_secildi(index: int):
	hedef_panel.visible = false
	menu_tipi = ""
	if battle_manager:
		var index_map = get_meta("hedef_index_map", [])
		if index < index_map.size():
			battle_manager.hedef_secildi(index_map[index])

func act_secenekleri_goster(acts: Array):
	ana_menu_panel.visible = false
	act_panel.visible = true
	menu_tipi = "ACT"
	secili_index = 0
	secenekler = acts.duplicate()
	act_menu_guncelle()

func _on_act_secildi(act_ismi: String):
	act_panel.visible = false
	menu_tipi = ""
	if battle_manager: battle_manager.act_secildi(act_ismi, 0)
