extends CharacterBody2D

@export var hedef_ismi: String = "Player"  # Hedefin ismini belirt

# --- AYARLAR ---
var hiz = 150
var iz_sikligi = 4
var takip_gecikmesi = 8
var minimum_hareket_mesafesi = 3

var hedef: Node2D = null  # Takip edilecek hedef
var ayak_izleri = [] 
var son_animasyon = ""
@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	print("=== TAKİPÇİ BAŞLATILIYOR ===")
	print("Aranan hedef ismi: ", hedef_ismi)
	
	# Scene tree'den hedefi bul - birkaç yöntem dene
	await get_tree().process_frame
	
	# Yöntem 1: find_child
	hedef = get_tree().current_scene.find_child(hedef_ismi)
	
	if not hedef:
		print("find_child başarısız, get_node deniyor...")
		# Yöntem 2: get_node
		hedef = get_tree().current_scene.get_node_or_null(hedef_ismi)
	
	if not hedef:
		print("get_node başarısız, tüm child'ları arıyorum...")
		# Yöntem 3: Tüm child'ları tara
		for child in get_tree().current_scene.get_children():
			print("  Bulunan node: ", child.name)
			if child.name == hedef_ismi:
				hedef = child
				break
	
	if hedef:
		print("✓ Takipçi hedefi buldu: ", hedef.name)
		print("  Hedef pozisyonu: ", hedef.global_position)
		# İlk pozisyonu ayarla
		global_position = hedef.global_position
		print("  Takipçi pozisyonu ayarlandı: ", global_position)
	else:
		print("✗ HATA: Takipçi '", hedef_ismi, "' isimli hedefi bulamadı!")
		print("  Lütfen hedef isminin doğru olduğundan emin ol")
	
	# Aktiflik durumunu kontrol et
	guncelle_gorunurluk()
	
	# Global sinyaline bağlan
	Global.takipci_durumu_degisti.connect(_on_takipci_durumu_degisti)

func guncelle_gorunurluk():
	# Global flag'e göre görünürlük ve physics'i ayarla
	if Global.takipci_aktif:
		visible = true
		set_physics_process(true)
	else:
		visible = false
		set_physics_process(false)
		ayak_izleri.clear()

func _physics_process(_delta):
	if hedef == null: 
		return
	
	# --- 1. AKILLI KAYIT SİSTEMİ ---
	var son_nokta = hedef.global_position
	if not ayak_izleri.is_empty():
		son_nokta = ayak_izleri.back()
		
	# Sadece yeterince uzaklaştıysa kaydet
	if hedef.global_position.distance_to(son_nokta) > iz_sikligi or ayak_izleri.is_empty():
		if hedef.velocity.length() > 10:
			ayak_izleri.append(hedef.global_position)
	
	# İz listesi çok uzarsa kısalt
	if ayak_izleri.size() > 50:
		ayak_izleri.pop_front()

	# --- 2. HAREKET SİSTEMİ ---
	if ayak_izleri.size() > takip_gecikmesi:
		var gidilecek_nokta = ayak_izleri[0]
		var mesafe_hedefe = global_position.distance_to(gidilecek_nokta)
		
		# Çok yakınsa noktayı sil ve bir sonrakine geç
		if mesafe_hedefe < minimum_hareket_mesafesi:
			ayak_izleri.pop_front()
			if ayak_izleri.is_empty():
				velocity = Vector2.ZERO
				if anim_sprite.is_playing():
					anim_sprite.stop()
					anim_sprite.frame = 1
				return
			gidilecek_nokta = ayak_izleri[0]
			mesafe_hedefe = global_position.distance_to(gidilecek_nokta)
		
		# Normal hareket
		var yon = global_position.direction_to(gidilecek_nokta)
		velocity = yon * hiz
		move_and_slide()
		
		# Animasyonu oynat
		if velocity.length() > 10:
			animasyon_oynat(yon)
		
		# Hedefe çok yaklaştıysa noktayı sil
		if mesafe_hedefe < minimum_hareket_mesafesi * 1.5:
			ayak_izleri.pop_front()
			
	else:
		# Dur
		velocity = Vector2.ZERO
		if anim_sprite.is_playing():
			anim_sprite.stop()
			anim_sprite.frame = 1
		son_animasyon = ""

	# --- 3. DERİNLİK AYARI (Y-SORT) ---
	if hedef:
		z_index = int(global_position.y)

func animasyon_oynat(yon):
	var yeni_animasyon = ""
	
	# Hangi animasyon oynatılacak?
	if abs(yon.x) > abs(yon.y):
		# Yatay hareket dominant
		if yon.x > 0:
			yeni_animasyon = "walk_right"
		else:
			yeni_animasyon = "walk_left"
	else:
		# Dikey hareket dominant
		if yon.y > 0:
			yeni_animasyon = "walk_down"
		else:
			yeni_animasyon = "walk_up"
	
	# Sadece animasyon değiştiyse yeni animasyonu başlat
	if yeni_animasyon != son_animasyon:
		anim_sprite.play(yeni_animasyon)
		son_animasyon = yeni_animasyon

func _on_takipci_durumu_degisti(aktif: bool):
	if aktif:
		# Oyuncunun yanında yeniden belir
		if hedef:
			ayak_izleri.clear()
			global_position = hedef.global_position
			velocity = Vector2.ZERO
	guncelle_gorunurluk()

func reset_pozisyon(yeni_pozisyon: Vector2):
	ayak_izleri.clear()
	global_position = yeni_pozisyon
	velocity = Vector2.ZERO
	if anim_sprite.is_playing():
		anim_sprite.stop()
		anim_sprite.frame = 1
	
	# Physics'i geçici kapat
	set_physics_process(false)
	await get_tree().create_timer(0.5).timeout
	
	# Sadece aktifse physics'i aç
	if Global.takipci_aktif:
		set_physics_process(true)
	
	# Görünürlüğü güncelle
	guncelle_gorunurluk()
