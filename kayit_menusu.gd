extends CanvasLayer

@onready var slot1_label = $Panel/VBoxContainer/Slot1
@onready var slot2_label = $Panel/VBoxContainer/Slot2
@onready var slot3_label = $Panel/VBoxContainer/Slot3
@onready var iptal_label = $Panel/VBoxContainer/IptalButton
@onready var aciklama_label = $Panel/VBoxContainer/Aciklama

var kayit_noktasi_pozisyonu: Vector2
var kayit_noktasi_sahnesi: String
var secili_slot = 0  # 0-3: slot1, slot2, slot3, iptal
var onay_modu = false
var onaylanan_slot = 0

var slot_labels = []

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Label'ları diziye koy
	slot_labels = [slot1_label, slot2_label, slot3_label, iptal_label]

func _process(_delta):
	if not visible: return
	
	if onay_modu:
		# Onay modundayken
		if Input.is_action_just_pressed("tus_z"):
			# Evet - Kaydet
			kayit_yap(onaylanan_slot)
			
		if Input.is_action_just_pressed("tus_x"):
			# Hayır - İptal
			onay_modu = false
			aciklama_label.text = "Oyununu kaydetmek ister misin?\nHP'n tam olacak!"
			secimi_guncelle()
	else:
		# Normal mod - slot seçimi
		if Input.is_action_just_pressed("ui_up"):
			secili_slot -= 1
			if secili_slot < 0:
				secili_slot = 3
			secimi_guncelle()
			
		if Input.is_action_just_pressed("ui_down"):
			secili_slot += 1
			if secili_slot > 3:
				secili_slot = 0
			secimi_guncelle()
		
		if Input.is_action_just_pressed("tus_z"):
			# Z ile seç
			if secili_slot == 3:
				# İptal seçildi
				menuyu_kapat()
			else:
				# Slot seçildi - onay iste
				onaylanan_slot = secili_slot + 1
				onay_sor(onaylanan_slot)
		
		if Input.is_action_just_pressed("tus_x"):
			# X ile kapat
			menuyu_kapat()

func menuyu_ac(pozisyon: Vector2, sahne: String):
	kayit_noktasi_pozisyonu = pozisyon
	kayit_noktasi_sahnesi = sahne
	
	get_tree().paused = true
	visible = true
	
	secili_slot = 0
	onay_modu = false
	
	slot_bilgilerini_guncelle()
	secimi_guncelle()

func menuyu_kapat():
	visible = false
	get_tree().paused = false
	onay_modu = false

func slot_bilgilerini_guncelle():
	# Slot 1
	var slot1_bilgi = Global.kayit_bilgisi_al(1)
	if slot1_bilgi["var"]:
		var zaman_str = str(slot1_bilgi["zaman"])  # String'e çevir
		var zaman_parcalari = zaman_str.split(" ")
		var saat = zaman_parcalari[1] if zaman_parcalari.size() > 1 else zaman_str
		slot1_label.text = "Slot 1: " + saat + "\n       " + str(slot1_bilgi["altin"]) + " Altın"
	else:
		slot1_label.text = "Slot 1: Boş"
	
	# Slot 2
	var slot2_bilgi = Global.kayit_bilgisi_al(2)
	if slot2_bilgi["var"]:
		var zaman_str = str(slot2_bilgi["zaman"])
		var zaman_parcalari = zaman_str.split(" ")
		var saat = zaman_parcalari[1] if zaman_parcalari.size() > 1 else zaman_str
		slot2_label.text = "Slot 2: " + saat + "\n       " + str(slot2_bilgi["altin"]) + " Altın"
	else:
		slot2_label.text = "Slot 2: Boş"
	
	# Slot 3
	var slot3_bilgi = Global.kayit_bilgisi_al(3)
	if slot3_bilgi["var"]:
		var zaman_str = str(slot3_bilgi["zaman"])
		var zaman_parcalari = zaman_str.split(" ")
		var saat = zaman_parcalari[1] if zaman_parcalari.size() > 1 else zaman_str
		slot3_label.text = "Slot 3: " + saat + "\n       " + str(slot3_bilgi["altin"]) + " Altın"
	else:
		slot3_label.text = "Slot 3: Boş"

func secimi_guncelle():
	# Tüm seçimleri beyaz yap, seçiliyi sarı
	for i in range(slot_labels.size()):
		var label_text = slot_labels[i].text
		
		# ">" işaretini kaldır
		if label_text.begins_with("> "):
			label_text = label_text.substr(2)
		
		if i == secili_slot:
			slot_labels[i].modulate = Color(1, 1, 0)  # Sarı - seçili
			slot_labels[i].text = "> " + label_text
		else:
			slot_labels[i].modulate = Color(1, 1, 1)  # Beyaz
			slot_labels[i].text = label_text

func onay_sor(slot: int):
	onay_modu = true
	
	# Slot bilgisi
	var slot_bilgi = Global.kayit_bilgisi_al(slot)
	
	if slot_bilgi["var"]:
		# Dolu slot - üzerine yazma uyarısı
		aciklama_label.text = "Slot " + str(slot) + " üzerine yazılacak!\nEmin misin?\n\n(Z = Evet | X = Hayır)"
	else:
		# Boş slot - normal onay
		aciklama_label.text = "Slot " + str(slot) + "'e kaydetmek\nister misin?\n\n(Z = Evet | X = Hayır)"

func kayit_yap(slot: int):
	# Kaydet
	Global.oyunu_kaydet(kayit_noktasi_pozisyonu, kayit_noktasi_sahnesi, slot)
	
	# Başarı mesajı
	aciklama_label.text = "Slot " + str(slot) + "'e kaydedildi!\nHP'n tam oldu!"
	onay_modu = false
	
	# Slot bilgilerini güncelle
	slot_bilgilerini_guncelle()
	secimi_guncelle()
	
	# Bekle ve kapat
	await get_tree().create_timer(2.0).timeout
	menuyu_kapat()
