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
var input_kilitli = false  # Input buffer için

var slot_labels = []

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	slot_labels = [slot1_label, slot2_label, slot3_label, iptal_label]

func _process(_delta):
	if not visible: return
	if input_kilitli: return  # Input kilitliyse işlem yapma
	
	if onay_modu:
		# Onay modundayken
		if Input.is_action_just_pressed("tus_z"):
			kayit_yap(onaylanan_slot)
			
		if Input.is_action_just_pressed("tus_x"):
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
			if secili_slot == 3:
				menuyu_kapat()
			else:
				onaylanan_slot = secili_slot + 1
				onay_sor(onaylanan_slot)
		
		if Input.is_action_just_pressed("tus_x"):
			menuyu_kapat()

func menuyu_ac(pozisyon: Vector2, sahne: String):
	kayit_noktasi_pozisyonu = pozisyon
	kayit_noktasi_sahnesi = sahne
	
	get_tree().paused = true
	visible = true
	
	secili_slot = 0
	onay_modu = false
	
	# Input kilitini aç (debounce)
	input_kilitli = true
	
	slot_bilgilerini_guncelle()
	secimi_guncelle()
	
	# Kısa bekle, sonra input'a izin ver
	await get_tree().create_timer(0.3).timeout
	input_kilitli = false

func menuyu_kapat():
	visible = false
	get_tree().paused = false
	onay_modu = false
	input_kilitli = false

func slot_bilgilerini_guncelle():
	# Slot 1
	var slot1_bilgi = Global.kayit_bilgisi_al(1)
	if slot1_bilgi["var"]:
		var sure = format_playtime(slot1_bilgi["oyun_suresi"])
		slot1_label.text = "> Slot 1: " + sure + "\n       " + str(slot1_bilgi["altin"]) + " Altın"
	else:
		slot1_label.text = "Slot 1: Boş"
	
	# Slot 2
	var slot2_bilgi = Global.kayit_bilgisi_al(2)
	if slot2_bilgi["var"]:
		var sure = format_playtime(slot2_bilgi["oyun_suresi"])
		slot2_label.text = "Slot 2: " + sure + "\n       " + str(slot2_bilgi["altin"]) + " Altın"
	else:
		slot2_label.text = "Slot 2: Boş"
	
	# Slot 3
	var slot3_bilgi = Global.kayit_bilgisi_al(3)
	if slot3_bilgi["var"]:
		var sure = format_playtime(slot3_bilgi["oyun_suresi"])
		slot3_label.text = "Slot 3: " + sure + "\n       " + str(slot3_bilgi["altin"]) + " Altın"
	else:
		slot3_label.text = "Slot 3: Boş"

func format_playtime(saniye: float) -> String:
	var toplam_saniye = int(saniye)
	var dakika = toplam_saniye / 60
	var sn = toplam_saniye % 60
	return "%d:%02d" % [dakika, sn]

func secimi_guncelle():
	for i in range(slot_labels.size()):
		var label_text = slot_labels[i].text
		
		if label_text.begins_with("> "):
			label_text = label_text.substr(2)
		
		if i == secili_slot:
			slot_labels[i].modulate = Color(1, 1, 0)  # Sarı
			slot_labels[i].text = "> " + label_text
		else:
			slot_labels[i].modulate = Color(1, 1, 1)  # Beyaz
			slot_labels[i].text = label_text

func onay_sor(slot: int):
	onay_modu = true
	var slot_bilgi = Global.kayit_bilgisi_al(slot)
	
	if slot_bilgi["var"]:
		aciklama_label.text = "Slot " + str(slot) + " üzerine yazılacak!\nEmin misin?\n\n(Z = Evet | X = Hayır)"
	else:
		aciklama_label.text = "Slot " + str(slot) + "'e kaydetmek\nister misin?\n\n(Z = Evet | X = Hayır)"

func kayit_yap(slot: int):
	Global.oyunu_kaydet(kayit_noktasi_pozisyonu, kayit_noktasi_sahnesi, slot)
	
	aciklama_label.text = "Slot " + str(slot) + "'e kaydedildi!\nHP'n tam oldu!"
	onay_modu = false
	
	slot_bilgilerini_guncelle()
	secimi_guncelle()
	
	await get_tree().create_timer(2.0).timeout
	menuyu_kapat()
