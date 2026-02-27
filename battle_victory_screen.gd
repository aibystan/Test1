extends CanvasLayer

@onready var kazanma_label = $IcerikContainer/KazanmaLabel
@onready var xp_deger = $IcerikContainer/OdulContainer/XPKutusu/XPIcerik/XPDeger
@onready var gold_deger = $IcerikContainer/OdulContainer/GoldKutusu/GoldIcerik/GoldDeger
@onready var devam_label = $IcerikContainer/DevamLabel
@onready var odul_container = $IcerikContainer/OdulContainer

var toplam_xp = 0
var toplam_gold = 0
var input_kilitli = true

func _ready():
	visible = false

func goster(xp: int, gold: int):
	toplam_xp = xp
	toplam_gold = gold
	visible = true
	# Metin kutusunu gizle
	var ui_arkaplan = get_tree().current_scene.get_node_or_null("UIArkaplan")
	if ui_arkaplan:
		var mb = ui_arkaplan.get_node_or_null("MessageBox")
		if mb: mb.visible = false
	input_kilitli = true
	
	# Başlangıç durumu
	kazanma_label.modulate.a = 0.0
	odul_container.modulate.a = 0.0
	devam_label.visible = false
	xp_deger.text = "+0"
	gold_deger.text = "+0"
	
	_animasyon_baslat()

func _animasyon_baslat():
	# 1. Başlık fade in
	var tw = create_tween()
	tw.tween_property(kazanma_label, "modulate:a", 1.0, 0.4)
	tw.tween_interval(0.2)
	# 2. Ödüller fade in + sayaç
	tw.tween_property(odul_container, "modulate:a", 1.0, 0.3)
	tw.tween_callback(_sayac_baslat)

func _sayac_baslat():
	var tw = create_tween()
	tw.tween_method(_xp_guncelle, 0, toplam_xp, 0.6)
	tw.parallel().tween_method(_gold_guncelle, 0, toplam_gold, 0.6)
	tw.tween_interval(0.2)
	tw.tween_callback(_devam_goster)

func _xp_guncelle(deger: int):
	xp_deger.text = "+" + str(deger)

func _gold_guncelle(deger: int):
	gold_deger.text = "+" + str(deger)

func _devam_goster():
	devam_label.visible = true
	var tw = create_tween()
	tw.tween_property(devam_label, "modulate:a", 1.0, 0.3)
	tw.tween_interval(0.4)
	tw.tween_callback(func(): input_kilitli = false)

func _process(_delta):
	if not visible: return
	if Input.is_action_just_pressed("tus_z") and not input_kilitli:
		overworld_don()

func overworld_don():
	Global.altin += toplam_gold
	
	if Global.has_meta("current_enemy_id"):
		var enemy_id = Global.get_meta("current_enemy_id")
		Global.defeated_enemies[enemy_id] = true
		Global.remove_meta("current_enemy_id")
	
	if Global.has_meta("battle_return_position"):
		Global.yuklenen_pozisyon = Global.get_meta("battle_return_position")
		Global.remove_meta("battle_return_position")
	
	visible = false
	get_tree().paused = false
	
	var hedef = "res://Rooms/overworld.tscn"
	if Global.has_meta("battle_return_scene"):
		hedef = Global.get_meta("battle_return_scene")
		Global.remove_meta("battle_return_scene")
	
	# Efekti sahne değişiminden önce global olarak ayarla
	Global.set_meta("savas_bitis_efekti", true)
	get_tree().change_scene_to_file(hedef)
