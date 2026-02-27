extends Area2D

# --- GRID VE KONUM ---
var grid_x = 1 
var grid_y = 1 

var grid_container = null
var sprite = null

# --- DURUMLAR ---
var zipliyor = false
var egiliyor = false

# --- ZIPLAMA FİZİĞİ (Mario tarzı) ---
const ZIPLAMA_HIZI     = 320.0   # Başlangıç yukarı hızı
const YERCEKIM         = 600.0   # Normal yerçekimi
const HIZLI_YERCEKIM   = 2500.0  # Z bırakılınca / X basılınca
const MAX_YUKSEKLIK    = 90.0    # Sprite'ın çıkabileceği max offset

var _sprite_vel_y = 0.0          # Sprite'ın dikey hızı (px/s)
var _z_basili = false

# --- STATS ---
var hp = 100
var qut = 170
var max_gp = 100.0
var is_grazing = false
var aktif_karakter_index: int = 0  # battle_manager tarafından set edilir

func _ready():
	if has_node("Sprite2D"):
		sprite = $Sprite2D
	else:
		printerr("HATA: Sprite2D bulunamadı!")
	var parent = get_parent()
	if parent.has_node("GridKonumlari"):
		grid_container = parent.get_node("GridKonumlari")
		call_deferred("konum_guncelle", false)

func _process(delta):
	if grid_container == null or sprite == null: return
	kontrol_et(delta)
	gp_yonet(delta)

func kontrol_et(delta):
	# --- YATAY / GRID HAREKETİ ---
	if not zipliyor:
		var ox = grid_x; var oy = grid_y
		if Input.is_action_just_pressed("ui_right") and grid_x < 3:
			grid_x += 1; sprite.flip_h = false
		elif Input.is_action_just_pressed("ui_left") and grid_x > 0:
			grid_x -= 1; sprite.flip_h = true
		if Input.is_action_just_pressed("ui_up") and grid_y > 0:
			grid_y -= 1
		elif Input.is_action_just_pressed("ui_down") and grid_y < 3:
			grid_y += 1
		if ox != grid_x or oy != grid_y:
			konum_guncelle(true)
		egil(Input.is_action_pressed("tus_x"))

	# --- ZIPLAMA BAŞLANGICI ---
	if Input.is_action_just_pressed("tus_z") and not zipliyor and not egiliyor:
		zipliyor = true
		_sprite_vel_y = -ZIPLAMA_HIZI
		_z_basili = true

	if Input.is_action_just_released("tus_z"):
		_z_basili = false

	# --- HAVADA FİZİK ---
	if zipliyor:
		# Z bırakıldıysa veya X basılıysa hızlı yerçekimi
		var yc = YERCEKIM
		if not _z_basili or Input.is_action_pressed("tus_x"):
			yc = HIZLI_YERCEKIM

		_sprite_vel_y += yc * delta
		sprite.position.y += _sprite_vel_y * delta

		# Yere değdi mi?
		if sprite.position.y >= 0.0:
			sprite.position.y = 0.0
			_sprite_vel_y = 0.0
			zipliyor = false
			_z_basili = false

		# Max yükseklik sınırı
		if sprite.position.y < -MAX_YUKSEKLIK:
			sprite.position.y = -MAX_YUKSEKLIK
			_sprite_vel_y = 0.0

func konum_guncelle(animasyonlu: bool = false):
	var hedef_isim = "Pos_" + str(grid_y) + "_" + str(grid_x)
	if grid_container.has_node(hedef_isim):
		var hedef_pos = grid_container.get_node(hedef_isim).position
		z_index = 10 - grid_y
		if animasyonlu:
			create_tween().tween_property(self, "position", hedef_pos, 0.1).set_trans(Tween.TRANS_SINE)
		else:
			position = hedef_pos

func egil(durum):
	if egiliyor == durum: return
	egiliyor = durum
	if egiliyor:
		sprite.scale.y = 0.6
		sprite.position.y = 15
	else:
		sprite.scale.y = 1.0
		sprite.position.y = 0.0

func gp_yonet(delta):
	# Tüm karakterlerin GP'sini saniyede %1 artır
	for k in Global.party_data:
		if not k.get("baygin", false):
			k["gp"] = min(k["gp"] + delta * 1.0, max_gp)

func hasar_al(miktar):
	hp -= miktar
	# GP global.gd parti_hasar_al içinde sıfırlanıyor

func darbe_alir_mi(mermi_katmani: int) -> bool:
	is_grazing = true
	match mermi_katmani:
		0: return not zipliyor
		1: return not egiliyor and not zipliyor
		2: return zipliyor
	return false

func graze_bitti():
	is_grazing = false
