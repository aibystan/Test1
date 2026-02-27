extends CharacterBody2D

# --- DÜŞMAN AYARLARI ---
@export var baslangic_hizi: float = 50.0
@export var maksimum_hiz: float = 200.0
@export var hizlanma_orani: float = 20.0
@export var gorme_mesafesi: float = 150.0

# --- SAVAŞ AYARLARI ---
@export var dusman_listesi: Array[EnemyData] = []

# --- DEĞİŞKENLER ---
var player: CharacterBody2D = null
var takip_ediyor = false
var mevcut_hiz = 0.0
var savaş_basladi = false
var yenildi = false
var unique_id: String = ""

@onready var sprite = $Sprite2D
@onready var gorme_alani = $GormeAlani
@onready var carpisma_alani = $CarpismaAlani

func _ready():
	mevcut_hiz = baslangic_hizi
	
	# Node ismini ID olarak kullan (sahnede her node ismi benzersizdir)
	unique_id = name
	
	# Kaydedilmiş pozisyon varsa uygula
	if Global.enemy_positions.has(unique_id):
		await get_tree().process_frame
		global_position = Global.enemy_positions[unique_id]
		Global.enemy_positions.erase(unique_id)
	
	# Bu düşman öldürüldü mü kontrol et
	if Global.defeated_enemies.has(unique_id):
		yenildi = true
		await kaybol_animasyonu()
		return
	
	# Görme alanı boyutunu ayarla
	if gorme_alani and gorme_alani.has_node("CollisionShape2D"):
		var collision = gorme_alani.get_node("CollisionShape2D")
		if collision.shape is CircleShape2D:
			collision.shape.radius = gorme_mesafesi
	
	# Sinyal bağlantıları
	if gorme_alani:
		gorme_alani.body_entered.connect(_on_gorme_alani_body_entered)
		gorme_alani.body_exited.connect(_on_gorme_alani_body_exited)
	
	if carpisma_alani:
		carpisma_alani.body_entered.connect(_on_carpisma_alani_body_entered)

func _physics_process(delta):
	if savaş_basladi or yenildi:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if takip_ediyor and player:
		var yon = (player.global_position - global_position).normalized()
		mevcut_hiz = min(mevcut_hiz + hizlanma_orani * delta, maksimum_hiz)
		velocity = yon * mevcut_hiz
	else:
		velocity = Vector2.ZERO
		mevcut_hiz = baslangic_hizi
	
	move_and_slide()

func _on_gorme_alani_body_entered(body):
	if body.name == "Player" and not savaş_basladi and not yenildi:
		player = body
		takip_ediyor = true

func _on_gorme_alani_body_exited(body):
	if body.name == "Player":
		takip_ediyor = false
		player = null

func _on_carpisma_alani_body_entered(body):
	if body.name == "Player" and not savaş_basladi and not yenildi:
		savas_basla()

func savas_basla():
	if savaş_basladi or yenildi:
		return
	
	savaş_basladi = true
	takip_ediyor = false
	velocity = Vector2.ZERO
	# Oyuncuyu durdur
	if player:
		player.velocity = Vector2.ZERO
		player.set_physics_process(false)
	
	if dusman_listesi.size() > 0:
		# Mevcut sahneyi ve oyuncu pozisyonunu kaydet
		Global.set_meta("battle_return_scene", get_tree().current_scene.scene_file_path)
		if player:
			Global.set_meta("battle_return_position", player.global_position)
		
		# Düşman ID ve mevcut pozisyonunu kaydet
		Global.set_meta("current_enemy_id", unique_id)
		Global.enemy_positions[unique_id] = global_position
		
		# Düşman listesini kaydet
		Global.set_meta("battle_enemies", dusman_listesi)
		
		# Encounter efektini oynat, sonra savaş sahnesine geç
		var efekt = load("res://encounter_efekti.tscn").instantiate()
		get_tree().current_scene.add_child(efekt)
		efekt.oynat("res://savas_sahnesi.tscn")
	else:
		print("HATA: Düşman listesi boş!")
		savaş_basladi = false

func kaybol_animasyonu():
	for i in range(6):
		visible = false
		await get_tree().create_timer(0.1).timeout
		visible = true
		await get_tree().create_timer(0.1).timeout
	visible = false
	yenildi = true
	set_physics_process(false)
