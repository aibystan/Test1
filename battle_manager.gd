extends Node
class_name BattleManager

# --- SİNYALLER ---
signal turn_basladi(karakter_index: int)
signal turn_bitti
signal dusman_turn_basladi
signal savas_bitti(kazanildi: bool)

# --- REFERANSLAR ---
var battle_ui: Control
var grid_node: Node2D
var player_node: Area2D

# --- DÜŞMANLAR ---
var dusmanlar: Array = []  # {data: EnemyData, node: Node2D}
var aktif_dusman_sayisi: int = 0

# --- TURN SİSTEMİ ---
enum TurnDurumu {PLAYER_1, PLAYER_2, DUSMAN, BEKLEME}
var suanki_durum: TurnDurumu = TurnDurumu.BEKLEME
var aktif_karakter_index: int = 0

# --- PLAYER DATA ---
var player_characters: Array = []  # Global.party_data'dan

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func savas_baslat(dusman_listesi: Array):
	print("Savaş Başladı!")
	
	# Player karakterleri yükle
	player_characters = Global.party_data.duplicate(true)
	
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
	# Düşman container oluştur
	var dusman_container = Node2D.new()
	dusman_container.position = Vector2(700 + (index * 120), 200)  # Daha sağda ve yukarıda
	
	# Düşman görsel (ColorRect) - DAHA KÜÇÜK
	var dusman_node = ColorRect.new()
	dusman_node.custom_minimum_size = Vector2(80, 80)  # Sabit boyut
	dusman_node.size = Vector2(80, 80)
	dusman_node.color = dusman.renk
	
	# İsim label ekle
	var label = Label.new()
	label.text = dusman.isim + "\nHP: " + str(dusman.current_hp)
	label.position = Vector2(0, 90)  # Altına yaz
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dusman_container.add_child(label)
	
	dusman_container.add_child(dusman_node)
	get_parent().add_child(dusman_container)
	
	return dusman_container

func ilk_player_turn_basla():
	if player_characters.size() > 0:
		aktif_karakter_index = 0
		player_turn_basla()

func player_turn_basla():
	suanki_durum = TurnDurumu.PLAYER_1 if aktif_karakter_index == 0 else TurnDurumu.PLAYER_2
	turn_basladi.emit(aktif_karakter_index)
	
	# UI'ye turn başladığını bildir
	if battle_ui:
		battle_ui.turn_menusu_goster(player_characters[aktif_karakter_index])

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
	# Şimdilik sabit hasar (Timing bar gelince burası değişecek)
	var karakter = player_characters[aktif_karakter_index]
	var damage = karakter["atk"]
	
	if hedef_index < dusmanlar.size():
		var dusman_dict = dusmanlar[hedef_index]
		dusman_dict["data"].hasar_al(damage)
		
		# HP label güncelle
		if dusman_dict["node"].has_node("Label"):
			var label = dusman_dict["node"].get_node("Label")
			label.text = dusman_dict["data"].isim + "\nHP: " + str(dusman_dict["data"].current_hp)
		
		print(dusman_dict["data"].isim + " " + str(damage) + " hasar aldı!")
		
		# Öldü mü?
		if dusman_dict["data"].oldu_mu():
			dusman_oldu(hedef_index)
	
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
	dusman_turn_basladi.emit()
	
	print("Düşman saldırıyor!")
	
	for dusman_dict in dusmanlar:
		if not dusman_dict["data"].oldu_mu():
			print(dusman_dict["data"].isim + ": Grrrr!")
	
	
	await get_tree().create_timer(3.0).timeout
	
	dusman_turn_bitir()

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
