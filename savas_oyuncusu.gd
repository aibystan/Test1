extends Area2D

# --- GRID VE KONUM ---
var grid_x = 1 
var grid_y = 1 

# Node'ları güvenli bulmak için başta null yapıyoruz
var grid_container = null
var sprite = null

# --- DURUMLAR ---
var zipliyor = false
var egiliyor = false
var taban_y = 0.0 

# --- STATS ---
var hp = 100
var qut = 170
var gp = 0.0
var max_gp = 100.0
var is_grazing = false

# --- AYARLAR ---
var ziplama_gucu = 80.0
var ziplama_suresi = 0.5

func _ready():
	# 1. Sprite Kontrolü
	if has_node("Sprite2D"):
		sprite = $Sprite2D
	else:
		printerr("HATA: Sprite2D bulunamadı!")
	
	# 2. Grid Container'ı Bul (Bir üst düğüme soruyoruz)
	var parent = get_parent()
	if parent.has_node("GridKonumlari"):
		grid_container = parent.get_node("GridKonumlari")
		call_deferred("konum_guncelle", false)
	else:
		print("UYARI: GridKonumlari bulunamadı. SavasSahnesi.tscn'den başlatmalısın.")

func _process(delta):
	if grid_container == null or sprite == null: return # Hata varsa çalışma

	kontrol_et()
	gp_yonet(delta)

func kontrol_et():
	if zipliyor: return 
	
	var onceki_x = grid_x
	var onceki_y = grid_y
	
	# --- YATAY HAREKET (X EKSENİ) ---
	# DÜZELTME: Tuşların yönünü senin sahnene göre değiştirdik.
	
	# SAĞ TUŞU:
	# Eğer sağa basınca sola gidiyorsa, burada mantığı tersine çeviriyoruz.
	# Normalde x artmalıydı, ama senin kurulumunda azalması gerekiyor olabilir.
	# Aşağıdaki kodda: Sağa basınca x'i ARTIRIYORUZ (Standardı budur).
	# EĞER HALA TERS ÇALIŞIRSA: 'ui_right' ile 'ui_left' yazan yerleri yer değiştir.
	if Input.is_action_just_pressed("ui_right") and grid_x < 2:
		grid_x += 1
		sprite.flip_h = false 
	elif Input.is_action_just_pressed("ui_left") and grid_x > 0:
		grid_x -= 1
		sprite.flip_h = true 
	
	# --- DİKEY HAREKET (Y EKSENİ) ---
	# DÜZELTME: Bilgisayarda Y koordinatı aşağı doğru artar.
	# Bu yüzden "Yukarı" gitmek için Y'yi AZALTMALIYIZ (grid_y -= 1).
	
	if Input.is_action_just_pressed("ui_up") and grid_y > 0: 
		grid_y -= 1 # 0'a (Yukarıya) git
	elif Input.is_action_just_pressed("ui_down") and grid_y < 2: 
		grid_y += 1 # 2'ye (Aşağıya) git
		
	# Konum değiştiyse güncelle
	if onceki_x != grid_x or onceki_y != grid_y:
		konum_guncelle(true)

	# --- AKSİYONLAR ---
	if Input.is_action_just_pressed("tus_z") and not zipliyor and not egiliyor:
		zipla()
		
	if Input.is_action_pressed("tus_x"):
		egil(true)
	else:
		egil(false)

func konum_guncelle(animasyonlu: bool = false):
	var hedef_isim = "Pos_" + str(grid_y) + "_" + str(grid_x)
	
	if grid_container.has_node(hedef_isim):
		var hedef_node = grid_container.get_node(hedef_isim)
		var hedef_pos = hedef_node.position
		z_index = 10 - grid_y 
		
		if animasyonlu:
			var tween = create_tween()
			tween.tween_property(self, "position", hedef_pos, 0.1).set_trans(Tween.TRANS_SINE)
		else:
			position = hedef_pos

func zipla():
	zipliyor = true
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", -ziplama_gucu, ziplama_suresi / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0.0, ziplama_suresi / 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	zipliyor = false

func egil(durum):
	if egiliyor == durum: return
	egiliyor = durum
	if egiliyor:
		sprite.scale.y = 0.6
		sprite.position.y = 15
	else:
		sprite.scale.y = 1.0
		sprite.position.y = 0

func gp_yonet(delta):
	if is_grazing: gp += delta * 15.0
	else: gp += delta * 2.0
	if gp > max_gp: gp = max_gp

func hasar_al(miktar):
	hp -= miktar
	gp = 0.0

# Mermiler bu fonksiyonu çağırıp hasar verip veremeyeceğini soracak
# mermi_katmani -> 0: Alt, 1: Orta, 2: Üst
func darbe_alir_mi(mermi_katmani: int) -> bool:
	# -- GRAZE (SIYIRMA) KONTROLÜ --
	# Mermi içimizden geçerken bu fonksiyon sürekli çağrılırsa Graze puanı artar
	is_grazing = true 
	
	# -- ÇARPIŞMA MANTIĞI --
	match mermi_katmani:
		0: # ALT TABAKA (Yerden giden)
			if zipliyor:
				return false # Zıpladık, altımızdan geçti (ISKA)
			else:
				return true # Yerdeyiz (veya eğiliyoruz), ayağımıza çarptı (HASAR)
		
		1: # ORTA TABAKA (Gövdeden giden)
			if egiliyor:
				return false # Eğildik, üstümüzden geçti (ISKA) - Senin kuralın
			elif zipliyor:
				return false # Zıpladık, altımızdan geçti (ISKA)
			else:
				return true # Ayaktayız, göğsümüze çarptı (HASAR)
		
		2: # ÜST TABAKA (Havadan giden)
			if zipliyor:
				return true # Zıpladık, tam kafamıza çarptı (HASAR)
			else:
				return false # Yerdeyiz (Ayakta veya Eğik), kafamızın üstünden geçti (ISKA)
	
	return false

# Mermi Area'dan çıkınca Graze biter
func graze_bitti():
	is_grazing = false
