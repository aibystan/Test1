extends Area2D

# Merminin özellikleri
var hiz = 300.0 # Ne kadar hızlı gidiyor
var katman = 0 # 0: Alt, 1: Orta, 2: Üst (Bunu düşman belirleyecek)
var yon = Vector2.LEFT # Sola doğru (Düşmandan bize)

func _ready():
	# Oyuncuya çarpma sinyalini bağla
	# Godot 4'te "area_entered" sinyali kullanılır
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	# Renk kodlaması (İstersen açabilirsin, katmana göre renk değişir)
	renk_ayarla()

func _process(delta):
	# Mermiyi hareket ettir
	position += yon * hiz * delta
	
	# Ekrandan çok uzaklaşırsa sil (Performans için)
	if position.x < -100 or position.x > 1500:
		queue_free()

func renk_ayarla():
	# Görsel hata ayıklama için:
	if katman == 0: modulate = Color.RED # Alt (Zıpla)
	elif katman == 1: modulate = Color.ORANGE # Orta (Eğil)
	elif katman == 2: modulate = Color.CYAN # Üst (Dur)

func _on_area_entered(area):
	# Çarptığımız şey oyuncu mu?
	if area.name == "SavasOyuncusu":
		# EKSİKLİK GİDERME: Satır Kontrolü
		# Merminin Y koordinatı ile Oyuncunun Y koordinatı çok farklıysa (başka sıradaysa) vurma.
		# 30 piksel tolerans tanıyalım.
		if abs(position.y - area.position.y) > 30:
			return # Mermi başka sıradan geçiyor, oyuncuya değmez.
		if area.has_method("darbe_alir_mi"):
			var hasar_var_mi = area.darbe_alir_mi(katman)
			
			if hasar_var_mi:
				print("VURULDUK! Katman: " + str(katman))
				area.hasar_al(10) # 10 can düş
				queue_free() # Mermi yok olsun
			else:
				print("ISKA! Başarılı manevra.")
				# Mermi yok olmuyor, içimizden geçip gidiyor (Graze için)

func _on_area_exited(area):
	if area.name == "SavasOyuncusu":
		# Mermi içimizden çıktı, graze bitti
		if area.has_method("graze_bitti"):
			area.graze_bitti()
