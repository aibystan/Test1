extends Control

# --- SİNYALLER ---
signal timing_tamamlandi(kalite: String, carpan: float)

# --- REFERANSLAR ---
@onready var bar_container = $BarContainer
@onready var bar_bg = $BarContainer/BarBackground
@onready var cursor = $BarContainer/Cursor
@onready var perfect_zone = $BarContainer/PerfectZone
@onready var good_zone = $BarContainer/GoodZone
@onready var sonuc_label = $SonucLabel

# --- DEĞİŞKENLER ---
var aktif = false
var cursor_pozisyon = 0.0
var yon = 1  # 1 = sağa, -1 = sola
var hiz = 150.0  # Başlangıç hızı (100 → 150)
var max_hiz = 500.0  # Maksimum hız (400 → 500)
var hizlanma = 300.0  # Hızlanma oranı

# Zone pozisyonları (0-1 arası)
var perfect_zone_merkez = 0.75  # %75'te perfect zone
var perfect_zone_genislik = 0.1  # %10 genişlik
var good_zone_genislik = 0.25  # %25 genişlik

var tamamlandi = false
var input_kilitli = true  # Başta kilitli

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func baslat():
	visible = true
	aktif = true
	tamamlandi = false
	input_kilitli = true  # Input başta kilitli
	cursor_pozisyon = 0.0
	yon = 1
	hiz = 100.0
	
	sonuc_label.text = ""
	
	# Zone'ları konumlandır
	zone_konumlandir()
	
	# Kısa bekleme - cursor hareket etsin
	await get_tree().create_timer(0.3).timeout
	input_kilitli = false  # Artık Z'ye basılabilir

func zone_konumlandir():
	var bar_genisligi = bar_bg.size.x
	
	# Perfect Zone (Sarı)
	perfect_zone.position.x = (perfect_zone_merkez - perfect_zone_genislik / 2) * bar_genisligi
	perfect_zone.size.x = perfect_zone_genislik * bar_genisligi
	perfect_zone.color = Color(1, 1, 0, 0.6)  # Sarı
	
	# Good Zone (Yeşil)
	good_zone.position.x = (perfect_zone_merkez - good_zone_genislik / 2) * bar_genisligi
	good_zone.size.x = good_zone_genislik * bar_genisligi
	good_zone.color = Color(0, 1, 0, 0.3)  # Yeşil

func _process(delta):
	if not visible or not aktif or tamamlandi:
		return
	
	# Cursor hareketi
	cursor_hareket(delta)
	
	# Z tuşu ile timing kontrol (sadece input kilidi açıksa)
	if not input_kilitli and Input.is_action_just_pressed("tus_z"):
		timing_kontrol()
		return

func cursor_hareket(delta):
	# Hızlanma (ortaya yaklaştıkça hızlanır)
	var orta_uzaklik = abs(cursor_pozisyon - 0.5)  # 0-0.5 arası
	var hiz_carpan = 1.0 + (1.0 - orta_uzaklik * 2) * 3  # Ortada 4x hızlı
	var suanki_hiz = hiz * hiz_carpan
	
	# Hareket
	cursor_pozisyon += yon * suanki_hiz * delta / bar_bg.size.x
	
	# Sınır kontrolü ve geri dönme
	if cursor_pozisyon >= 1.0:
		cursor_pozisyon = 1.0
		yon = -1
	elif cursor_pozisyon <= 0.0:
		cursor_pozisyon = 0.0
		yon = 1
	
	# Debug
	if int(Time.get_ticks_msec()) % 500 == 0:  # Her 500ms'de bir
		print("Cursor pozisyon: ", cursor_pozisyon)
	
	# Cursor pozisyonunu güncelle
	if cursor and bar_bg:
		cursor.position.x = cursor_pozisyon * bar_bg.size.x

func timing_kontrol():
	tamamlandi = true
	aktif = false
	
	# Hangi zone'da?
	var perfect_baslangic = perfect_zone_merkez - perfect_zone_genislik / 2
	var perfect_bitis = perfect_zone_merkez + perfect_zone_genislik / 2
	
	var good_baslangic = perfect_zone_merkez - good_zone_genislik / 2
	var good_bitis = perfect_zone_merkez + good_zone_genislik / 2
	
	var kalite = ""
	var carpan = 0.0
	
	if cursor_pozisyon >= perfect_baslangic and cursor_pozisyon <= perfect_bitis:
		# PERFECT!
		kalite = "PERFECT"
		carpan = 2.0
		sonuc_label.text = "PERFECT!"
		sonuc_label.modulate = Color(1, 1, 0)  # Sarı
		cursor.color = Color(1, 1, 0)
	elif cursor_pozisyon >= good_baslangic and cursor_pozisyon <= good_bitis:
		# GOOD
		kalite = "GOOD"
		carpan = 1.0
		sonuc_label.text = "GOOD"
		sonuc_label.modulate = Color(0, 1, 0)  # Yeşil
		cursor.color = Color(0, 1, 0)
	else:
		# MISS
		kalite = "MISS"
		carpan = 0.3  # Çok düşük hasar
		sonuc_label.text = "MISS..."
		sonuc_label.modulate = Color(1, 0, 0)  # Kırmızı
		cursor.color = Color(1, 0, 0)
	
	print("Timing: " + kalite + " (x" + str(carpan) + ")")
	
	# Sinyal gönder
	await get_tree().create_timer(0.5).timeout
	timing_tamamlandi.emit(kalite, carpan)
	
	# Kapat
	await get_tree().create_timer(1.0).timeout
	visible = false
