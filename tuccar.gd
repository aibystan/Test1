extends StaticBody2D

@export var satilacak_urunler: Array[ItemData] = []
var oyuncu_yakin = false

func _process(_delta):
	# Diyalog kutusuyla aynı mantık, "Z"ye basınca çalış
	if oyuncu_yakin and Input.is_action_just_pressed("tus_z"):
		
		# Diyalog kutusunu bul
		var diyalog_kutusu = get_tree().current_scene.find_child("DiyalogKutusu")
		
		if diyalog_kutusu:
			var soyleyeceklerim = [
				"Hoş geldin gezgin!",
				"Elimde çok taze mallar var.",
				"Bir bakmak ister misin?"
			]
			# ÖNEMLİ: 3. parametre olarak dukkan_ac fonksiyonunu gönderiyoruz!
			# "self.dukkan_ac" diyerek bu fonksiyonun adresini veriyoruz.
			diyalog_kutusu.baslat("Gezgin Tüccar", soyleyeceklerim, self.dukkan_ac)

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
