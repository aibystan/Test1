extends CanvasLayer

# --- BAĞLANTILAR ---
@onready var esya_listesi_kutusu = $SolPanel/KaydirmaKutusu/EsyaListesi
@onready var kaydirma_kutusu = $SolPanel/KaydirmaKutusu # ScrollContainer'a erişim lazım
@onready var aciklama_label = $AltPanel/AciklamaLabel

# Karakter bilgileri
@onready var isim_label = $SagPanel/KarakterBilgileri/IsimLabel
@onready var hp_label = $SagPanel/KarakterBilgileri/HPLabel
@onready var atk_label = $SagPanel/KarakterBilgileri/AtkLabel
@onready var silah_label = $SagPanel/KarakterBilgileri/SilahLabel
@onready var zirh_label = $SagPanel/KarakterBilgileri/ZirhLabel

# --- DEĞİŞKENLER ---
var secili_index = 0 # Şu an kaçıncı sıradaki eşyadayız?

func _ready():
	visible = false

func _process(_delta):
	# 1. Menüyü Açma/Kapatma (I Tuşu)
	if Input.is_action_just_pressed("inventory"):
		if visible:
			menuyu_kapat()
		else:
			menuyu_ac()
			
	# EĞER MENÜ AÇIKSA TUŞLARI DİNLE
	if visible:
		kontrol_mekanizmasi()

# --- MENÜYÜ YÖNETME ---
func menuyu_ac():
	visible = true
	secili_index = 0
	menuyu_yeniden_ciz()
	
	# OYUNU DURDUR
	get_tree().paused = true 

func menuyu_kapat():
	visible = false
	
	# OYUNU DEVAM ETTİR
	get_tree().paused = false

# --- KLAVYE KONTROLLERİ ---
func kontrol_mekanizmasi():
	# X Tuşu: Menüden Çık
	if Input.is_action_just_pressed("tus_x"):
		menuyu_kapat()
		return

	# --- KARAKTER DEĞİŞTİRME (ARTIK OK TUŞLARI) ---
	
	# SAĞ OK (Sonraki Karakter)
	if Input.is_action_just_pressed("ui_right"): 
		Global.secili_karakter_index += 1
		# Son karakteri geçersek başa dön
		if Global.secili_karakter_index >= Global.party_data.size():
			Global.secili_karakter_index = 0
		menuyu_yeniden_ciz()
		
	# SOL OK (Önceki Karakter)
	if Input.is_action_just_pressed("ui_left"):
		Global.secili_karakter_index -= 1
		# İlk karakterden geriye gidersek sona git
		if Global.secili_karakter_index < 0:
			Global.secili_karakter_index = Global.party_data.size() - 1
		menuyu_yeniden_ciz()

	# --- LİSTE KONTROLLERİ ---
	# Eğer çanta boşsa aşağı/yukarı yapmaya gerek yok, buradan dön.
	if Global.inventory.is_empty(): return

	# YUKARI / AŞAĞI HAREKET
	if Input.is_action_just_pressed("ui_up"):
		secili_index -= 1
		gorseli_guncelle()
		
	if Input.is_action_just_pressed("ui_down"):
		secili_index += 1
		gorseli_guncelle()

	# Z Tuşu: Seç / Kullan
	if Input.is_action_just_pressed("tus_z"):
		esya_kullan()

# --- GÖRSEL GÜNCELLEME ---
func menuyu_yeniden_ciz():
	# 1. Listeyi temizle (DÜZELTME BURADA)
	for cocuk in esya_listesi_kutusu.get_children():
		esya_listesi_kutusu.remove_child(cocuk) # Önce listeden at (Anında etki eder)
		cocuk.queue_free() # Sonra hafızadan silinmesi için sıraya koy

	# 2. Etiketleri oluştur (Kodun geri kalanı aynı)
	for i in range(Global.inventory.size()):
		var esya = Global.inventory[i]
		var label = Label.new()
		
		# Normal hali
		label.text = "   " + esya.isim 
		
		esya_listesi_kutusu.add_child(label)
	
	# 3. Sağ tarafı güncelle
	karakter_bilgisini_goster()
	
	# 4. İlk seçimi yap
	gorseli_guncelle()

func gorseli_guncelle():
	if Global.inventory.is_empty():
		aciklama_label.text = "Çantanız boş."
		return

	# İndeksi sınırla (Listenin dışına çıkmasın)
	# clamp fonksiyonu sayıyı min ve max arasında tutar
	secili_index = clamp(secili_index, 0, Global.inventory.size() - 1)
	
	# Tüm listedeki yazıların rengini ve şeklini ayarla
	var cocuklar = esya_listesi_kutusu.get_children()
	
	for i in range(cocuklar.size()):
		var label = cocuklar[i]
		
		if i == secili_index:
			# SEÇİLİ OLAN (Sarı ve Ok İşaretli)
			label.text = "> " + Global.inventory[i].isim
			label.modulate = Color(1, 1, 0) # Sarı Renk
			
			# Otomatik Kaydırma (Listede aşağı inince ekran kaysın)
			ensure_visible(label)
			
			# Açıklamayı güncelle
			aciklama_label.text = Global.inventory[i].aciklama
		else:
			# SEÇİLİ OLMAYAN (Beyaz ve Boşluklu)
			label.text = "   " + Global.inventory[i].isim
			label.modulate = Color(1, 1, 1) # Beyaz Renk

