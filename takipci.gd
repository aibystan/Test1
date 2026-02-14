extends CharacterBody2D

@export var hedef: Node2D 

# --- AYARLAR ---
var hiz = 150            # Player hızıyla AYNI olsun
var iz_sikligi = 5      # (ARTTIRDIK) Her 10 pikselde bir iz bırak. Bu, duvarda yığılmayı önler.
var takip_gecikmesi = 5 # Tampon bölge boyutu

var ayak_izleri = [] 
@onready var anim_sprite = $AnimatedSprite2D

func _physics_process(_delta):
	if hedef == null: return
	
	# --- 1. AKILLI KAYIT SİSTEMİ ---
	# Hıza bakmıyoruz! Son bıraktığımız izden gerçekten uzaklaştı mı diye bakıyoruz.
	# Eğer liste boşsa VEYA oyuncunun şu anki konumu son izden 'iz_sikligi' kadar uzaktaysa kaydet.
	var son_nokta = hedef.global_position
	if not ayak_izleri.is_empty():
		son_nokta = ayak_izleri.back()
		
	if hedef.global_position.distance_to(son_nokta) > iz_sikligi or ayak_izleri.is_empty():
		# Buraya ekstra bir kontrol: Oyuncu gerçekten hareket ediyor mu?
		# Bu, dururken titremeleri tamamen keser.
		if hedef.velocity.length() > 10:
			ayak_izleri.append(hedef.global_position)

	# --- 2. HAREKET SİSTEMİ ---
	# Tampon bölge dolduysa harekete başla
	if ayak_izleri.size() > takip_gecikmesi:
		var gidilecek_nokta = ayak_izleri[0]
		var yon = global_position.direction_to(gidilecek_nokta)
		var mesafe_hedefe = global_position.distance_to(gidilecek_nokta)
		
		velocity = yon * hiz
		move_and_slide()
		
		# Animasyonu oynat
		if velocity.length() > 10: # Sadece gerçekten hareket ediyorsa oynat
			animasyon_oynat(yon)
		
		# Noktaya vardıysak sil (Hıza göre biraz toleranslı davranalım)
		if mesafe_hedefe < 10:
			ayak_izleri.pop_front()
			
	else:
		# Tampon sınırına geldik, dur.
		velocity = Vector2.ZERO
		anim_sprite.stop()
		# Duruş karesi (Opsiyonel)
		# if anim_sprite.animation == "sag_yuru": anim_sprite.frame = 0

	# --- 3. DERİNLİK AYARI ---
	if global_position.y < hedef.global_position.y - 5: # -5 tolerans ekledik
		z_index = -1
	else:
		z_index = 0

func animasyon_oynat(yon):
	if abs(yon.x) > abs(yon.y): # Yatay hareket
		anim_sprite.play("sag_yuru") 
		anim_sprite.flip_h = (yon.x < 0)
	else: # Dikey hareket
		if yon.y > 0:
			anim_sprite.play("asagi_yuru")
		else:
			anim_sprite.play("yukari_yuru")
