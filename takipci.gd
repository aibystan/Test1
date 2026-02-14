extends CharacterBody2D

@export var hedef: Node2D 

# --- AYARLAR ---
var hiz = 150            # Player hızıyla AYNI olsun
var iz_sikligi = 8       # Her 8 pikselde bir iz bırak
var takip_gecikmesi = 8  # Daha fazla mesafe bırak

var ayak_izleri = [] 
@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	# Başlangıçta hedefi bul (player)
	if hedef == null:
		hedef = get_parent().get_node_or_null("Player")

func _physics_process(_delta):
	if hedef == null: return
	
	# --- 1. AKILLI KAYIT SİSTEMİ ---
	var son_nokta = hedef.global_position
	if not ayak_izleri.is_empty():
		son_nokta = ayak_izleri.back()
		
	if hedef.global_position.distance_to(son_nokta) > iz_sikligi or ayak_izleri.is_empty():
		# Oyuncu gerçekten hareket ediyor mu?
		if hedef.velocity.length() > 10:
			ayak_izleri.append(hedef.global_position)
	
	# İz listesi çok uzarsa kısalt (optimizasyon)
	if ayak_izleri.size() > 50:
		ayak_izleri.pop_front()

	# --- 2. HAREKET SİSTEMİ ---
	if ayak_izleri.size() > takip_gecikmesi:
		var gidilecek_nokta = ayak_izleri[0]
		var yon = global_position.direction_to(gidilecek_nokta)
		var mesafe_hedefe = global_position.distance_to(gidilecek_nokta)
		
		velocity = yon * hiz
		move_and_slide()
		
		# Animasyonu oynat
		if velocity.length() > 10:
			animasyon_oynat(yon)
		
		# Noktaya vardıysak sil
		if mesafe_hedefe < 12:
			ayak_izleri.pop_front()
			
	else:
		# Dur
		velocity = Vector2.ZERO
		if anim_sprite.is_playing():
			anim_sprite.stop()
			anim_sprite.frame = 1  # Duruş karesi

	# --- 3. DERİNLİK AYARI (Y-SORT) ---
	# Takipçi player'ın arkasında kalmalı
	if hedef:
		# Y pozisyonuna göre z_index ayarla
		z_index = int(global_position.y)

func animasyon_oynat(yon):
	if abs(yon.x) > abs(yon.y): # Yatay hareket
		if yon.x > 0:
			anim_sprite.play("walk_right")
		else:
			anim_sprite.play("walk_left")
	else: # Dikey hareket
		if yon.y > 0:
			anim_sprite.play("walk_down")
		else:
			anim_sprite.play("walk_up")
