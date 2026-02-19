extends Node
class_name BattleManager

# --- SİNYALLER ---
signal turn_basladi(karakter_index: int)
signal dusman_turn_basladi
signal savas_bitti(kazanildi: bool)

# --- REFERANSLAR ---
var battle_ui
var grid_node: Node2D
var player_node: Area2D
var timing_bar: Control
var message_box: Control

# --- DÜŞMANLAR ---
var dusmanlar: Array = []
var aktif_dusman_sayisi: int = 0

# --- TURN SİSTEMİ ---
enum TurnDurumu {PLAYER_1, PLAYER_2, DUSMAN, BEKLEME}
var suanki_durum: TurnDurumu = TurnDurumu.BEKLEME
var aktif_karakter_index: int = 0

enum TurnFazi {MENU, GRID}
var suanki_faz: TurnFazi = TurnFazi.MENU

# --- PLAYER DATA ---
var player_characters: Array = []

# Hasar havuzu: düşman saldırısından gelen hasarı hangi karakterden başlayarak dağıtacağız
var hasar_dagilim_index: int = 0

# ============================================================
# DÜŞMAN SPAWN
# ============================================================

# 1-4 düşman için sabit grid pozisyonları (ekran 640x360, düşman alanı y=100-240)
const POZISYON_GRIDI = {
	1: [Vector2(320, 100)],
	2: [Vector2(210, 100), Vector2(430, 100)],
	3: [Vector2(130, 100), Vector2(320, 100), Vector2(510, 100)],
	4: [Vector2(110, 90), Vector2(270, 90), Vector2(390, 90), Vector2(540, 90)]
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func savas_baslat(dusman_listesi: Array):
	print("Savaş Başladı!")
	player_characters = Global.party_data
	hasar_dagilim_index = 0

	if player_node:
		player_node.process_mode = Node.PROCESS_MODE_DISABLED
		player_node.visible = false

	dusmanlar.clear()
	var toplam = dusman_listesi.size()
	var pozlar = POZISYON_GRIDI.get(min(toplam, 4), POZISYON_GRIDI[4])

	for i in range(toplam):
		var dusman_data = dusman_listesi[i].duplicate()
		var node = spawn_dusman(dusman_data, i, pozlar[i])
		dusmanlar.append({"data": dusman_data, "node": node})

	aktif_dusman_sayisi = dusmanlar.size()
	await get_tree().create_timer(0.5).timeout
	ilk_player_turn_basla()

func spawn_dusman(dusman: EnemyData, _index: int, pozisyon: Vector2) -> Node2D:
	const GW = 56   # Düşman genişliği
	const GH = 56   # Düşman yüksekliği

	var container = Node2D.new()
	container.position = pozisyon

	# Renkli kare (sprite placeholder)
	var rect = ColorRect.new()
	rect.size = Vector2(GW, GH)
	rect.position = Vector2(-GW / 2, -GH / 2)
	rect.color = dusman.renk
	container.add_child(rect)

	# İsim (üstte, küçük)
	var isim_lbl = Label.new()
	isim_lbl.text = dusman.isim
	isim_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	isim_lbl.position = Vector2(-50, -GH / 2 - 18)
	isim_lbl.custom_minimum_size = Vector2(100, 16)
	var isim_font = isim_lbl.get_theme_default_font()
	isim_lbl.add_theme_font_size_override("font_size", 10)
	container.add_child(isim_lbl)

	# Konuşma balonu (sağ üstte)
	if ResourceLoader.exists("res://speech_bubble.tscn"):
		var balon = load("res://speech_bubble.tscn").instantiate()
		balon.position = Vector2(GW / 2, -GH / 2 - 60)
		balon.set_size(Vector2(160, 55))
		balon.name = "SpeechBubble"
		container.add_child(balon)

	get_parent().add_child(container)
	return container

# ============================================================
# PLAYER TURN SİSTEMİ
# ============================================================

func ilk_player_turn_basla():
	aktif_karakter_index = 0
	_sonraki_aktif_karaktere_gec()

func player_turn_basla():
	var karakter = player_characters[aktif_karakter_index]

	# Baygınsa bu karakteri atla
	if karakter.get("baygin", false):
		player_turn_bitir()
		return

	suanki_durum = TurnDurumu.PLAYER_1 if aktif_karakter_index == 0 else TurnDurumu.PLAYER_2
	suanki_faz = TurnFazi.MENU
	turn_basladi.emit(aktif_karakter_index)

	if player_node:
		player_node.process_mode = Node.PROCESS_MODE_DISABLED
		player_node.visible = false

	if battle_ui:
		battle_ui.visible = true
		battle_ui.turn_menusu_goster(karakter)

	# Oyuncu turu: flavor text göster
	if aktif_karakter_index == 0 and message_box:
		var flavor = flavor_text_sec()
		if flavor != "":
			message_box.visible = true
			message_box.flavor_goster(flavor)
		else:
			message_box.visible = false

func player_turn_bitir():
	aktif_karakter_index += 1
	_sonraki_aktif_karaktere_gec()

func _sonraki_aktif_karaktere_gec():
	# Tüm karakterler oynadı mı?
	if aktif_karakter_index >= player_characters.size():
		dusman_turn_basla()
		return

	var karakter = player_characters[aktif_karakter_index]
	if karakter.get("baygin", false):
		# Baygın karakteri atla
		aktif_karakter_index += 1
		_sonraki_aktif_karaktere_gec()
	else:
		player_turn_basla()

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

# ============================================================
# OYUNCU EYLEMLERİ
# ============================================================

func player_eylem_sec(eylem_tipi: String):
	match eylem_tipi:
		"SALDIR": saldiri_baslat()
		"SIHIR":  sihir_menusu_goster()
		"EYLEM":  act_menusu_goster()
		"ITEM":   item_menusu_goster()
		"INSAF":  insaf_menusu_goster()

func saldiri_baslat():
	if battle_ui:
		battle_ui.hedef_secim_goster(dusmanlar)

func hedef_secildi(hedef_index: int):
	if timing_bar:
		timing_bar.baslat()
		var sonuc = await timing_bar.timing_tamamlandi
		var carpan = sonuc[1]
		hasar_ver(hedef_index, carpan)
	else:
		hasar_ver(hedef_index, 1.0)

func hasar_ver(hedef_index: int, carpan: float):
	if hedef_index >= dusmanlar.size():
		player_turn_bitir()
		return

	var karakter = player_characters[aktif_karakter_index]
	var damage = int(karakter["atk"] * carpan)
	var dusman_dict = dusmanlar[hedef_index]
	dusman_dict["data"].hasar_al(damage)

	# HP bar güncelle (hedef seçim ekranında gösterilir, burada sadece veri)
	_dusman_hp_guncelle(hedef_index)

	# Timing sonucu göster
	if message_box:
		var kalite = "MISS..." if carpan < 1.0 else ("PERFECT!" if carpan >= 2.0 else "GOOD!")
		message_box.visible = true
		message_box.sonuc_goster(kalite)

	print(dusman_dict["data"].isim + " " + str(damage) + " hasar aldı!")

	if dusman_dict["data"].oldu_mu():
		dusman_oldu(hedef_index)

	if aktif_dusman_sayisi <= 0:
		return

	await get_tree().create_timer(1.0).timeout
	player_turn_bitir()

func _dusman_hp_guncelle(hedef_index: int):
	# Sadece veri güncellemesi — görsel HP barı hedef_secim_goster'de çizilir
	pass

func dusman_oldu(index: int):
	print(dusmanlar[index]["data"].isim + " yenildi!")
	if is_instance_valid(dusmanlar[index]["node"]):
		dusmanlar[index]["node"].queue_free()
	aktif_dusman_sayisi -= 1
	if aktif_dusman_sayisi <= 0:
		savas_kazanildi()

# ============================================================
# DÜŞMAN TURN SİSTEMİ
# ============================================================

func dusman_turn_basla():
	suanki_durum = TurnDurumu.DUSMAN
	suanki_faz = TurnFazi.GRID
	dusman_turn_basladi.emit()
	# Düşman turu boyunca metin kutusu KAPALI
	if message_box:
		message_box.visible = false

	if battle_ui:
		await battle_ui.panelleri_gizle()
		# Düşman turu: sadece stat paneli kalır, menü yok
		battle_ui.sadece_stat_goster()

	await dusman_konusma_goster()

	# Konuşma bitti - metin kutusu KAPALI kalır, sadece grid/pattern

	if player_node:
		player_node.process_mode = Node.PROCESS_MODE_ALWAYS
		player_node.visible = true

	await dusman_pattern_calistir()
	dusman_turn_bitir()

func dusman_konusma_goster():
	var konusan_balon = null
	for dusman_dict in dusmanlar:
		var data = dusman_dict["data"]
		if not data.oldu_mu():
			if is_instance_valid(dusman_dict["node"]) and dusman_dict["node"].has_node("SpeechBubble"):
				var balon = dusman_dict["node"].get_node("SpeechBubble")
				var diyalog = data.sonraki_diyalog()
				if diyalog != "":
					balon.goster_liste(Array(diyalog.split("|")))
					konusan_balon = balon
			break

	if konusan_balon != null:
		await konusan_balon.konusma_bitti
	else:
		await get_tree().create_timer(0.3).timeout

func dusman_pattern_calistir():
	for dusman_dict in dusmanlar:
		if not dusman_dict["data"].oldu_mu():
			var pattern_type = pattern_turunu_belirle(dusman_dict["data"].pattern_turu)
			var pattern = AttackPattern.new(pattern_type, get_parent(), grid_node)
			await pattern.calistir()
			# Grid'den hasar al (oyuncu kaçamadıysa graze_points vs. ilerleyen versiyonda)

func _parti_hasar_uygula(miktar: int):
	var etkilenenler = Global.parti_hasar_al(miktar, hasar_dagilim_index)
	# Bir sonraki hasar için index ilerlet (son etkilenen karakterden devam)
	if etkilenenler.size() > 0:
		var son_isim = etkilenenler[-1]["isim"]
		for i in range(Global.party_data.size()):
			if Global.party_data[i]["isim"] == son_isim:
				hasar_dagilim_index = (i + 1) % Global.party_data.size()
				break
		# Baygin kontrolü
		for k in Global.party_data:
			if k["hp"] <= 0 and not k.get("baygin", false):
				k["hp"] = 0
				k["baygin"] = true
				print(k["isim"] + " bayıldı!")
	# UI'yi güncelle
	if battle_ui and battle_ui.visible:
		battle_ui.stat_guncelle()

func dusman_turn_bitir():
	# Düşman turu bitti - metin kutusunu kapat
	if message_box:
		message_box.visible = false
	# Tüm karakterler baygın mı kontrol et
	var hepsi_baygin = true
	for k in Global.party_data:
		if not k.get("baygin", false):
			hepsi_baygin = false
			break
	if hepsi_baygin:
		savas_kaybedildi()
		return
	ilk_player_turn_basla()

func pattern_turunu_belirle(pattern_str: String) -> AttackPattern.PatternType:
	match pattern_str:
		"basit": return AttackPattern.PatternType.BASIT_DALGALI
		"orta":  return AttackPattern.PatternType.IZGARA
		"zor":   return AttackPattern.PatternType.SPIRAL
		"boss":  return AttackPattern.PatternType.BOSS_LAZER
		_:       return AttackPattern.PatternType.RANDOM_SPAM

# ============================================================
# SAVAŞ SONU
# ============================================================

func savas_kazanildi():
	print("Savaş Kazanıldı!")
	savas_bitti.emit(true)
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://Rooms/overworld.tscn")

func savas_kaybedildi():
	print("Savaş Kaybedildi!")
	savas_bitti.emit(false)

# ============================================================
# MENÜ FONKSİYONLARI
# ============================================================

func sihir_menusu_goster():
	print("Sihir menüsü - Henüz hazır değil")
	await get_tree().create_timer(0.5).timeout
	player_turn_bitir()

func act_menusu_goster():
	if battle_ui and dusmanlar.size() > 0:
		battle_ui.act_secenekleri_goster(dusmanlar[0]["data"].acts)

func act_secildi(act_ismi: String, hedef_index: int):
	if hedef_index < dusmanlar.size():
		var mesaj = dusmanlar[hedef_index]["data"].act_yap(act_ismi)
		print(mesaj)
		if dusmanlar[hedef_index]["data"].baris_edildi:
			dusman_oldu(hedef_index)
	await get_tree().create_timer(1.5).timeout
	player_turn_bitir()

func item_menusu_goster():
	print("Item menüsü")
	await get_tree().create_timer(0.5).timeout
	player_turn_bitir()

func insaf_menusu_goster():
	print("İnsaf menüsü")
	await get_tree().create_timer(0.5).timeout
	player_turn_bitir()
