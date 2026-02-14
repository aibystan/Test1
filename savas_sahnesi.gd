extends Node2D

# SavasSahnesi.gd içine ekle

var mermi_sahnesi = preload("res://mermi.tscn") # mermi.tscn dosyan olduğundan emin ol

func _process(delta):
	# TEST: 'M' tuşuna basınca orta sıraya mermi at
	if Input.is_action_just_pressed("tus_m"): # Input Map'ten ekle veya ui_accept kullan
		test_mermi_at()

# savas_sahnesi.gd

func test_mermi_at():
	var mermi = mermi_sahnesi.instantiate()
	add_child(mermi)
	
	# 1. Rastgele bir hedef satır seç (0: Ön, 1: Orta, 2: Arka)
	var hedef_satir = randi() % 3
	
	# 2. O satırın en sağındaki kutuyu (Sütun 2) bul referans al
	# İsimlendirmene dikkat et: "Pos_Satir_Sutun" -> "Pos_" + str(hedef_satir) + "_2"
	var baslangic_node_ismi = "Pos_" + str(hedef_satir) + "_2"
	var baslangic_node = $GridKonumlari.get_node(baslangic_node_ismi)
	
	# 3. Merminin Yüksekliği (Y) o satırla aynı olsun
	# X'i ise ekranın biraz daha sağında olsun (örneğin node'un +500 sağında)
	mermi.position = Vector2(baslangic_node.position.x + 500, baslangic_node.position.y)
	
	# 4. Mermi Katmanını ve Rengini Seç
	mermi.katman = randi() % 3 # 0: Alt, 1: Orta, 2: Üst
	mermi.renk_ayarla()
	
	# 5. Görsel Derinlik (Z-Index)
	# Mermi, hedeflediği satırla aynı derinlikte olmalı ki
	# Arkadaki karakterin önünden geçerken arkada kalsın.
	mermi.z_index = 10 - hedef_satir 
	
	print("Mermi Geliyor! Hedef Satır: " + str(hedef_satir) + " | Tip: " + str(mermi.katman))
