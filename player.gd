extends CharacterBody2D

const SPEED = 150.0
@onready var anim = $AnimatedSprite2D
@onready var etkilesim_isini = $RayCast2D
var etkilesim_yasakli = false

func _physics_process(delta):
	# --- SAHNE GEÇİŞİ KONTROLÜ ---
	if Gecis.gecis_yapiliyor:
		velocity = Vector2.ZERO 
		$AnimatedSprite2D.stop() 
		move_and_slide()
		return 

	# --- HAREKET ---
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * SPEED
		anim.play()
		# Işını karaktere göre döndür
		etkilesim_isini.target_position = direction * 30 
	else:
		velocity = Vector2.ZERO
		anim.stop()
		anim.frame = 1

	# --- ANİMASYON YÖNÜ ---
	if direction.x > 0:
		anim.animation = "walk_right"
	elif direction.x < 0:
		anim.animation = "walk_left"
	elif direction.y > 0:
		anim.animation = "walk_down"
	elif direction.y < 0:
		anim.animation = "walk_up"

	move_and_slide()
	
	# --- ETKİLEŞİM (Z TUŞU) ---
	# Player sadece Z'ye basıldığını haber verir, gerisine karışmaz.
	if Input.is_action_just_pressed("tus_z") and not etkilesim_yasakli:
		etkilesim_kontrol()

func _ready():
	# (DİKKAT: DiyalogKutusu bağlantılarını buradan SİLDİK. 
	# Çünkü o artık Player'ın içinde değil.)
	
	if Global.gidilecek_kapi_ismi != "":
		var hedef_kapi = get_parent().find_child(Global.gidilecek_kapi_ismi)
		if hedef_kapi:
			var spawn_noktasi = hedef_kapi.get_node_or_null("SpawnNoktasi")
			if spawn_noktasi:
				global_position = spawn_noktasi.global_position
	
	if Global.yuklenen_pozisyon != null:
		global_position = Global.yuklenen_pozisyon
		Global.yuklenen_pozisyon = null 
	
	# --- TAKİPÇİ AYARLARI ---
	var takipci = get_node_or_null("Takipci")
	if takipci:
		takipci.ayak_izleri.clear()
		takipci.global_position = global_position + Vector2(0, 20)

func etkilesim_kontrol():
	if etkilesim_isini.is_colliding():
		var degilen_nesne = etkilesim_isini.get_collider()
		
		# Eğer dokunduğumuz şeyin "etkilesime_gec" diye bir fonksiyonu varsa çalıştır.
		# (Tabela, Sandık veya Tüccar olması fark etmez)
		if degilen_nesne.has_method("etkilesime_gec"):
			degilen_nesne.etkilesime_gec()
			
			# Ufak bir bekleme koyalım ki Z'ye basılı tutup hata yapmayalım
			_on_diyalog_bitti()

func _on_diyalog_bitti():
	# Diyalog kapandı ama parmağımız hala Z'de olabilir.
	# Hemen yeni etkileşim başlatma, biraz bekle.
	etkilesim_yasakli = true 
	await get_tree().create_timer(0.2).timeout 
	etkilesim_yasakli = false
