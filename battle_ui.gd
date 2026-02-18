extends CanvasLayer

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
var _hedef_dusmanlar: Array = []

# Ekran 640x360
# Alt panel: StatsPanel sol 200px, AnaMenuPanel sağ 440px, yükseklik 55px
const SW = 640
const SH = 360
const PH = 55      # panel yüksekliği
const STATS_W = 200
const MENU_W = 440

func _ready():
	visible = true
	_panelleri_ayarla()
	ana_menu_panel.visible = false
	hedef_panel.visible = false
	act_panel.visible = false
	if message_box:
		message_box.visible = false

func _panelleri_ayarla():
	stats_panel.set_position(Vector2(0, SH))
	stats_panel.set_size(Vector2(STATS_W, PH))

	ana_menu_panel.set_position(Vector2(STATS_W, SH))
	ana_menu_panel.set_size(Vector2(MENU_W, PH))

	hedef_panel.set_position(Vector2(SW / 2 - 85, SH / 2 - 45))
	hedef_panel.set_size(Vector2(170, 90))

	act_panel.set_position(Vector2(SW / 2 - 85, SH / 2 - 55))
	act_panel.set_size(Vector2(170, 110))

func _process(_delta):
	if not visible: return
	klavye_kontrol()

func klavye_kontrol():
	match menu_tipi:
		"ANA":   ana_menu_kontrol()
		"HEDEF": hedef_menu_kontrol()
		"ACT":   act_menu_kontrol()

# --- ANİMASYONLAR ---
func panelleri_goster():
	ana_menu_panel.visible = true
	if message_box:
		message_box.visible = false
	var hy = float(SH - PH)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(stats_panel,    "position:y", hy, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(ana_menu_panel, "position:y", hy, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func panelleri_gizle():
	if message_box:
		message_box.visible = false
	var tw = create_tween().set_parallel(true)
	tw.tween_property(stats_panel,    "position:y", float(SH), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(ana_menu_panel, "position:y", float(SH), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tw.finished
	ana_menu_panel.visible = false

# Düşman konuşma fazı: sadece stat paneli, metin kutusu KAPALI
func sadece_stat_goster():
	ana_menu_panel.visible = false
	if message_box:
		message_box.visible = false
	var hy = float(SH - PH)
	var tw = create_tween()
	tw.tween_property(stats_panel, "position:y", hy, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

# Konuşma bitti, pattern başlıyor
func metin_kutusunu_ac():
	if message_box:
		message_box.visible = true

# --- ANA MENÜ ---
func ana_menu_kontrol():
	if Input.is_action_just_pressed("ui_left"):
		secili_index = (secili_index - 1 + 5) % 5
		ana_menu_guncelle()
	if Input.is_action_just_pressed("ui_right"):
		secili_index = (secili_index + 1) % 5
		ana_menu_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		ana_menu_sec()

func ana_menu_guncelle():
	var hbox = ana_menu_panel.get_node("MarginContainer/HBoxContainer")
	var btns = ["SaldirBtn","SihirBtn","EylemBtn","ItemBtn","InsafBtn"]
	for i in range(btns.size()):
		hbox.get_node(btns[i]).modulate = Color(1,1,0) if i == secili_index else Color(1,1,1)

func ana_menu_sec():
	var eylemler = ["SALDIR","SIHIR","EYLEM","ITEM","INSAF"]
	if battle_manager:
		battle_manager.player_eylem_sec(eylemler[secili_index])

# --- HEDEF MENÜ ---
func hedef_menu_kontrol():
	if Input.is_action_just_pressed("ui_left"):
		secili_index = (secili_index - 1 + hedef_listesi.size()) % hedef_listesi.size()
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
	var text = "Hedef:\n"
	for i in range(hedef_listesi.size()):
		var ok = "> " if i == secili_index else "  "
		var d = _hedef_dusmanlar[i] if i < _hedef_dusmanlar.size() else null
		var bar = ""
		if d:
			var dolu = int(float(d.current_hp) / float(d.max_hp) * 6)
			bar = " [" + "|".repeat(dolu) + ".".repeat(6 - dolu) + "]"
		text += ok + hedef_listesi[i] + bar + "\n"
	hedef_panel.get_node("MarginContainer/Label").text = text

# --- ACT MENÜ ---
func act_menu_kontrol():
	if Input.is_action_just_pressed("ui_up"):
		secili_index = (secili_index - 1 + secenekler.size()) % secenekler.size()
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
	var text = "Act:\n"
	for i in range(secenekler.size()):
		text += ("> " if i == secili_index else "  ") + secenekler[i] + "\n"
	act_panel.get_node("MarginContainer/Label").text = text

# --- TURN SİSTEMİ ---
func turn_menusu_goster(_k: Dictionary):
	menu_tipi = "ANA"
	secili_index = 0
	stat_guncelle()
	ana_menu_guncelle()
	panelleri_goster()

func stat_guncelle():
	_stat_yaz(0, "Karakter1")
	_stat_yaz(1, "Karakter2")

func _stat_yaz(ki: int, node_isim: String):
	if ki >= Global.party_data.size(): return
	var k = Global.party_data[ki]
	var p = stats_panel.get_node("MarginContainer/HBoxContainer/" + node_isim)
	var baygin = k.get("baygin", false)
	p.get_node("IsimLabel").text = k["isim"] + (" 💀" if baygin else "")
	p.get_node("HPLabel").text   = "HP %d/%d" % [k["hp"], k["max_hp"]]
	p.get_node("QutLabel").text  = "QUT %d" % (Global.current_qut if ki == 0 else k.get("qut", 0))
	p.get_node("GPLabel").text   = "GP %d%%" % Global.graze_points
	p.modulate = Color(0.5, 0.5, 0.5) if baygin else Color(1, 1, 1)

# --- HEDEF / ACT ---
func hedef_secim_goster(dusmanlar: Array):
	ana_menu_panel.visible = false
	hedef_panel.visible = true
	menu_tipi = "HEDEF"
	secili_index = 0
	hedef_listesi.clear()
	_hedef_dusmanlar.clear()
	var idx_map = []
	for i in range(dusmanlar.size()):
		var d = dusmanlar[i]
		if not d["data"].oldu_mu():
			hedef_listesi.append(d["data"].isim)
			_hedef_dusmanlar.append(d["data"])
			idx_map.append(i)
	set_meta("hedef_index_map", idx_map)
	hedef_menu_guncelle()

func _on_hedef_secildi(index: int):
	hedef_panel.visible = false
	menu_tipi = ""
	if battle_manager:
		var idx_map = get_meta("hedef_index_map", [])
		if index < idx_map.size():
			battle_manager.hedef_secildi(idx_map[index])

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
