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
	print("=== DÜKKAN AÇILIYOR ===")
	print("Ürün sayısı: ", urunler_listesi.size())
	
	satilik_esyalar = urunler_listesi
	visible = true
	secili_index = 0
	get_tree().paused = true
	
	# Input'u hemen kilitle
	input_kilitli = true
	
	# Kısa bekleme - scene tam yüklenmesi için
	await get_tree().create_timer(0.1).timeout
	
	menuyu_yeniden_ciz()
	
	# Daha uzun input debounce - Z tuşu serbest kalması için
	await get_tree().create_timer(0.5).timeout
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
	print("=== MENÜ ÇİZİLİYOR ===")
	print("Ürün sayısı: ", satilik_esyalar.size())
	
	# 1. TEMİZLİK
	for cocuk in esya_listesi_kutusu.get_children():
		if cocuk.name != "SablonLabel":
			cocuk.queue_free()
	
	# 2. ŞABLON KONTROLÜ
	if not esya_listesi_kutusu.has_node("SablonLabel"):
		print("HATA: SablonLabel bulunamadı!")
		return
		
	var sablon = esya_listesi_kutusu.get_node("SablonLabel")
		
	# 3. LİSTEYI OLUŞTUR
	for i in range(satilik_esyalar.size()):
		var esya = satilik_esyalar[i]
		
		var yeni_label = sablon.duplicate()
		yeni_label.name = "Urun_" + str(i)
		yeni_label.visible = true 
		
		var metin = esya.isim + " (" + str(esya.fiyat) + " G)"
		
		if i == secili_index:
			yeni_label.text = "> " + metin
			yeni_label.modulate = Color(1, 1, 0) # Sarı
			
			# Açıklama - RichTextLabel desteği
			if aciklama_label is RichTextLabel:
				aciklama_label.clear()
				aciklama_label.append_text(esya.aciklama)
			else:
				aciklama_label.text = esya.aciklama
		else:
			yeni_label.text = "   " + metin
			yeni_label.modulate = Color(1, 1, 1) # Beyaz
			
		esya_listesi_kutusu.add_child(yeni_label)
		print("✓ Eklendi: ", esya.isim)
		
	# 4. PARAYI GÖSTER
	altin_label.text = "Paranız: " + str(Global.altin) + " G"
	print("=== ÇİZİM TAMAMLANDI ===")

func esya_satin_al():
	if secili_index >= satilik_esyalar.size():
		return
		
	var secilen_esya = satilik_esyalar[secili_index]
	
	# 1. ENVANTER KONTROLÜ
	if Global.envanter_dolu_mu():
		mesaj_goster("Envanteriniz dolu! Yer açın.")
		return
	
	# 2. PARA KONTROLÜ
	if Global.altin >= secilen_esya.fiyat:
		Global.altin -= secilen_esya.fiyat
		Global.envantere_ekle(secilen_esya)
		mesaj_goster("Satın alındı: " + secilen_esya.isim)
		menuyu_yeniden_ciz()
	else:
		mesaj_goster("Yetersiz Bakiye! Paran yetmiyor.")

func mesaj_goster(mesaj: String):
	if aciklama_label is RichTextLabel:
		aciklama_label.clear()
		aciklama_label.append_text(mesaj)
	else:
		aciklama_label.text = mesaj
