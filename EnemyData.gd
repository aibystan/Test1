extends Resource
class_name EnemyData

# --- TEMEL BİLGİLER ---
@export var isim: String = "Düşman"
@export var max_hp: int = 50
@export var current_hp: int = 50
@export var atk: int = 10
@export var def: int = 5

# --- GÖRSEL ---
@export var renk: Color = Color.RED  # Placeholder renk
@export var boyut: Vector2 = Vector2(64, 64)

# --- ACT SİSTEMİ ---
# Her düşmanın kendine özel act seçenekleri
@export var acts: Array[String] = ["Check", "Konuş"]

# Barış koşulları - hangi act'ler yapılmalı
@export var baris_kosullari: Array[String] = []

# Check mesajı
@export var check_mesaji: String = "Sıradan bir düşman."

# --- SAVAŞ MEKANİĞİ ---
@export var pattern_turu: String = "basit"  # basit, orta, zor, boss
@export var saldiri_gecikmesi: float = 2.0  # Saldırılar arası süre

# --- DURUM ---
var baris_edildi: bool = false
var yapilan_actler: Array[String] = []  # Hangi act'ler yapıldı

func act_yap(act_ismi: String) -> String:
	yapilan_actler.append(act_ismi)
	
	# Check özel
	if act_ismi == "Check":
		return check_mesaji
	
	# Barış koşulları kontrol et
	if baris_kosullari.size() > 0:
		var tamamlandi = true
		for kosul in baris_kosullari:
			if not kosul in yapilan_actler:
				tamamlandi = false
				break
		
		if tamamlandi:
			baris_edildi = true
			return isim + " artık savaşmak istemiyor!"
	
	# Varsayılan mesaj
	return isim + " ile " + act_ismi + " yaptın."

func hasar_al(miktar: int):
	current_hp -= miktar
	if current_hp < 0:
		current_hp = 0

func oldu_mu() -> bool:
	return current_hp <= 0
