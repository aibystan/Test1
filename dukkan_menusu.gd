extends CanvasLayer

# --- BAĞLANTILAR ---
@onready var esya_listesi_kutusu = $SolPanel/KaydirmaKutusu/EsyaListesi
@onready var aciklama_label = $AltPanel/AciklamaLabel
@onready var altin_label = $SagPanel/AltinLabel

# --- DEĞİŞKENLER ---
var satilik_esyalar: Array[ItemData] = []
var secili_index = 0
var input_kilitli = false

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func dukkani_ac(urunler_listesi: Array[ItemData]):
	satilik_esyalar = urunler_listesi
	visible = true
	secili_index = 0
	get_tree().paused = true
	menuyu_yeniden_ciz()
	
	# Bekleme süresi (Debounce)
	input_kilitli = true
	await get_tree().create_timer(0.2).timeout
	input_kilitli = false

func menuyu_kapat():
	visible = false
	get_tree().paused = false

func _process(_delta):
	if not visible: return
	if input_kilitli: return

	# ÇIKIŞ
	if Input.is_action_just_pressed("tus_x"):
		menuyu_kapat()

	# MENÜ KONTROLLERİ
	if satilik_esyalar.is_empty(): return

	if Input.is_action_just_pressed("ui_up"):
		secili_index = max(0, secili_index - 1)
		menuyu_yeniden_ciz()
		
	if Input.is_action_just_pressed("ui_down"):
		secili_index = min(satilik_esyalar.size() - 1, secili_index + 1)
		menuyu_yeniden_ciz()

	# SATIN ALMA (Z Tuşu)
	if Input.is_action_just_pressed("tus_z"):
		esya_satin_al()

func menuyu_yeniden_ciz():
	print("Menü çiziliyor! Ürün sayısı: ", satilik_esyalar.size())
	# 1. TEMİZLİK
	for cocuk in esya_listesi_kutusu.get_children():
		if cocuk.name != "SablonLabel":
			cocuk.queue_free()
		
	# 2. LİSTEYI OLUŞTUR
	var sablon = esya_listesi_kutusu.get_node("SablonLabel")
	
	for i in range(satilik_esyalar.size()):
		var esya = satilik_esyalar[i]
		var yeni_label = sablon.duplicate()
		yeni_label.visible = true 
		
		var metin = esya.isim + " (" + str(esya.fiyat) + " G)"
		
		if i == secili_index:
			yeni_label.text = "> " + metin
			yeni_label.modulate = Color(1, 1, 0) # Sarı
			aciklama_label.text = esya.aciklama
		else:
			yeni_label.text = "   " + metin
			yeni_label.modulate = Color(1, 1, 1) # Beyaz
			
		esya_listesi_kutusu.add_child(yeni_label)
		print("Eklendi: ", esya.isim)
		
	# 3. PARAYI GÖSTER
	altin_label.text = "Paranız: " + str(Global.altin) + " G"

func esya_satin_al():
	var secilen_esya = satilik_esyalar[secili_index]
	
	# 1. ENVANTER KAPASİTE KONTROLÜ (YENİ!)
	if Global.envanter_dolu_mu():
		aciklama_label.text = "Envanteriniz dolu! Yer açın."
		# Hata sesi çal (opsiyonel)
		return
	
	# 2. PARA KONTROLÜ
	if Global.altin >= secilen_esya.fiyat:
		# Parayı düş
		Global.altin -= secilen_esya.fiyat
		
		# Eşyayı çantaya at (yeni fonksiyonla)
		Global.envantere_ekle(secilen_esya)
		
		# Mesaj ver ve güncelle
		aciklama_label.text = "Satın alındı: " + secilen_esya.isim
		menuyu_yeniden_ciz()
		# Kasa sesi çal (Chaching!) 
	else:
		aciklama_label.text = "Yetersiz Bakiye! Paran yetmiyor."
		# Hata sesi çal
