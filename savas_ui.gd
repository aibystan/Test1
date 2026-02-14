extends CanvasLayer

# --- SİNYALLER ---
signal oyuncu_saldiriyor
signal tur_bitti # İki karakter de oynayınca bu sinyal gider

# --- NODE REFERANSLARI ---
@onready var secim_oku = $MainControl/SecimOku
@onready var buton_kutusu = $MainControl/ButonKonteyner
# Karakter Panelleri
@onready var panel_p1 = $MainControl/PanelKarakter1
@onready var panel_p2 = $MainControl/PanelKarakter2

# --- DEĞİŞKENLER ---
var secili_index = 0 # 0: Saldır, 1: Sihir ... 4: İnsaf
var buton_sayisi = 5
var su_anki_karakter = 1 # 1 veya 2
var p1_aksiyonu_hazir = false # P1 seçim yaptı mı?

# Butonların X koordinatlarını tutacağız
var buton_pozisyonlari = []

func _ready():
	# Butonların yerlerini kaydet (Okun gitmesi için)
	# Bir frame bekliyoruz ki UI tam yerleşsin
	await get_tree().process_frame
	
	for buton in buton_kutusu.get_children():
		# Butonun global merkezini al
		var merkez_x = buton.global_position.x + (buton.size.x / 2)
		buton_pozisyonlari.append(merkez_x)
	
	# İlk durumu ayarla
	ok_pozisyonunu_guncelle()
	karakter_gorselini_guncelle()

func _input(event):
	# Eğer UI aktif değilse (Düşman turundaysak) tuşları dinleme
	if not visible: return

	# --- SAĞ / SOL HAREKET ---
	if event.is_action_pressed("ui_right"):
		secili_index = (secili_index + 1) % buton_sayisi
		ok_pozisyonunu_guncelle()
		
	elif event.is_action_pressed("ui_left"):
		secili_index = (secili_index - 1)
		if secili_index < 0: secili_index = buton_sayisi - 1
		ok_pozisyonunu_guncelle()

	# --- SEÇİM YAPMA (Z TUŞU) ---
	elif event.is_action_pressed("tus_z"): # ui_accept
		secim_yap()

	# --- GERİ GELME (X TUŞU) ---
	elif event.is_action_pressed("tus_x"): # ui_cancel
		if su_anki_karakter == 2:
			# Karakter 2'den vazgeçtik, Karakter 1'e dön
			print("Karakter 2 iptal edildi, Karakter 1'e dönüldü.")
			su_anki_karakter = 1
			p1_aksiyonu_hazir = false
			karakter_gorselini_guncelle()
			# Oku sıfırla veya kaldığı yere getir
			secili_index = 0 
			ok_pozisyonunu_guncelle()

func ok_pozisyonunu_guncelle():
	if buton_pozisyonlari.size() > 0:
		var hedef_x = buton_pozisyonlari[secili_index]
		# Oku butonun altına koy (Y'yi kendi sahnene göre ayarla)
		var hedef_y = buton_kutusu.global_position.y + 60 
		
		# Animasyonlu geçiş (Tween)
		var tween = create_tween()
		tween.tween_property(secim_oku, "position", Vector2(hedef_x, hedef_y), 0.1)

func karakter_gorselini_guncelle():
	# Görseldeki gibi: Aktif karakter öne çıkar, diğeri kararır ve arkada kalır.
	if su_anki_karakter == 1:
		# P1 Aktif, P2 Pasif
		panel_p1.modulate = Color(1, 1, 1, 1) # Tam parlak
		panel_p1.z_index = 1 # Önde
		
		panel_p2.modulate = Color(0.5, 0.5, 0.5, 1) # Gri/Karanlık
		panel_p2.z_index = 0 # Arkada
		# Panel 2'yi biraz sola/yukarı kaydırabilirsin efekt için
		
	elif su_anki_karakter == 2:
		# P2 Aktif, P1 Beklemede
		panel_p2.modulate = Color(1, 1, 1, 1)
		panel_p2.z_index = 1
		
		panel_p1.modulate = Color(0.5, 0.5, 0.5, 1)
		panel_p1.z_index = 0

func secim_yap():
	print("Karakter " + str(su_anki_karakter) + " Seçti: Kutu " + str(secili_index + 1))
	
	if su_anki_karakter == 1:
		# P1 seçimini yaptı, şimdi P2'ye geç
		p1_aksiyonu_hazir = true
		su_anki_karakter = 2
		karakter_gorselini_guncelle()
		secili_index = 0 # Oku başa al
		ok_pozisyonunu_guncelle()
		
	elif su_anki_karakter == 2:
		# P2 de seçimini yaptı, artık saldırı başlasın!
		print("Tüm seçimler yapıldı! Tur oynanıyor...")
		# Menüyü gizle
		visible = false 
		# Sinyal gönder (SavasSahnesi bunu yakalayacak)
		emit_signal("tur_bitti") 
		
		# Burada aksiyonları sıraya koyup oynatacağız.
		# Şimdilik direkt düşman turuna geçişi simüle edelim.

# Düşman turu bitince bu fonksiyon çağrılacak
func yeni_tur_baslat():
	visible = true
	su_anki_karakter = 1
	p1_aksiyonu_hazir = false
	secili_index = 0
	karakter_gorselini_guncelle()
	ok_pozisyonunu_guncelle()
