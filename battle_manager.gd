extends Node
class_name BattleManager

# --- SİNYALLER ---
signal turn_basladi(karakter_index: int)
signal turn_bitti
signal dusman_turn_basladi
signal savas_bitti(kazanildi: bool)

# --- REFERANSLAR ---
var battle_ui  # Type hint kaldırıldı - CanvasLayer olabilir
var grid_node: Node2D
var player_node: Area2D
var timing_bar: Control
var message_box: Control  # Mesaj kutusu referansı

# --- DÜŞMANLAR ---
var dusmanlar: Array = []  # {data: EnemyData, node: Node2D}
var aktif_dusman_sayisi: int = 0

# --- TURN SİSTEMİ ---
enum TurnDurumu {PLAYER_1, PLAYER_2, DUSMAN, BEKLEME}
var suanki_durum: TurnDurumu = TurnDurumu.BEKLEME
var aktif_karakter_index: int = 0

# Turn fazları
enum TurnFazi {MENU, GRID}
var suanki_faz: TurnFazi = TurnFazi.MENU

# --- PLAYER DATA ---
var player_characters: Array = []  # Global.party_data'dan

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func savas_baslat(dusman_listesi: Array):
	print("Savaş Başladı!")
	
	# Player karakterleri yükle
	player_characters = Global.party_data.duplicate(true)
	
	# Grid'i başta kapat
	if player_node:
		player_node.process_mode = Node.PROCESS_MODE_DISABLED
		player_node.visible = false
	
	# Düşmanları spawn et
	dusmanlar.clear()
	for i in range(dusman_listesi.size()):
		var dusman_data = dusman_listesi[i]
		var dusman_dict = {
			"data": dusman_data.duplicate(),
			"node": spawn_dusman(dusman_data, i)
		}
		dusmanlar.append(dusman_dict)
	
	aktif_dusman_sayisi = dusmanlar.size()
	
	# İlk turn'ü başlat
	await get_tree().create_timer(0.5).timeout
	ilk_player_turn_basla()

func spawn_dusman(dusman: EnemyData, index: int):
	# Düşman sayısına göre pozisyon hesapla
	# Ekran: 640x360, metin kutusu üstte ~90px, alt panel ~90px
	# Düşmanlar: metin kutusunun hemen altında, ortalanmış
	var toplam_dusman = dusmanlar.size() + 1
	var ekran_merkez_x = 320  # 640 / 2
	
	var dusman_genislik = 80
	var bosluk = 20
	var toplam_genislik = toplam_dusman * (dusman_genislik + bosluk) - bosluk
	var baslangic_x = ekran_merkez_x - (toplam_genislik / 2)
	
	var dusman_x = baslangic_x + index * (dusman_genislik + bosluk)
	var dusman_y = 130  # Metin kutusunun altında
	
	# Düşman container
	var dusman_container = Node2D.new()
	dusman_container.position = Vector2(dusman_x, dusman_y)
	
	# Düşman görsel (ColorRect) - BÜYÜK
	var dusman_node = ColorRect.new()
	dusman_node.custom_minimum_size = Vector2(120, 120)
	dusman_node.size = Vector2(120, 120)
	dusman_node.color = dusman.renk
	dusman_container.add_child(dusman_node)
	
	# İsim label
	var isim_label = Label.new()
	isim_label.text = dusman.isim
	isim_label.position = Vector2(0, -30)
	isim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isim_label.custom_minimum_size = Vector2(80, 20)
	dusman_container.add_child(isim_label)
	
	# HP Bar container
	var hp_container = Control.new()
	hp_container.position = Vector2(0, 130)
	hp_container.custom_minimum_size = Vector2(120, 20)
	dusman_container.add_child(hp_container)
	
	# HP Bar background
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(120, 15)
	hp_bg.color = Color(0.2, 0.2, 0.2)
	hp_container.add_child(hp_bg)
	
	# HP Bar fill
	var hp_bar = ColorRect.new()
	hp_bar.size = Vector2(120, 15)
	hp_bar.color = Color(0, 1, 0)
	hp_bar.name = "HPBar"
	hp_container.add_child(hp_bar)
	
	# HP text
	var hp_label = Label.new()
	hp_label.text = str(dusman.current_hp) + "/" + str(dusman.max_hp)
	hp_label.position = Vector2(0, 15)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.custom_minimum_size = Vector2(80, 20)
	hp_label.name = "HPLabel"
	hp_container.add_child(hp_label)
	
	# Konuşma balonu - düşmanın sağ üstünde
	if ResourceLoader.exists("res://speech_bubble.tscn"):
		var balon = load("res://speech_bubble.tscn").instantiate()
		# Düşmanın sağ üst köşesine yerleştir
		balon.position = Vector2(dusman_genislik, -70)
		balon.set_size(Vector2(180, 65))
		balon.name = "SpeechBubble"
		dusman_container.add_child(balon)
	
	get_parent().add_child(dusman_container)
	
	return dusman_container

