extends StaticBody2D

@export var isim: String = "Old Sign"
@export var giris_mesajlari: Array[String] = ["Ne yapmak istersin?"]
@export var secenekler: Array[DialogSecenek] = []

func etkilesime_gec():
	var diyalog = get_tree().current_scene.find_child("DiyalogKutusu")
	if not diyalog:
		print("HATA: DiyalogKutusu bulunamadı!")
		return

	# Seçenek yoksa sadece diyalog göster
	if secenekler.is_empty():
		diyalog.baslat(isim, giris_mesajlari)
		return

	# Seçenek varsa giriş mesajından sonra seçenekleri aç
	diyalog.baslat(isim, giris_mesajlari, _secenekleri_goster.bind(diyalog))

func _secenekleri_goster(diyalog):
	var secenek_listesi = []
	for s in secenekler:
		var mesajlar = s.cevap_mesajlari.duplicate()
		secenek_listesi.append({
			"metin": s.secenek_metni,
			"callback": func(): diyalog.baslat(isim, mesajlar)
		})
	diyalog.secenekleri_goster(secenek_listesi)
