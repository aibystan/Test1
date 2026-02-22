extends CanvasLayer

var message_box: Node = null
var stats_panel: Node = null
@onready var ana_menu_panel = $AnaMenuPanel
@onready var hedef_panel = $HedefPanel
@onready var act_panel = $ActPanel
var blur_rect: Node = null
var _blur_canvas: Node = null

var battle_manager: BattleManager
var menu_tipi: String = "ANA"
var secili_index: int = 0
var _ana_menu_index: int = 0  # Alt panelden çıkınca buraya dön
var secenekler: Array = []
var hedef_listesi: Array = []
var _hedef_dusmanlar: Array = []

const SH = 360
const PH = 90
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


var _blur_tween: Tween = null

func _blur_goster():
	if not blur_rect or not blur_rect.material:
		return
	# Zaten tamamen açıksa tekrar tween etme (flash önleme)
	if _blur_canvas.visible and blur_rect.material.get_shader_parameter("overall_alpha") >= 1.0:
		return
	if _blur_tween:
		_blur_tween.kill()
	blur_rect.material.set_shader_parameter("overall_alpha", 0.0)
	_blur_canvas.visible = true
	_blur_tween = create_tween()
	_blur_tween.tween_method(func(v: float): blur_rect.material.set_shader_parameter("overall_alpha", v), 0.0, 1.0, 0.25)

func _blur_gizle():
	if not blur_rect or not blur_rect.material:
		return
	if _blur_tween:
		_blur_tween.kill()
	_blur_tween = create_tween()
	_blur_tween.tween_method(func(v: float): blur_rect.material.set_shader_parameter("overall_alpha", v), 1.0, 0.0, 0.2)
	_blur_tween.tween_callback(func(): _blur_canvas.visible = false)

func _ready():
	await get_tree().process_frame
	# UIArkaplan'dan stats_panel ve message_box bul
	var ui_arkaplan = get_parent().get_node_or_null("UIArkaplan")
	if ui_arkaplan:
		stats_panel = ui_arkaplan.get_node_or_null("StatsPanel")
		message_box = ui_arkaplan.get_node_or_null("MessageBox")
	if message_box:
		message_box.visible = false
	# BlurCanvas bul
	var canvas = get_parent().get_node_or_null("BlurCanvas")
	if canvas:
		_blur_canvas = canvas
		blur_rect = canvas.get_node_or_null("BlurRect")
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
	_blur_gizle()
	if message_box:
		message_box.visible = false
	_panelleri_gizle_bekleniyor = true
	_stat_hedef_y = float(SH + PH)
	_menu_hedef_y = float(SH + PH)
	await _gizleme_bitti

func sadece_stat_goster():
	_blur_gizle()
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
	if Input.is_action_just_pressed("ui_up"):
		secili_index = (secili_index - 1 + hedef_listesi.size()) % hedef_listesi.size()
		hedef_menu_guncelle()
	if Input.is_action_just_pressed("ui_down"):
		secili_index = (secili_index + 1) % hedef_listesi.size()
		hedef_menu_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		_on_hedef_secildi(secili_index)
	if Input.is_action_just_pressed("tus_x"):
		hedef_panel.visible = false
		ana_menu_panel.visible = true
		menu_tipi = "ANA"
		secili_index = _ana_menu_index
		ana_menu_guncelle()
		_blur_gizle()

func hedef_menu_guncelle():
	var container = hedef_panel.get_node_or_null("MarginContainer/HedefContainer")
	if not container:
		return
	var satirlar = container.get_children()
	for i in range(hedef_listesi.size()):
		if i >= satirlar.size():
			break
		var satir = satirlar[i]
		var isim_lbl = satir.get_node_or_null("IsimLabel")
		if isim_lbl:
			var ok = "> " if i == secili_index else "  "
			isim_lbl.text = ok + hedef_listesi[i]
		var d = _hedef_dusmanlar[i] if i < _hedef_dusmanlar.size() else null
		if d:
			var oran = clampf(float(d.current_hp) / float(d.max_hp), 0.0, 1.0)
			var fg = satir.get_node_or_null("HPBg/HPFg")
			if fg:
				fg.anchor_right = oran
				fg.offset_right = 0.0
