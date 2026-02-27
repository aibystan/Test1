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
var karakter_nodelar: Array = []  # Savaştaki karakter sprite nodeları

# Hasar havuzu: düşman saldırısından gelen hasarı hangi karakterden başlayarak dağıtacağız
var hasar_dagilim_index: int = 0

# ============================================================
# DÜŞMAN SPAWN
# ============================================================

# 1-4 düşman için sabit grid pozisyonları (ekran 640x360, düşman alanı y=100-240)
const POZISYON_GRIDI = {
	1: [Vector2(320, 70)],
	2: [Vector2(210, 70), Vector2(430, 70)],
	3: [Vector2(130, 70), Vector2(320, 70), Vector2(510, 70)],
	4: [Vector2(110, 70), Vector2(270, 70), Vector2(390, 70), Vector2(540, 70)]
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func savas_baslat(dusman_listesi: Array):
	print("Savaş Başladı!")
	
	# Sadece aktif party üyelerini al
	if Global.takipci_aktif:
		# İki karakter birlikte
		player_characters = Global.party_data.duplicate()
		print("Savaş: Oyuncu + Takipçi (2 karakter)")
	else:
		# Sadece ilk karakter (player)
		player_characters = [Global.party_data[0]]
		print("Savaş: Sadece Oyuncu (1 karakter)")
	
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
	_karakterleri_spawn_et()
	ilk_player_turn_basla()

func spawn_dusman(dusman: EnemyData, _index: int, pozisyon: Vector2) -> Node2D:
	const GW = 56
	const GH = 56

	var container = Node2D.new()
	container.position = pozisyon

	# AnimatedSprite > Sprite > ColorRect öncelik sırası
	if dusman.sprite_frames:
		var anim_spr = AnimatedSprite2D.new()
		anim_spr.sprite_frames = dusman.sprite_frames
		anim_spr.name = "AnimSprite"
		# Boyut ayarı: frames'teki ilk frame'e göre ölçekle
		var anim_isim = dusman.varsayilan_animasyon if dusman.varsayilan_animasyon != "" else "idle"
		if dusman.sprite_frames.has_animation(anim_isim):
			var frame_tex = dusman.sprite_frames.get_frame_texture(anim_isim, 0)
			if frame_tex:
				var tex_size = frame_tex.get_size()
				var olcek = Vector2(float(GW) / tex_size.x, float(GH) / tex_size.y)
				anim_spr.scale = olcek
			anim_spr.play(anim_isim)
		container.add_child(anim_spr)
	elif dusman.sprite:
		var spr = Sprite2D.new()
		spr.texture = dusman.sprite
		var tex_size = dusman.sprite.get_size()
		var olcek = Vector2(float(GW) / tex_size.x, float(GH) / tex_size.y)
		spr.scale = olcek
		container.add_child(spr)
	else:
		var rect = ColorRect.new()
		rect.size = Vector2(GW, GH)
		rect.position = Vector2(-GW / 2, -GH / 2)
		rect.color = dusman.renk
		container.add_child(rect)

	# Konuşma balonu (sağ üstte)
	if ResourceLoader.exists("res://speech_bubble.tscn"):
		var balon = load("res://speech_bubble.tscn").instantiate()
		balon.position = Vector2(GW / 2, -GH / 2 - 20)
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
	if aktif_karakter_index == 0:
		_karakterleri_goster()  # Sadece ilk tur başında fade-in
	# GP artışı için aktif karakter indexini player_node'a bildir
	if player_node:
		player_node.aktif_karakter_index = aktif_karakter_index
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
	# Eylem seçilince menüyü hemen kilitle (çift basış önlenir)
	if battle_ui: battle_ui.menu_tipi = ""
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
	# Act modu: hedef seçildi, o düşmanın act listesini göster
	if _bekleyen_eylem_mod == "ACT":
		_bekleyen_eylem_mod = ""
		_bekleyen_act_hedef = hedef_index
		if battle_ui and hedef_index < dusmanlar.size():
			battle_ui.act_secenekleri_goster(dusmanlar[hedef_index]["data"].acts)
		return
	# Sihir modundaysak sihir hasar fonksiyonuna yönlendir
	if not _bekleyen_sihir.is_empty() and _bekleyen_sihir.get("tip") == "SQA":
		sihir_hedef_secildi(hedef_index)
		_bekleyen_sihir = {}
		return
	if timing_bar:
		if battle_ui:
			battle_ui._blur_gizle()
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

	if aktif_karakter_index >= player_characters.size():
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
	aktif_karakter_index += 1
	_sonraki_aktif_karaktere_gec()

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

func _karakterleri_spawn_et():
	# Önceki nodeları temizle
	for n in karakter_nodelar:
		if is_instance_valid(n): n.queue_free()
	karakter_nodelar.clear()

	var aktif = []
	for k in player_characters:
		if not k.get("baygin", false):
			aktif.append(k)

	# Pozisyonlar: 1 karakter ortada, 2 karakter yan yana
	var pozlar = []
	if aktif.size() == 1:
		pozlar = [Vector2(315, 255)]
	elif aktif.size() >= 2:
		pozlar = [Vector2(280, 255), Vector2(355, 255)]

	for i in range(min(aktif.size(), pozlar.size())):
		var k = aktif[i]
		var node = _karakter_node_olustur(k)
		node.position = pozlar[i]
		get_parent().add_child(node)
		karakter_nodelar.append(node)

func _karakter_node_olustur(k: Dictionary) -> Node2D:
	var node = Node2D.new()
	node.name = "BattleKarakter_" + k["isim"]

	# Sprite veya renk kutusu
	var sprite_tex = k.get("battle_sprite", null)
	if sprite_tex:
		var spr = Sprite2D.new()
		spr.texture = sprite_tex
		node.add_child(spr)
	else:
		var rect = ColorRect.new()
		rect.size = Vector2(32, 48)
		rect.position = Vector2(-16, -48)
		rect.color = k.get("renk", Color(0.8, 0.4, 0.4))
		node.add_child(rect)
	return node

func _karakterleri_goster():
	for node in karakter_nodelar:
		if is_instance_valid(node):
			var tw = node.create_tween()
			node.modulate.a = 0.0
			node.visible = true
			tw.tween_property(node, "modulate:a", 1.0, 0.4)

func _karakterleri_gizle():
	for node in karakter_nodelar:
		if is_instance_valid(node):
			var tw = node.create_tween()
			tw.tween_property(node, "modulate:a", 0.0, 0.4)
			tw.tween_callback(func(): if is_instance_valid(node): node.visible = false)

func dusman_turn_basla():
	suanki_durum = TurnDurumu.DUSMAN
	suanki_faz = TurnFazi.GRID
	_karakterleri_gizle()
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
	# Tüm canlı düşmanları aynı anda konuştur
	var balonlar = []
	for dusman_dict in dusmanlar:
		var data = dusman_dict["data"]
		if not data.oldu_mu():
			if is_instance_valid(dusman_dict["node"]) and dusman_dict["node"].has_node("SpeechBubble"):
				var balon = dusman_dict["node"].get_node("SpeechBubble")
				var diyalog = data.sonraki_diyalog()
				if diyalog != "":
					balon.goster_liste(Array(diyalog.split("|")))
					balonlar.append(balon)
	# Tüm balonların bitmesini bekle (sayaç ile - sinyal kaçırma önlenir)
	if balonlar.is_empty():
		await get_tree().create_timer(0.3).timeout
	else:
		var biten = [0]  # Array: lambda içinden referansla değiştirilebilir
		for balon in balonlar:
			balon.konusma_bitti.connect(func(): biten[0] += 1)
		while biten[0] < balonlar.size():
			await get_tree().process_frame

func dusman_pattern_calistir():
	for dusman_dict in dusmanlar:
		if not dusman_dict["data"].oldu_mu():
			var pattern_type = pattern_turunu_belirle(dusman_dict["data"].pattern_turu)
			var pattern = AttackPattern.new(pattern_type, get_parent(), grid_node)
			await pattern.calistir()
			# Grid'den hasar al (oyuncu kaçamadıysa graze_points vs. ilerleyen versiyonda)

func _parti_hasar_uygula(miktar: int):
	var etkilenenler = Global.parti_hasar_al(miktar, hasar_dagilim_index)
	# Hasar mesajını göster
	# Hasar mesajı metin kutusunda gösterilmiyor
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
	
	# Ödülleri hesapla
	var toplam_xp = 0
	var toplam_gold = 0
	
	for dusman_dict in dusmanlar:
		var dusman = dusman_dict["data"]
		# Her düşman XP ve gold veriyor
		toplam_xp += dusman.max_hp  # Basit: Max HP kadar XP
		toplam_gold += dusman.max_hp / 2  # Max HP'nin yarısı kadar gold
	
	# Victory screen göster
	var victory_screen = get_tree().current_scene.get_node_or_null("BattleVictoryScreen")
	if victory_screen:
		# TimingBar'ı gizle
		var tb = get_tree().current_scene.get_node_or_null("TimingBar")
		if tb: tb.visible = false
		victory_screen.goster(toplam_xp, toplam_gold)
	else:
		print("UYARI: Victory screen bulunamadı, overworld'e dönülüyor")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://Rooms/overworld.tscn")

func savas_kaybedildi():
	print("Savaş Kaybedildi!")
	savas_bitti.emit(false)

# ============================================================
# MENÜ FONKSİYONLARI
# ============================================================

func act_menusu_goster():
	# Önce düşman hedef seçimi
	if battle_ui:
		_bekleyen_eylem_mod = "ACT"
		battle_ui.hedef_secim_goster(dusmanlar)

func act_secildi(act_ismi: String, _hedef_index_unused: int):
	var hedef_index = _bekleyen_act_hedef
	_bekleyen_act_hedef = 0
	if hedef_index < dusmanlar.size():
		var dusman_data = dusmanlar[hedef_index]["data"]
		var mesaj = dusman_data.act_yap(act_ismi)
		if message_box:
			message_box.visible = true
			message_box.flavor_goster(mesaj)
		# baris_edildi -> spareable aktif, ama hemen ölmez
		if dusman_data.baris_edildi:
			dusman_data.spareable = true
			dusman_data.baris_edildi = false
	await get_tree().create_timer(1.5).timeout
	# Eylem metni bitti, flavor text'e dön
	if message_box:
		var flavor = flavor_text_sec()
		if flavor != "":
			message_box.flavor_goster(flavor)
	aktif_karakter_index += 1
	_sonraki_aktif_karaktere_gec()

func item_menusu_goster():
	# Envanterden sadece TUKETILEBILIR eşyaları filtrele
	var kullanilabilir = []
	for i in range(Global.inventory.size()):
		var esya = Global.inventory[i]
		if esya.tur == ItemData.Tip.TUKETILEBILIR:
			kullanilabilir.append({"esya": esya, "index": i})
	
	if kullanilabilir.is_empty():
		if message_box:
			message_box.visible = true
			message_box.flavor_goster("Kullanılabilecek eşya yok.")
		await get_tree().create_timer(1.0).timeout
		if message_box: message_box.flavor_goster(flavor_text_sec())
		aktif_karakter_index += 1
		_sonraki_aktif_karaktere_gec()
		return
	
	_item_listesi = kullanilabilir
	if battle_ui:
		battle_ui.item_menusu_ac(_item_listesi, self)

func item_secildi(liste_index: int):
	if liste_index >= _item_listesi.size(): return
	var secim = _item_listesi[liste_index]
	var esya = secim["esya"]
	var envanter_index = secim["index"]
	
	# Hedef karakter seçimi gerekiyor
	_bekleyen_item = {"esya": esya, "envanter_index": envanter_index}
	if battle_ui:
		battle_ui.item_paneli_kapat()
		battle_ui.parti_hedef_sec_goster(Global.party_data, "ITEM")

func item_hedef_secildi(hedef_index: int):
	if _bekleyen_item.is_empty(): return
	var esya = _bekleyen_item["esya"]
	var envanter_index = _bekleyen_item["envanter_index"]
	_bekleyen_item = {}
	
	var k = Global.party_data[hedef_index]
	var mesaj = ""
	
	if esya.etki_turu == ItemData.EtkiTuru.HP:
		k["hp"] = min(k["hp"] + esya.etki_degeri, k["max_hp"])
		if k.get("baygin", false) and k["hp"] > 0:
			k["baygin"] = false
		mesaj = esya.isim + " kullanıldı! " + k["isim"] + " +" + str(esya.etki_degeri) + " HP"
	elif esya.etki_turu == ItemData.EtkiTuru.QUT:
		k["qut"] = min(k.get("qut", 0) + esya.etki_degeri, k.get("max_qut", 200))
		mesaj = esya.isim + " kullanıldı! " + k["isim"] + " +" + str(esya.etki_degeri) + " QUT"
	
	# Eşyayı envanterden çıkar
	Global.envanterden_cikar(envanter_index)
	
	if message_box:
		message_box.visible = true
		message_box.flavor_goster(mesaj)
	if battle_ui: battle_ui.stat_guncelle()
	await get_tree().create_timer(1.5).timeout
	if message_box: message_box.flavor_goster(flavor_text_sec())
	aktif_karakter_index += 1
	_sonraki_aktif_karaktere_gec()

func insaf_menusu_goster():
	# Tüm spareable düşmanları bul
	var spareable_indexler = []
	for i in range(dusmanlar.size()):
		if dusmanlar[i]["data"].spareable:
			spareable_indexler.append(i)

	if spareable_indexler.is_empty():
		if message_box:
			message_box.visible = true
			message_box.flavor_goster("Kimseyi affetmedin.")
		await get_tree().create_timer(1.0).timeout
		if message_box: message_box.flavor_goster(flavor_text_sec())
		# player_turn_bitir() yerine direkt ilerle - await çakışmasını önler
		aktif_karakter_index += 1
		_sonraki_aktif_karaktere_gec()
		return

	# Sondan başa sil (index kaymaması için)
	for i in range(spareable_indexler.size() - 1, -1, -1):
		var idx = spareable_indexler[i]
		var d = dusmanlar[idx]
		if message_box:
			message_box.visible = true
			message_box.flavor_goster(d["data"].isim + " savaşı terk etti!")
		await get_tree().create_timer(1.0).timeout
		var node = d["node"]
		if is_instance_valid(node): node.queue_free()
		dusmanlar.remove_at(idx)
		aktif_dusman_sayisi -= 1

	if battle_ui: battle_ui.stat_guncelle()

	if aktif_dusman_sayisi <= 0:
		savas_kazanildi()
		return

	if message_box: message_box.flavor_goster(flavor_text_sec())
	# Tüm spareable işlemi bitti, tur sona erer (index'i ilerletme, bitir)
	aktif_karakter_index = player_characters.size()  # Turu zorla bitir
	_sonraki_aktif_karaktere_gec()

# ============================================================
# SİHİR SİSTEMİ
# ============================================================

# Karakter başına sihir listeleri
const SIHIRLER = {
	"Ryu": {
		"SQA": [
			{"isim": "SaldiriSihri", "qut": 30, "aciklama": "Güçlü saldırı"},
		],
		"DQA": [
			{"isim": "BeraberSihri", "qut_her": 25, "aciklama": "İki turun geçer"},
		]
	},
	"Nina": {
		"SQA": [
			{"isim": "IyilesmeSihri", "qut": 20, "aciklama": "50 can iyileşir", "hedef_sec": true},
		],
		"DQA": []
	}
}

var _bekleyen_sihir: Dictionary = {}
var _bekleyen_eylem_mod: String = ""
var _bekleyen_act_hedef: int = 0
var _item_listesi: Array = []
var _bekleyen_item: Dictionary = {}

func sihir_menusu_goster():
	var karakter = player_characters[aktif_karakter_index]
	var isim = karakter["isim"]
	var sihirler = SIHIRLER.get(isim, {"SQA": [], "DQA": []})

	# Menü seçeneklerini oluştur
	var secenekler = []
	for s in sihirler["SQA"]:
		secenekler.append("SQA: " + s["isim"] + " (" + str(s["qut"]) + " QUT)")
	for s in sihirler["DQA"]:
		secenekler.append("DQA: " + s["isim"] + " (" + str(s["qut_her"]) + "x2 QUT)")

	if secenekler.is_empty():
		print("Bu karakterin sihri yok.")
		await get_tree().create_timer(0.5).timeout
		aktif_karakter_index += 1
		_sonraki_aktif_karaktere_gec()
		return

	if battle_ui:
		battle_ui.sihir_menusu_ac(secenekler, sihirler, isim, self)

func sihir_secildi(tip: String, sihir: Dictionary):
	var karakter = player_characters[aktif_karakter_index]

	# QUT kontrolü
	var k_aktif = Global.party_data[aktif_karakter_index]
	var maliyet = sihir.get("qut", sihir.get("qut_her", 0))
	var qut_gerekli = maliyet * 2 if tip == "DQA" else maliyet
	var qut_kontrol = (k_aktif.get("qut", 0) + Global.party_data[(aktif_karakter_index + 1) % Global.party_data.size()].get("qut", 0)) if tip == "DQA" else k_aktif.get("qut", 0)
	if qut_kontrol < qut_gerekli:
		print("Yetersiz QUT!")
		if battle_ui: battle_ui.sihir_paneli_kapat()
		await get_tree().create_timer(0.5).timeout
		aktif_karakter_index += 1
		_sonraki_aktif_karaktere_gec()
		return

	if battle_ui: battle_ui.sihir_paneli_kapat(false)
	_bekleyen_sihir = {"tip": tip, "sihir": sihir}

	match sihir["isim"]:
		"SaldiriSihri":
			# Hedef seçimi gerekli
			hedef_secim_goster_sihir()
		"IyilesmeSihri":
			# Parti içi hedef seçimi
			parti_hedef_sec_goster()
		"BeraberSihri":
			await _dqa_uygula(sihir)

func hedef_secim_goster_sihir():
	if battle_ui:
		battle_ui.hedef_secim_goster(dusmanlar)

# Saldırı sihri uygulandığında (hedef_secildi zaten çağrılıyor ama sihir modu kontrolü lazım)
func sihir_hedef_secildi(hedef_index: int):
	var sihir = _bekleyen_sihir.get("sihir", {})
	var karakter = player_characters[aktif_karakter_index]
	match sihir.get("isim", ""):
		"SaldiriSihri":
			var maliyet = sihir.get("qut", 30)
			Global.party_data[aktif_karakter_index]["qut"] -= maliyet
			var hasar = int(karakter["atk"] * 2.0)
			if hedef_index < dusmanlar.size():
				dusmanlar[hedef_index]["data"].hasar_al(hasar)
				_dusman_hp_guncelle(hedef_index)
				if message_box:
					message_box.visible = true
					message_box.sonuc_goster("Sihir! " + str(hasar) + " hasar!")
				if dusmanlar[hedef_index]["data"].oldu_mu():
					dusman_oldu(hedef_index)
			if battle_ui: battle_ui.stat_guncelle()
			if battle_ui: battle_ui._blur_gizle()
			await get_tree().create_timer(1.5).timeout
			aktif_karakter_index += 1
			_sonraki_aktif_karaktere_gec()

func parti_hedef_sec_goster():
	if battle_ui:
		battle_ui.parti_hedef_sec_goster(Global.party_data)

func parti_hedef_secildi(hedef_index: int):
	var sihir = _bekleyen_sihir.get("sihir", {})
	match sihir.get("isim", ""):
		"IyilesmeSihri":
			var maliyet = sihir.get("qut", 20)
			Global.party_data[aktif_karakter_index]["qut"] -= maliyet
			var k = Global.party_data[hedef_index]
			k["hp"] = min(k["hp"] + 50, k["max_hp"])
			if k.get("baygin", false) and k["hp"] > 0:
				k["baygin"] = false
			if message_box:
				message_box.visible = true
				message_box.sonuc_goster(k["isim"] + " 50 can kazandı!")
			if battle_ui: battle_ui.stat_guncelle()
			await get_tree().create_timer(1.5).timeout
			aktif_karakter_index += 1
			_sonraki_aktif_karaktere_gec()

func _dqa_uygula(sihir: Dictionary):
	var maliyet_her = sihir.get("qut_her", 25)
	if Global.current_qut < maliyet_her * 2:
		print("DQA için yeterli QUT yok!")
		if battle_ui: battle_ui.sihir_paneli_kapat()
		await get_tree().create_timer(0.5).timeout
		aktif_karakter_index += 1
		_sonraki_aktif_karaktere_gec()
		return
	if battle_ui: battle_ui.tum_panelleri_kapat()
	# DQA: her iki karakterten de tüket
	for k in Global.party_data:
		k["qut"] = max(0, k.get("qut", 0) - maliyet_her)
	if message_box:
		message_box.visible = true
		message_box.sonuc_goster("BeraberSihri! İki tur geçti.")
	if battle_ui: battle_ui.stat_guncelle()
	await get_tree().create_timer(1.5).timeout
	# İki karakterin de turu geçer - önce Ryu'yu bitir
	aktif_karakter_index += 1
	# Nina da bayğınsa veya listede yoksa direkt düşman turuna geç
	if aktif_karakter_index >= player_characters.size():
		dusman_turn_basla()
	else:
		var nina = player_characters[aktif_karakter_index]
		if nina.get("baygin", false):
			dusman_turn_basla()
		else:
			player_turn_bitir()
