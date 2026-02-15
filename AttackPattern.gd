extends Node
class_name AttackPattern

# Pattern türleri
enum PatternType {
	BASIT_DALGALI,    # Basit: 3 mermi dalga dalga
	IZGARA,           # Orta: Grid şeklinde
	SPIRAL,           # Zor: Spiral pattern
	RANDOM_SPAM,      # Basit: Rastgele spam
	BOSS_LAZER        # Boss: Özel pattern
}

# Pattern parametreleri
var pattern_type: PatternType = PatternType.BASIT_DALGALI
var mermi_sahnesi = preload("res://mermi.tscn")
var parent_node: Node2D
var grid_node: Node2D

func _init(type: PatternType, parent: Node2D, grid: Node2D):
	pattern_type = type
	parent_node = parent
	grid_node = grid

# Pattern çalıştır
func calistir():
	match pattern_type:
		PatternType.BASIT_DALGALI:
			await basit_dalgali_pattern()
		PatternType.IZGARA:
			await izgara_pattern()
		PatternType.SPIRAL:
			await spiral_pattern()
		PatternType.RANDOM_SPAM:
			await random_spam_pattern()
		PatternType.BOSS_LAZER:
			await boss_lazer_pattern()

# ====== PATTERN TANIMLAMALARI ======

# 1. BASIT DALGALI - 3 mermi, 3 katman, birer birer
func basit_dalgali_pattern():
	print("Pattern: Basit Dalgalı")
	
	for satir in range(3):  # 3 satır (0, 1, 2)
		for katman in range(3):  # 3 katman (Alt, Orta, Üst)
			mermi_spawn(satir, katman, 250.0)
			await parent_node.get_tree().create_timer(0.3).timeout
	
	# Pattern bitmesi için bekle
	await parent_node.get_tree().create_timer(2.0).timeout

# 2. IZGARA - Tüm grid'e mermi yağmuru
func izgara_pattern():
	print("Pattern: Izgara")
	
	# Tüm satırlara aynı anda
	for satir in range(3):
		var katman = randi() % 3  # Rastgele katman
		mermi_spawn(satir, katman, 200.0)
	
	await parent_node.get_tree().create_timer(0.5).timeout
	
	# İkinci dalga
	for satir in range(3):
		var katman = (satir + 1) % 3  # Farklı katmanlar
		mermi_spawn(satir, katman, 200.0)
	
	await parent_node.get_tree().create_timer(2.5).timeout

# 3. SPIRAL - Dönen pattern (gelecekte)
func spiral_pattern():
	print("Pattern: Spiral (Placeholder)")
	
	for i in range(8):
		var satir = i % 3
		var katman = (i / 3) as int % 3
		mermi_spawn(satir, katman, 220.0)
		await parent_node.get_tree().create_timer(0.2).timeout
	
	await parent_node.get_tree().create_timer(2.0).timeout

# 4. RANDOM SPAM - Rastgele mermiler
func random_spam_pattern():
	print("Pattern: Random Spam")
	
	for i in range(10):
		var satir = randi() % 3
		var katman = randi() % 3
		var hiz = randf_range(180.0, 280.0)
		mermi_spawn(satir, katman, hiz)
		await parent_node.get_tree().create_timer(0.15).timeout
	
	await parent_node.get_tree().create_timer(2.0).timeout

# 5. BOSS LAZER (Gelecekte genişletilecek)
func boss_lazer_pattern():
	print("Pattern: Boss Lazer (Placeholder)")
	
	# Tüm katmanlar aynı anda
	for satir in range(3):
		for katman in range(3):
			mermi_spawn(satir, katman, 300.0)
	
	await parent_node.get_tree().create_timer(3.0).timeout

# ====== YARDIMCI FONKSİYONLAR ======

func mermi_spawn(satir: int, katman: int, hiz: float):
	if not grid_node:
		print("Grid node bulunamadı!")
		return
	
	var mermi = mermi_sahnesi.instantiate()
	
	# Grid pozisyonunu bul
	var baslangic_node_ismi = "Pos_" + str(satir) + "_3"  # En sağdaki sütun (3)
	
	if not grid_node.has_node(baslangic_node_ismi):
		# 4x4 değilse 3x3 (eski sistem)
		baslangic_node_ismi = "Pos_" + str(satir) + "_2"
	
	if grid_node.has_node(baslangic_node_ismi):
		var baslangic_node = grid_node.get_node(baslangic_node_ismi)
		
		# Mermiyi sağda spawn et
		mermi.position = Vector2(baslangic_node.position.x + 400, baslangic_node.position.y)
		mermi.katman = katman
		mermi.hiz = hiz
		mermi.z_index = 10 - satir  # Derinlik
		
		parent_node.add_child(mermi)
		
		print("Mermi spawn: Satır " + str(satir) + " Katman " + str(katman))
	else:
		print("Grid pozisyonu bulunamadı: " + baslangic_node_ismi)
