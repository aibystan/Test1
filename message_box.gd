extends Panel

@onready var mesaj_label = $MarginContainer/MesajLabel

# Flavor text: kalıcı, değiştirilmez (saldırı sırasında da durur)
var flavor_metni: String = ""
# Sonuç: anlık gösterim (kısa, sonra flavor'a döner)
var sonuc_timer: float = 0.0
var sonuc_suresi: float = 1.2

func _ready():
	pass

func _process(delta):
	if sonuc_timer > 0:
		sonuc_timer -= delta
		if sonuc_timer <= 0:
			# Sonuç bitti, flavor text'e geri dön
			mesaj_label.text = flavor_metni

# Flavor text: her round başında düşman konuşması gibi bir şey
# İki karakter boyunca (ve düşman turu boyunca) değişmez
func flavor_goster(metin: String):
	flavor_metni = metin
	# Eğer şu an sonuç gösterilmiyorsa hemen göster
	if sonuc_timer <= 0:
		mesaj_label.text = flavor_metni

# Sadece timing sonucu (GOOD/MISS/PERFECT) — kısa gösterim, flavor'ın üzerine yazar
func sonuc_goster(sonuc: String):
	mesaj_label.text = sonuc
	sonuc_timer = sonuc_suresi

# Eski API - geriye dönük uyumluluk (battle_manager bazı yerlerde hâlâ kullanıyor olabilir)
func mesaj_goster(mesaj: String, _sure: float = 2.0):
	flavor_goster(mesaj)

func temizle():
	flavor_metni = ""
	sonuc_timer = 0
	mesaj_label.text = ""
