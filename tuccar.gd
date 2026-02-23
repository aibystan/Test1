extends StaticBody2D

@export var npc_ismi: String = "Merchant"
@export_multiline var mesajlar: Array[String] = [
	"This is a test dialogue.",
	"Elimde cok taze mallar var.",
	"Bir bakmak ister misin?"
]
@export var satilacak_urunler: Array[ItemData] = []

var oyuncu_yakin = false
var etkilesim_yasakli = false

func _process(_delta):
	# Diyalog kontrolü
	var diyalog_kutusu = get_tree().current_scene.find_child("DiyalogKutusu")
	var diyalog_acik = diyalog_kutusu and diyalog_kutusu.visible
	
	# Diyalog açıkken etkileşimi kilitle
	if diyalog_acik:
		etkilesim_yasakli = true
		return
	else:
		etkilesim_yasakli = false
	
	# Z tuşu - sadece diyalog kapalıyken
	if oyuncu_yakin and Input.is_action_just_pressed("tus_z") and not etkilesim_yasakli:
		if diyalog_kutusu:
			diyalog_kutusu.baslat(npc_ismi, mesajlar, self.dukkan_ac)
			etkilesim_yasakli = true

# Bu fonksiyon, konuşma bitince Diyalog Kutusu tarafından çağırılacak
func dukkan_ac():
	var dukkan = get_tree().current_scene.find_child("DukkanMenusu")
	if dukkan:
		dukkan.dukkani_ac(satilacak_urunler)

# --- ALAN KONTROLLERİ (Aynen kalacak) ---
func _ready():
	$Area2D.body_entered.connect(_on_alan_girildi)
	$Area2D.body_exited.connect(_on_alan_cikildi)

func _on_alan_girildi(body):
	if body.name == "Player":
		oyuncu_yakin = true

func _on_alan_cikildi(body):
	if body.name == "Player":
		oyuncu_yakin = false