func ilk_player_turn_basla():
	if player_characters.size() > 0:
		aktif_karakter_index = 0
		player_turn_basla()

func player_turn_basla():
	suanki_durum = TurnDurumu.PLAYER_1 if aktif_karakter_index == 0 else TurnDurumu.PLAYER_2
	suanki_faz = TurnFazi.MENU
	turn_basladi.emit(aktif_karakter_index)
	
	if player_node:
		player_node.process_mode = Node.PROCESS_MODE_DISABLED
		player_node.visible = false
	
	# Flavor text sadece round basinda (ilk karakter)
	if aktif_karakter_index == 0 and message_box:
		var flavor = flavor_text_sec()
		if flavor != "":
			message_box.flavor_goster(flavor)
	
	if battle_ui:
		battle_ui.visible = true
		battle_ui.turn_menusu_goster(player_characters[aktif_karakter_index])

func flavor_text_sec() -> String:
	var canli = []
	for d in dusmanlar:
		if not d["data"].oldu_mu():
			canli.append(d["data"])
	if canli.is_empty():
		return ""
	var dusman = canli[randi() % canli.size()]
	if dusman.flavor_texts.size() > 0:
		return dusman.flavor_texts[randi() % dusman.flavor_texts.size()]
	return ""

# PLAYER EYLEM SEÇTİ
func player_eylem_sec(eylem_tipi: String):
	match eylem_tipi:
		"SALDIR":
			saldiri_baslat()
		"SIHIR":
			sihir_menusu_goster()
		"EYLEM":
			act_menusu_goster()
		"ITEM":
			item_menusu_goster()
		"INSAF":
			insaf_menusu_goster()

func saldiri_baslat():
	print("Saldırı başlatıldı!")
	# Hedef seçimi
	if battle_ui:
		battle_ui.hedef_secim_goster(dusmanlar)

func hedef_secildi(hedef_index: int):
	# Timing bar başlat
	if timing_bar:
		timing_bar.baslat()
		
		# Timing bar sinyalini bekle
		var sonuc = await timing_bar.timing_tamamlandi
		var kalite = sonuc[0]
		var carpan = sonuc[1]
		
		# Hasar hesapla
		hasar_ver(hedef_index, carpan)
	else:
		# Timing bar yoksa normal hasar
		hasar_ver(hedef_index, 1.0)

func hasar_ver(hedef_index: int, carpan: float):
	var karakter = player_characters[aktif_karakter_index]
	var base_damage = karakter["atk"]
	var damage = int(base_damage * carpan)
	
	if hedef_index < dusmanlar.size():
		var dusman_dict = dusmanlar[hedef_index]
		dusman_dict["data"].hasar_al(damage)
		
		# HP bar ve label güncelle
		if is_instance_valid(dusman_dict["node"]):
			# HP Bar güncelle
			if dusman_dict["node"].has_node("Control/HPBar"):
				var hp_bar = dusman_dict["node"].get_node("Control/HPBar")
				var hp_ratio = float(dusman_dict["data"].current_hp) / float(dusman_dict["data"].max_hp)
				hp_bar.size.x = 80 * hp_ratio
				
				# Renk değiştir (yeşil → sarı → kırmızı)
				if hp_ratio > 0.5:
					hp_bar.color = Color(0, 1, 0)  # Yeşil
				elif hp_ratio > 0.25:
					hp_bar.color = Color(1, 1, 0)  # Sarı
				else:
					hp_bar.color = Color(1, 0, 0)  # Kırmızı
			
			# HP Label güncelle
			if dusman_dict["node"].has_node("Control/HPLabel"):
				var hp_label = dusman_dict["node"].get_node("Control/HPLabel")
				hp_label.text = str(dusman_dict["data"].current_hp) + "/" + str(dusman_dict["data"].max_hp)
		
		# Sadece timing sonucunu kısa göster (flavor text kaybolmaz)
		if message_box:
			var kalite_text = ""
			if carpan >= 2.0:
				kalite_text = "PERFECT!"
			elif carpan >= 1.0:
				kalite_text = "GOOD!"
			else:
				kalite_text = "MISS..."
			message_box.sonuc_goster(kalite_text)
		
		print(dusman_dict["data"].isim + " " + str(damage) + " hasar aldi! (x" + str(carpan) + ")")
		
		# Öldü mü?
		var oldu = dusman_dict["data"].oldu_mu()
		if oldu:
			dusman_oldu(hedef_index)
	
	# Savaş kazanıldıysa turn bitirme
	if aktif_dusman_sayisi <= 0:
		return
	
	# Turn bitir
	await get_tree().create_timer(1.0).timeout
	player_turn_bitir()

func dusman_oldu(index: int):
	print(dusmanlar[index]["data"].isim + " yenildi!")
	
	# Node'u kaldır
	if dusmanlar[index]["node"]:
		dusmanlar[index]["node"].queue_free()
	
	aktif_dusman_sayisi -= 1
	
	# Tüm düşmanlar öldü mü?
	if aktif_dusman_sayisi <= 0:
		savas_kazanildi()

