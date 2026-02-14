extends CharacterBody2D

@export var hedef: Node2D 

# --- AYARLAR ---
var hiz = 150            # Player hızıyla AYNI olsun
var iz_sikligi = 12      # Daha seyrek iz - titreme azalır
var takip_gecikmesi = 3 # Daha fazla mesafe
var minimum_hareket_mesafesi = 8  # Bu mesafeden azsa hareket etme

var ayak_izleri = [] 
var son_animasyon = ""  # Son oynatılan animasyonu hatırla
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
		
		# Animasyonu oynat (sadece gerçekten hareket varsa)
		if velocity.length() > 20:
			animasyon_oynat(yon)
		
		# Hedefe vardıysa noktayı sil
		if mesafe_hedefe < 8:
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
