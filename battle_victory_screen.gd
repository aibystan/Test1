extends CanvasLayer

@onready var kazanma_label = $Panel/VBoxContainer/KazanmaLabel
@onready var odul_label = $Panel/VBoxContainer/OdulLabel
@onready var devam_label = $Panel/VBoxContainer/DevamLabel

var toplam_xp = 0
var toplam_gold = 0
var typewriter_aktif = false
var tam_metin = ""
var char_index = 0.0
var typewriter_hiz = 0.03
var input_kilitli = true

func _ready():
	visible = false

func goster(xp: int, gold: int):
	toplam_xp = xp
	toplam_gold = gold
	visible = true
	
	# Kazanma label'ı hemen göster
	kazanma_label.text = "You Won!"
	
	# Ödül metnini hazırla
	tam_metin = "You gained " + str(xp) + " XP and " + str(gold) + " Gold."
	char_index = 0.0
	typewriter_aktif = true
	odul_label.text = ""
	
	# Devam mesajı gizli
	devam_label.visible = false
	
	# Input kilitli
	input_kilitli = true

func _process(delta):
	if not visible:
		return
	
	# Typewriter animasyonu
	if typewriter_aktif:
		char_index += delta / typewriter_hiz
		var current_chars = int(char_index)
		
		if current_chars >= tam_metin.length():
			current_chars = tam_metin.length()
			typewriter_aktif = false
			typewriter_bitti()
		
		odul_label.text = tam_metin.substr(0, current_chars)
	
	# Z tuşu - devam et
	if Input.is_action_just_pressed("tus_z") and not input_kilitli:
		overworld_don()

func typewriter_bitti():
	# Typewriter bitince devam mesajını göster
	devam_label.visible = true
	input_kilitli = false

func overworld_don():
	print("=== OVERWORLD'E DÖNÜLÜYOR ===")
	
	# Altını ekle
	Global.altin += toplam_gold
	print("Gold eklendi: ", toplam_gold)
	
	# Düşmanı yenildi olarak işaretle
	if Global.has_meta("current_enemy_id"):
		var enemy_id = Global.get_meta("current_enemy_id")
		var defeat_key = "defeated_enemy_" + enemy_id
		
		print("Düşman yenildi olarak işaretleniyor:")
		print("  Enemy ID: ", enemy_id)
		print("  Defeat Key: ", defeat_key)
		
		Global.set_meta(defeat_key, true)
		Global.remove_meta("current_enemy_id")
		
		print("İşaretleme tamamlandı!")
	else:
		print("UYARI: current_enemy_id bulunamadı!")
	
	# Player pozisyonunu kaydet
	if Global.has_meta("battle_return_position"):
		var pozisyon = Global.get_meta("battle_return_position")
		Global.yuklenen_pozisyon = pozisyon
		Global.remove_meta("battle_return_position")
	
	# Overworld'e dön
	visible = false
	get_tree().paused = false
	
	# Önceki sahneye dön
	if Global.has_meta("battle_return_scene"):
		var sahne = Global.get_meta("battle_return_scene")
		Global.remove_meta("battle_return_scene")
		print("Sahneye dönülüyor: ", sahne)
		get_tree().change_scene_to_file(sahne)
	else:
		print("Fallback: overworld.tscn")
		get_tree().change_scene_to_file("res://Rooms/overworld.tscn")