func _hedef_satirlari_olustur():
	var BAR_GENISLIK = 120.0
	var BAR_YUKSEKLIK = 8.0

	# Eski label gizle
	hedef_panel.get_node("MarginContainer/Label").visible = false

	# Container oluştur ya da temizle
	var mc = hedef_panel.get_node("MarginContainer")
	var container = mc.get_node_or_null("HedefContainer")
	if container:
		for c in container.get_children():
			c.queue_free()
	else:
		container = VBoxContainer.new()
		container.name = "HedefContainer"
		container.layout_mode = 2
		container.add_theme_constant_override("separation", 6)
		mc.add_child(container)

	for i in range(hedef_listesi.size()):
		var satir = VBoxContainer.new()
		satir.add_theme_constant_override("separation", 2)
		container.add_child(satir)

		# İsim label
		var isim_lbl = Label.new()
		isim_lbl.name = "IsimLabel"
		var ok = "> " if i == secili_index else "  "
		isim_lbl.text = ok + hedef_listesi[i]
		isim_lbl.add_theme_font_size_override("font_size", 10)
		satir.add_child(isim_lbl)

		# HP bar container (Control, sabit boyutlu)
		var hp_bg = ColorRect.new()
		hp_bg.name = "HPBg"
		hp_bg.color = Color(0.6, 0.0, 0.0, 1.0)
		hp_bg.custom_minimum_size = Vector2(BAR_GENISLIK, BAR_YUKSEKLIK)
		satir.add_child(hp_bg)

		# Yeşil ön bar — anchor ile parent'a oransal
		var hp_fg = ColorRect.new()
		hp_fg.name = "HPFg"
		hp_fg.color = Color(0.0, 0.8, 0.0, 1.0)
		hp_fg.layout_mode = 1
		hp_fg.anchor_left = 0.0
		hp_fg.anchor_top = 0.0
		hp_fg.anchor_bottom = 1.0
		var d = _hedef_dusmanlar[i] if i < _hedef_dusmanlar.size() else null
		var oran = 1.0
		if d:
			oran = clampf(float(d.current_hp) / float(d.max_hp), 0.0, 1.0)
		hp_fg.anchor_right = oran
		hp_fg.offset_right = 0.0
		hp_fg.offset_bottom = 0.0
		hp_bg.add_child(hp_fg)

	# Panel boyutunu ayarla
	hedef_panel.offset_right = hedef_panel.offset_left + BAR_GENISLIK + 48
	hedef_panel.offset_bottom = hedef_panel.offset_top + hedef_listesi.size() * 36 + 24


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
		secili_index = _ana_menu_index
		ana_menu_guncelle()
		_blur_gizle()

func act_menu_guncelle():
	var text = "Act:\n"
	for i in range(secenekler.size()):
		text += ("> " if i == secili_index else "  ") + secenekler[i] + "\n"
	act_panel.get_node("MarginContainer/Label").text = text

# --- TURN ---
func turn_menusu_goster(_k: Dictionary):
	_blur_gizle()
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
	_ana_menu_index = secili_index
	_blur_goster()
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
	_hedef_satirlari_olustur()
	hedef_menu_guncelle()

func _on_hedef_secildi(index: int):
	hedef_panel.visible = false
	menu_tipi = ""
	if battle_manager:
		var idx_map = get_meta("hedef_index_map", [])
		if index < idx_map.size():
			battle_manager.hedef_secildi(idx_map[index])

func act_secenekleri_goster(acts: Array):
	_blur_goster()
	ana_menu_panel.visible = false
	act_panel.visible = true
	menu_tipi = "ACT"
	secili_index = 0
	secenekler = acts.duplicate()
	act_menu_guncelle()

func _on_act_secildi(act_ismi: String):
	_blur_gizle()
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
	_blur_goster()
	_sihir_verileri = sihirler
	_sihir_karakter = karakter_isim
	_sihir_battle_manager = bm
	_ana_menu_index = secili_index
	secili_index = 0
	menu_tipi = "SIHIR"
	ana_menu_panel.visible = false
	act_panel.visible = true
	act_panel.get_node("MarginContainer/Label").text = _sihir_metni_olustur()
	_sihir_panel_yeniden_boyutlandir()
	# QUT label oluştur (yoksa)
	if not act_panel.get_node_or_null("QutLabel"):
		var qut_lbl = Label.new()
		qut_lbl.name = "QutLabel"
		qut_lbl.add_theme_font_size_override("font_size", 9)
		qut_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.2, 1.0))
		qut_lbl.layout_mode = 1
		qut_lbl.anchor_left = 0.0
		qut_lbl.anchor_top = 0.0
		qut_lbl.anchor_right = 1.0
		qut_lbl.anchor_bottom = 0.0
		qut_lbl.offset_top = 6
		qut_lbl.offset_bottom = 20
		qut_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		act_panel.add_child(qut_lbl)
	_sihir_qut_label_guncelle()

