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

const SH = 360
const PH = 55
const STATS_W = 200
const MENU_W = 440

# Manuel animasyon state - başlangıç değerleri _ready'de set edilir
var _stat_hedef_y: float = 415.0
var _menu_hedef_y: float = 415.0
var _animasyon_hizi: float = 600.0  # piksel/saniye
var _animasyon_aktif: bool = false   # _ready bitmeden hareket etme

var _panelleri_gizle_bekleniyor: bool = false
var _gizle_signal_verildi: bool = false

signal _gizleme_bitti

func _ready():
	if message_box:
		message_box.visible = false
	ana_menu_panel.visible = false
	# 1 frame bekle ki node'lar yerleşsin
	await get_tree().process_frame
	# Gerçek başlangıç konumunu oku, hedefi buna eşitle
	var baslangic_y = stats_panel.global_position.y
	_stat_hedef_y = baslangic_y
	_menu_hedef_y = baslangic_y
	_animasyon_aktif = true

func _process(delta):
	if not _animasyon_aktif:
		return

	var adim = _animasyon_hizi * delta
	var sp_y = stats_panel.global_position.y
	var mp_y = ana_menu_panel.global_position.y

	if abs(sp_y - _stat_hedef_y) > 0.5:
		stats_panel.global_position.y = move_toward(sp_y, _stat_hedef_y, adim)
	else:
		stats_panel.global_position.y = _stat_hedef_y

	if abs(mp_y - _menu_hedef_y) > 0.5:
		ana_menu_panel.global_position.y = move_toward(mp_y, _menu_hedef_y, adim)
	else:
		ana_menu_panel.global_position.y = _menu_hedef_y
		if _panelleri_gizle_bekleniyor:
			_panelleri_gizle_bekleniyor = false
			ana_menu_panel.visible = false
			_gizleme_bitti.emit()

	if not visible: return
	klavye_kontrol()

# --- ANİMASYONLAR ---
func panelleri_goster():
	ana_menu_panel.visible = true
	_stat_hedef_y = float(SH - PH)
	_menu_hedef_y = float(SH - PH)

func panelleri_gizle():
	if message_box:
		message_box.visible = false
	_panelleri_gizle_bekleniyor = true
	_stat_hedef_y = float(SH + PH)
	_menu_hedef_y = float(SH + PH)
	await _gizleme_bitti

func sadece_stat_goster():
	ana_menu_panel.visible = false
	if message_box:
		message_box.visible = false
	_stat_hedef_y = float(SH - PH)
	_menu_hedef_y = float(SH + PH)

# --- KLAVYE ---
func klavye_kontrol():
	match menu_tipi:
		"ANA":          ana_menu_kontrol()
		"HEDEF":        hedef_menu_kontrol()
		"ACT":          act_menu_kontrol()
		"SIHIR":        _sihir_menu_kontrol()
		"PARTI_HEDEF":  _parti_hedef_kontrol()
		"ITEM":         _item_menu_kontrol()

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

# --- TURN ---
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
	p.get_node("QutLabel").text  = "QUT %d/%d" % [k.get("qut", 0), k.get("max_qut", 200)]
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
		if not dusmanlar[i]["data"].oldu_mu():
			hedef_listesi.append(dusmanlar[i]["data"].isim)
			_hedef_dusmanlar.append(dusmanlar[i]["data"])
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

# ============================================================
# SİHİR MENÜSÜ
# ============================================================

var _sihir_verileri: Dictionary = {}
var _sihir_karakter: String = ""
var _sihir_battle_manager = null
var _sihir_secenekler: Array = []

func sihir_menusu_ac(secenekler: Array, sihirler: Dictionary, karakter_isim: String, bm):
	_sihir_secenekler = secenekler
	_sihir_verileri = sihirler
	_sihir_karakter = karakter_isim
	_sihir_battle_manager = bm
	secili_index = 0
	menu_tipi = "SIHIR"
	ana_menu_panel.visible = false
	act_panel.visible = true
	act_panel.get_node("MarginContainer/Label").text = _sihir_metni_olustur()

func _sihir_metni_olustur() -> String:
	var text = "Sihir:\n"
	for i in range(_sihir_secenekler.size()):
		text += ("> " if i == secili_index else "  ") + _sihir_secenekler[i] + "\n"
	return text

func sihir_paneli_kapat():
	act_panel.visible = false
	menu_tipi = ""

func tum_panelleri_kapat():
	act_panel.visible = false
	hedef_panel.visible = false
	menu_tipi = ""

# Parti hedef seçimi (iyileşme için)
var _parti_liste: Array = []

var _parti_mod: String = ""