# ScrollContainer'ın seçili eşyayı göstermesini sağlar
func ensure_visible(control: Control):
	# Basit bir matematik ile scroll bar'ı kaydırıyoruz
	var fark = control.position.y - kaydirma_kutusu.scroll_vertical
	if fark < 0:
		kaydirma_kutusu.scroll_vertical += fark
	elif fark + control.size.y > kaydirma_kutusu.size.y:
		kaydirma_kutusu.scroll_vertical += fark + control.size.y - kaydirma_kutusu.size.y

# --- EYLEMLER ---
func esya_kullan():
	if Global.inventory.is_empty(): return
	var secilen_esya = Global.inventory[secili_index]
	var suanki_karakter_ismi = Global.party_data[Global.secili_karakter_index]["isim"]
	
	# --- YENİ KONTROL: Karakter bu eşyayı kullanabilir mi? ---
	# Eğer liste doluysa (özel eşyaysa) VE ismimiz listede yoksa...
	if not secilen_esya.kullanabilir_karakterler.is_empty() and not suanki_karakter_ismi in secilen_esya.kullanabilir_karakterler:
		aciklama_label.text = "Bunu " + suanki_karakter_ismi + " kullanamaz!"
		# Hata sesi çal (Opsiyonel)
		return # İşlemi iptal et

	# --- DURUM A: YİYECEKSE ---
	if secilen_esya.tur == ItemData.Tip.TUKETILEBILIR:
		# Sesi Çal (İleride)
		# Global fonksiyonunu çağır
		Global.karakteri_iyilestir(secilen_esya.etki_degeri)
		
		# Eşyayı çantadan sil (Önemli: remove_at kullanıyoruz ki doğru olan silinsin)
		Global.inventory.remove_at(secili_index)
		
		# Mesaj ver
		aciklama_label.text = secilen_esya.isim + " kullanıldı ve can yenilendi!"

	# --- DURUM B: SİLAH VEYA ZIRHSA ---
	elif secilen_esya.tur == ItemData.Tip.SILAH or secilen_esya.tur == ItemData.Tip.ZIRH:
		# Global'e gönder ve varsa eski eşyayı geri al
		var cikarilan_esya = Global.esya_kusan(secilen_esya)
		
		# 1. Yeni eşyayı çantadan sil
		Global.inventory.remove_at(secili_index)
		
		# 2. Eğer üzerimizden eski bir eşya çıktıysa, onu çantaya geri koy
		if cikarilan_esya != null:
			Global.inventory.append(cikarilan_esya)
			aciklama_label.text = secilen_esya.isim + " kuşandı. " + cikarilan_esya.isim + " çantaya döndü."
		else:
			aciklama_label.text = secilen_esya.isim + " kuşandı."

	# 3. Her şey bitince menüyü tazele (Listeyi ve Statları güncelle)
	# Eğer son eşyayı sildiysek hata vermemesi için indeksi düzelt
	if secili_index >= Global.inventory.size():
		secili_index = max(0, Global.inventory.size() - 1)
		
	menuyu_yeniden_ciz()

# --- SAĞ PANEL (Aynı kaldı) ---
func karakter_bilgisini_goster():
	var karakter = Global.party_data[Global.secili_karakter_index]
	
	# İsim kısmına ok işaretleri ekle
	isim_label.text = "< " + karakter["isim"] + " >"
	
	# --- HESAPLAMA KISMI ---
	# Toplam Saldırı = Kendi Gücü + Silah Gücü
	var toplam_atk = karakter["atk"]
	if karakter["silah"] != null:
		toplam_atk += karakter["silah"].etki_degeri
		
	# (İstersen defans için de aynısını yapabilirsin)
	
	# --- YAZDIRMA KISMI ---
	isim_label.text = karakter["isim"]
	hp_label.text = "HP: %d/%d" % [karakter["hp"], karakter["max_hp"]]
	
	# Artık toplam gücü yazdırıyoruz
	atk_label.text = "SALDIRI: %d" % toplam_atk 
	
	if karakter["silah"]: silah_label.text = "Silah: " + karakter["silah"].isim
	else: silah_label.text = "Silah: Yok"
		
	if karakter["zirh"]: zirh_label.text = "Zırh: " + karakter["zirh"].isim
	else: zirh_label.text = "Zırh: Yok"

func ses_cal(tur):
	# İleride buraya ses efekti eklersin
	pass