func player_turn_bitir():
	aktif_karakter_index += 1
	
	# Tüm karakterler oynádı mı?
	if aktif_karakter_index >= player_characters.size():
		dusman_turn_basla()
	else:
		player_turn_basla()

func dusman_turn_basla():
	suanki_durum = TurnDurumu.DUSMAN
	suanki_faz = TurnFazi.GRID  # Grid fazı
	dusman_turn_basladi.emit()
	
	# Menüyü kapat, grid'i aç (animasyonlu)
	if battle_ui:
		await battle_ui.panelleri_gizle()
	
	# Flavor text düşman turunda da devam eder (paneller kapandıktan sonra göster)
	if message_box:
		var flavor = flavor_text_sec()
		if flavor != "":
			message_box.flavor_goster(flavor)
	
	if player_node:
		player_node.process_mode = Node.PROCESS_MODE_ALWAYS
		player_node.visible = true
	
	# Düşman konuşması (balon ile)
	await dusman_konusma_goster()
	
	# Pattern başlat
	await dusman_pattern_calistir()
	
	dusman_turn_bitir()

func dusman_konusma_goster():
	# İlk canlı düşman konuşur, bitmesini bekle
	var konusan_balon = null
	for dusman_dict in dusmanlar:
		var data = dusman_dict["data"]
		if not data.oldu_mu():
			if is_instance_valid(dusman_dict["node"]) and dusman_dict["node"].has_node("SpeechBubble"):
				var balon = dusman_dict["node"].get_node("SpeechBubble")
				var diyalog = data.sonraki_diyalog()
				if diyalog != "":
					var satirlar: Array = Array(diyalog.split("|"))
					balon.goster_liste(satirlar)
					konusan_balon = balon
				break  # Sadece ilk canlı düşman konuşur
	
	if konusan_balon != null:
		await konusan_balon.konusma_bitti
	else:
		# Konuşacak düşman yok, kısa bekle
		await get_tree().create_timer(0.3).timeout

func dusman_pattern_calistir():
	# Her canlı düşman saldırır
	for dusman_dict in dusmanlar:
		if not dusman_dict["data"].oldu_mu():
			var pattern_type = pattern_turunu_belirle(dusman_dict["data"].pattern_turu)
			var pattern = AttackPattern.new(pattern_type, get_parent(), grid_node)
			await pattern.calistir()

func pattern_turunu_belirle(pattern_str: String) -> AttackPattern.PatternType:
	match pattern_str:
		"basit":
			return AttackPattern.PatternType.BASIT_DALGALI
		"orta":
			return AttackPattern.PatternType.IZGARA
		"zor":
			return AttackPattern.PatternType.SPIRAL
		"boss":
			return AttackPattern.PatternType.BOSS_LAZER
		_:
			return AttackPattern.PatternType.RANDOM_SPAM

func dusman_turn_bitir():
	# Yeni round başlat
	ilk_player_turn_basla()

func savas_kazanildi():
	print("Savaş Kazanıldı!")
	savas_bitti.emit(true)
	
	# EXP/Altın ver (gelecekte)
	await get_tree().create_timer(2.0).timeout
	
	# Overworld'e dön
	get_tree().change_scene_to_file("res://Rooms/overworld.tscn")

func savas_kaybedildi():
	print("Savaş Kaybedildi!")
	savas_bitti.emit(false)
	
	# Game Over ekranı (gelecekte)

# --- MENÜ FONKSİYONLARI (Placeholder) ---
func sihir_menusu_goster():
	print("Sihir menüsü - Henüz hazır değil")
	await get_tree().create_timer(0.5).timeout
	player_turn_bitir()

func act_menusu_goster():
	print("Act menüsü")
	if battle_ui:
		# İlk düşmanın act'lerini göster
		if dusmanlar.size() > 0:
			battle_ui.act_secenekleri_goster(dusmanlar[0]["data"].acts)

func act_secildi(act_ismi: String, hedef_index: int):
	if hedef_index < dusmanlar.size():
		var mesaj = dusmanlar[hedef_index]["data"].act_yap(act_ismi)
		print(mesaj)
		
		# Barış edildi mi kontrol et
		if dusmanlar[hedef_index]["data"].baris_edildi:
			print(dusmanlar[hedef_index]["data"].isim + " ile barış sağlandı!")
			# Düşmanı kaldır
			dusman_oldu(hedef_index)
	
	await get_tree().create_timer(1.5).timeout
	player_turn_bitir()

func item_menusu_goster():
	print("Item menüsü")
	# Envanter aç
	await get_tree().create_timer(0.5).timeout
	player_turn_bitir()

func insaf_menusu_goster():
	print("İnsaf menüsü")
	# Kaçış veya affet
	await get_tree().create_timer(0.5).timeout
	player_turn_bitir()