func parti_hedef_sec_goster(party: Array, mod: String = "SIHIR"):
	_parti_liste = party
	_parti_mod = mod
	secili_index = 0
	menu_tipi = "PARTI_HEDEF"
	hedef_panel.visible = true
	_parti_hedef_guncelle()

func _parti_hedef_guncelle():
	var text = "Hedef:\n"
	for i in range(_parti_liste.size()):
		var ok = "> " if i == secili_index else "  "
		var k = _parti_liste[i]
		var baygin = " 💀" if k.get("baygin", false) else ""
		text += ok + k["isim"] + baygin + " HP:%d/%d\n" % [k["hp"], k["max_hp"]]
	hedef_panel.get_node("MarginContainer/Label").text = text

func _parti_hedef_kontrol():
	if Input.is_action_just_pressed("ui_up"):
		secili_index = (secili_index - 1 + _parti_liste.size()) % _parti_liste.size()
		_parti_hedef_guncelle()
	if Input.is_action_just_pressed("ui_down"):
		secili_index = (secili_index + 1) % _parti_liste.size()
		_parti_hedef_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		hedef_panel.visible = false
		menu_tipi = ""
		if _parti_mod == "ITEM":
			_parti_mod = ""
			if _sihir_battle_manager:
				_sihir_battle_manager.item_hedef_secildi(secili_index)
		else:
			_parti_mod = ""
			if _sihir_battle_manager:
				_sihir_battle_manager.parti_hedef_secildi(secili_index)
	if Input.is_action_just_pressed("tus_x"):
		hedef_panel.visible = false
		ana_menu_panel.visible = true
		menu_tipi = "ANA"

func _sihir_menu_kontrol():
	if Input.is_action_just_pressed("ui_up"):
		secili_index = (secili_index - 1 + _sihir_secenekler.size()) % _sihir_secenekler.size()
		act_panel.get_node("MarginContainer/Label").text = _sihir_metni_olustur()
	if Input.is_action_just_pressed("ui_down"):
		secili_index = (secili_index + 1) % _sihir_secenekler.size()
		act_panel.get_node("MarginContainer/Label").text = _sihir_metni_olustur()
	if Input.is_action_just_pressed("tus_z"):
		_sihir_sec()
	if Input.is_action_just_pressed("tus_x"):
		sihir_paneli_kapat()
		ana_menu_panel.visible = true
		menu_tipi = "ANA"

func _sihir_sec():
	# Hangi sihir seçildi bul
	var sqa_listesi = _sihir_verileri.get("SQA", [])
	var dqa_listesi = _sihir_verileri.get("DQA", [])
	var idx = secili_index

	if idx < sqa_listesi.size():
		var sihir = sqa_listesi[idx]
		sihir_paneli_kapat()
		if _sihir_battle_manager:
			_sihir_battle_manager.sihir_secildi("SQA", sihir)
	else:
		idx -= sqa_listesi.size()
		if idx < dqa_listesi.size():
			var sihir = dqa_listesi[idx]
			sihir_paneli_kapat()
			if _sihir_battle_manager:
				_sihir_battle_manager.sihir_secildi("DQA", sihir)

# ============================================================
# İTEM MENÜSÜ
# ============================================================

var _item_listesi_ui: Array = []
var _item_battle_manager = null

func item_menusu_ac(liste: Array, bm):
	_item_listesi_ui = liste
	_item_battle_manager = bm
	_sihir_battle_manager = bm
	secili_index = 0
	menu_tipi = "ITEM"
	ana_menu_panel.visible = false
	act_panel.visible = true
	_item_metni_guncelle()

func _item_metni_guncelle():
	var text = "Item:\n"
	for i in range(_item_listesi_ui.size()):
		var esya = _item_listesi_ui[i]["esya"]
		var ok = "> " if i == secili_index else "  "
		text += ok + esya.isim + "\n"
	act_panel.get_node("MarginContainer/Label").text = text

func item_paneli_kapat():
	act_panel.visible = false
	menu_tipi = ""

func _item_menu_kontrol():
	if Input.is_action_just_pressed("ui_up"):
		secili_index = (secili_index - 1 + _item_listesi_ui.size()) % _item_listesi_ui.size()
		_item_metni_guncelle()
	if Input.is_action_just_pressed("ui_down"):
		secili_index = (secili_index + 1) % _item_listesi_ui.size()
		_item_metni_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		item_paneli_kapat()
		if _item_battle_manager:
			_item_battle_manager.item_secildi(secili_index)
	if Input.is_action_just_pressed("tus_x"):
		item_paneli_kapat()
		ana_menu_panel.visible = true
		menu_tipi = "ANA"