func _sihir_metni_olustur() -> String:
	var sqa_listesi = _sihir_verileri.get("SQA", [])
	var dqa_listesi = _sihir_verileri.get("DQA", [])
	var text = "Sihir\n"

	text += "-- SQA --\n"
	for i in range(sqa_listesi.size()):
		var ok = "> " if i == secili_index else "  "
		text += ok + sqa_listesi[i]["isim"] + "\n"
	if sqa_listesi.is_empty():
		text += "  (Yok)\n"

	text += "-- DQA --\n"
	for i in range(dqa_listesi.size()):
		var global_i = sqa_listesi.size() + i
		var ok = "> " if global_i == secili_index else "  "
		text += ok + dqa_listesi[i]["isim"] + "\n"
	if dqa_listesi.is_empty():
		text += "  (Yok)\n"

	return text

func _secili_sihir_qut() -> String:
	var sqa_listesi = _sihir_verileri.get("SQA", [])
	var dqa_listesi = _sihir_verileri.get("DQA", [])
	if secili_index < sqa_listesi.size():
		return str(sqa_listesi[secili_index].get("qut", 0)) + " QUT"
	var dqa_i = secili_index - sqa_listesi.size()
	if dqa_i < dqa_listesi.size():
		return str(dqa_listesi[dqa_i].get("qut_her", 0)) + "x2 QUT"
	return ""

func _sihir_qut_label_guncelle():
	var qut_label = act_panel.get_node_or_null("QutLabel")
	if qut_label:
		qut_label.text = _secili_sihir_qut()

func _sihir_panel_yeniden_boyutlandir():
	var label = act_panel.get_node("MarginContainer/Label")
	var margin = 16  # margin_left + margin_right (8+8)
	var label_min = label.get_minimum_size()
	var yeni_genislik = label_min.x + margin + 16
	var yeni_yukseklik = label_min.y + margin + 16
	act_panel.offset_right = act_panel.offset_left + max(yeni_genislik, 170)
	act_panel.offset_top = act_panel.offset_bottom - yeni_yukseklik

func sihir_paneli_kapat(blur_kapat: bool = true):
	if blur_kapat:
		_blur_gizle()
	var qut_label = act_panel.get_node_or_null("QutLabel")
	if qut_label:
		qut_label.visible = false
	act_panel.visible = false
	menu_tipi = ""

func tum_panelleri_kapat():
	_blur_gizle()
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
		secili_index = _ana_menu_index
		ana_menu_guncelle()
		_blur_gizle()

func _sihir_menu_kontrol():
	if Input.is_action_just_pressed("ui_up"):
		secili_index = (secili_index - 1 + _sihir_secenekler.size()) % _sihir_secenekler.size()
		act_panel.get_node("MarginContainer/Label").text = _sihir_metni_olustur()
		_sihir_panel_yeniden_boyutlandir()
		_sihir_qut_label_guncelle()
	if Input.is_action_just_pressed("ui_down"):
		secili_index = (secili_index + 1) % _sihir_secenekler.size()
		act_panel.get_node("MarginContainer/Label").text = _sihir_metni_olustur()
		_sihir_panel_yeniden_boyutlandir()
		_sihir_qut_label_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		_sihir_sec()
	if Input.is_action_just_pressed("tus_x"):
		sihir_paneli_kapat()
		ana_menu_panel.visible = true
		menu_tipi = "ANA"
		secili_index = _ana_menu_index
		ana_menu_guncelle()
		_blur_gizle()

