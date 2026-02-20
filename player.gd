extends CharacterBody2D

const SPEED = 150.0
@onready var anim = $AnimatedSprite2D
@onready var etkilesim_isini = $RayCast2D
var etkilesim_yasakli = false
var son_etkilesim_zamani = 0.0

func _physics_process(delta):
	# --- SAHNE GEÇİŞİ KONTROLÜ ---
	if Gecis.gecis_yapiliyor:
		velocity = Vector2.ZERO 
		$AnimatedSprite2D.stop() 
		move_and_slide()
		return 

	# --- DİYALOG KONTROLÜ - HAREKET KİLİTLE ---
	var diyalog_kutusu = get_tree().current_scene.find_child("DiyalogKutusu")
	var diyalog_acik = diyalog_kutusu and diyalog_kutusu.visible
	
	if diyalog_acik:
		# Diyalog açıkken hareket etme
		velocity = Vector2.ZERO
		anim.stop()
		anim.frame = 1
		move_and_slide()
		return

	# --- HAREKET ---
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction:
		velocity = direction * SPEED
		anim.play()
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
	
	# --- DERİNLİK AYARI (Y-SORT) ---
	z_index = int(global_position.y)
	
	# --- ETKİLEŞİM KİLİT YÖNETİMİ ---
	if diyalog_acik:
		etkilesim_yasakli = true
	else:
		# Diyalog kapalı - son etkileşimden 0.5 saniye geçtiyse kilidi aç
		if Time.get_ticks_msec() - son_etkilesim_zamani > 500:
			etkilesim_yasakli = false
	
	# --- ETKİLEŞİM (Z TUŞU) ---
	if Input.is_action_just_pressed("tus_z") and not etkilesim_yasakli and not get_tree().paused:
		etkilesim_kontrol()

func _ready():
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
	var takipci = get_parent().get_node_or_null("Takipci")
	if takipci:
		takipci.ayak_izleri.clear()
		takipci.global_position = global_position + Vector2(0, 32)
		takipci.hedef = self

func etkilesim_kontrol():
	if etkilesim_isini.is_colliding():
		var degilen_nesne = etkilesim_isini.get_collider()
		
		if degilen_nesne.has_method("etkilesime_gec"):
			# Etkileşim zamanını kaydet
			son_etkilesim_zamani = Time.get_ticks_msec()
			etkilesim_yasakli = true
			
			# Etkileşime geç
			degilen_nesne.etkilesime_gec()