func _sihir_sec():
	# Hangi sihir seçildi bul
	var sqa_listesi = _sihir_verileri.get("SQA", [])
	var dqa_listesi = _sihir_verileri.get("DQA", [])
	var idx = secili_index

	if idx < sqa_listesi.size():
		var sihir = sqa_listesi[idx]
		sihir_paneli_kapat(false)  # blur açık kalsın, hedef seçimi açacak
		if _sihir_battle_manager:
			_sihir_battle_manager.sihir_secildi("SQA", sihir)
	else:
		idx -= sqa_listesi.size()
		if idx < dqa_listesi.size():
			var sihir = dqa_listesi[idx]
			sihir_paneli_kapat(false)  # blur açık kalsın, hedef seçimi açacak
			if _sihir_battle_manager:
				_sihir_battle_manager.sihir_secildi("DQA", sihir)

# ============================================================
# İTEM MENÜSÜ
# ============================================================

var _item_listesi_ui: Array = []
var _item_battle_manager = null

func item_menusu_ac(liste: Array, bm):
	_item_listesi_ui = liste
	_blur_goster()
	_item_battle_manager = bm
	_sihir_battle_manager = bm
	_ana_menu_index = secili_index
	secili_index = 0
	menu_tipi = "ITEM"
	ana_menu_panel.visible = false
	act_panel.visible = true
	_item_metni_guncelle()

func _item_metni_guncelle():
	var SATIR = 7  # Her sütunda max eşya
	var sol_size = min(SATIR, _item_listesi_ui.size())
	var sag_size = max(0, _item_listesi_ui.size() - SATIR)

	var text = "Item:\n"
	for i in range(max(sol_size, sag_size)):
		# Sol sütun
		var sol = ""
		if i < sol_size:
			var esya = _item_listesi_ui[i]["esya"]
			var ok = "> " if i == secili_index else "  "
			sol = ok + esya.isim
		# Sağ sütun
		var sag = ""
		if i < sag_size:
			var sag_i = SATIR + i
			var esya = _item_listesi_ui[sag_i]["esya"]
			var ok = "> " if sag_i == secili_index else "  "
			sag = ok + esya.isim
		# Satırı birleştir (sol 18 karakter sabit genişlik)
		text += sol.rpad(22) + sag + "\n"
	var label = act_panel.get_node("MarginContainer/Label")
	label.text = text
	# İçeriğe göre panel genişliğini ayarla
	await get_tree().process_frame
	var min_size = label.get_minimum_size()
	act_panel.offset_right = act_panel.offset_left + min_size.x + 20
	act_panel.offset_bottom = act_panel.offset_top + min_size.y + 20

func item_paneli_kapat():
	_blur_gizle()
	act_panel.visible = false
	menu_tipi = ""

func _item_menu_kontrol():
	var SATIR = 7
	var toplam = _item_listesi_ui.size()
	var sutun = 0 if secili_index < SATIR else 1
	var sutun_baslangic = sutun * SATIR
	var sutun_bitis = min(sutun_baslangic + SATIR, toplam)
	var sutun_boyut = sutun_bitis - sutun_baslangic

	if Input.is_action_just_pressed("ui_up"):
		var sutun_i = secili_index - sutun_baslangic
		secili_index = sutun_baslangic + (sutun_i - 1 + sutun_boyut) % sutun_boyut
		_item_metni_guncelle()
	if Input.is_action_just_pressed("ui_down"):
		var sutun_i = secili_index - sutun_baslangic
		secili_index = sutun_baslangic + (sutun_i + 1) % sutun_boyut
		_item_metni_guncelle()
	if Input.is_action_just_pressed("ui_left") and toplam > SATIR:
		var sutun_i = secili_index % SATIR
		secili_index = sutun_i  # Sol sütuna geç
		_item_metni_guncelle()
	if Input.is_action_just_pressed("ui_right") and toplam > SATIR:
		var sutun_i = secili_index % SATIR
		var hedef = SATIR + sutun_i
		if hedef < toplam:
			secili_index = hedef  # Sağ sütuna geç
		_item_metni_guncelle()
	if Input.is_action_just_pressed("tus_z"):
		item_paneli_kapat()
		if _item_battle_manager:
			_item_battle_manager.item_secildi(secili_index)
	if Input.is_action_just_pressed("tus_x"):
		item_paneli_kapat()
		ana_menu_panel.visible = true
		menu_tipi = "ANA"
		secili_index = _ana_menu_index
		ana_menu_guncelle()
		_blur_gizle()
