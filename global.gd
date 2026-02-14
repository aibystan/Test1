extends Node

var max_hp = 100
var current_hp = 100

var max_qut = 200
var current_qut = 200

var graze_points = 0

var parti_uyeleri = ["Ryu", "Nina"]

var inventory: Array[ItemData] = []
var party_data = [
	# 1. Karakter (Örn: Savaşçı)
	{
		"isim": "Ryu", # Breath of Fire göndermesi ;)
		"hp": 100,
		"max_hp": 100,
		"atk": 15,
		"def": 10,
		"silah": null, # Kuşandığı silah (ItemData olacak)
		"zirh": null   # Kuşandığı zırh
	},
	# 2. Karakter (Örn: Büyücü/Okçu)
	{
		"isim": "Nina",
		"hp": 70,
		"max_hp": 70,
		"atk": 25,
		"def": 5,
		"silah": null,
		"zirh": null
	}
]

# Hangi karakterin statlarına bakıyoruz? (0 = Ryu, 1 = Nina)
var secili_karakter_index = 0 

# ... (Kaydet/Yükle fonksiyonları aşağıda devam ediyor) ...
# --- DEĞİŞKENLER ---
var gidilecek_kapi_ismi = "" 
var yuklenen_pozisyon = null # Oyun yüklenince nerede doğacağız?

# --- EKONOMİ ---
var altin: int = 500 # Oyuna zengin başlayalım :)

# Kayıt dosyasının yolu (Bilgisayarın gizli klasörlerine kaydeder)
const KAYIT_DOSYASI = "user://oyun_kaydi.save"

# --- KAYDETME FONKSİYONU ---
func oyunu_kaydet(oyuncu_pozisyonu, sahne_yolu):
	# 1. Kaydedilecek verileri sözlük (Dictionary) yap
	var veriler = {
		"poz_x": oyuncu_pozisyonu.x,
		"poz_y": oyuncu_pozisyonu.y,
		"sahne": sahne_yolu
	}
	
	# 2. Dosyayı yazmak için aç
	var dosya = FileAccess.open(KAYIT_DOSYASI, FileAccess.WRITE)
	
	# 3. Veriyi JSON (Metin) formatına çevirip kaydet
	var json_veri = JSON.stringify(veriler)
	dosya.store_line(json_veri)
	
	print("Oyun Kaydedildi! Veri: ", json_veri)

# --- YÜKLEME FONKSİYONU ---
func oyunu_yukle():
	# 1. Dosya var mı diye bak
	if not FileAccess.file_exists(KAYIT_DOSYASI):
		print("Kayıt dosyası bulunamadı!")
		return # Yoksa iptal et

	# 2. Dosyayı okumak için aç
	var dosya = FileAccess.open(KAYIT_DOSYASI, FileAccess.READ)
	
	# 3. Satırı oku ve JSON'dan geri çevir
	var json_veri = dosya.get_line()
	var veriler = JSON.parse_string(json_veri)
	
	# 4. Verileri uygula
	if veriler:
		# Yüklenecek pozisyonu hafızaya al (Player sahne açılınca bunu okuyacak)
		yuklenen_pozisyon = Vector2(veriler["poz_x"], veriler["poz_y"])
		
		# Sahneyi değiştir (Gecis sistemiyle)
		# Not: Gecis singleton'ını kullandığımız için hata verirse başına Gecis. koy
		Gecis.sahne_degistir(veriler["sahne"]) 
		print("Oyun Yüklendi!")
func _ready():
	# TEST: Oyun başlarken envantere eşya ekleyelim.
	# load() komutuyla yaptığımız .tres dosyalarını yüklüyoruz.
	
	# Eğer "Items" klasörü yaptıysan yolları ona göre ayarla:
	var elma = load("res://Items/elma.tres") 
	var kilic = load("res://Items/pasli_kilic.tres")
	
	if elma and kilic:
		inventory.append(elma)
		inventory.append(elma) # İki elmamız olsun
		inventory.append(kilic)
		print("Test eşyaları envantere eklendi! Toplam: ", inventory.size())
	else:
		print("HATA: Eşya dosyaları bulunamadı! Yolları kontrol et.")
		
# ... (Global dosyasının üst kısımları) ...

# --- EŞYA KULLANIM FONKSİYONLARI ---

# 1. Can Doldurma
func karakteri_iyilestir(miktar):
	var karakter = party_data[secili_karakter_index] # party_data BURADA tanımlı olduğu için hata vermez
	
	karakter["hp"] += miktar
	if karakter["hp"] > karakter["max_hp"]:
		karakter["hp"] = karakter["max_hp"]
		
	print(karakter["isim"] + " iyileşti. Yeni HP: " + str(karakter["hp"]))

# 2. Ekipman Değiştirme
func esya_kusan(yeni_esya: ItemData) -> ItemData:
	var karakter = party_data[secili_karakter_index]
	var eski_esya = null
	
	if yeni_esya.tur == ItemData.Tip.SILAH:
		eski_esya = karakter["silah"]
		karakter["silah"] = yeni_esya
	elif yeni_esya.tur == ItemData.Tip.ZIRH:
		eski_esya = karakter["zirh"]
		karakter["zirh"] = yeni_esya
		
	print(karakter["isim"] + " kuşandı: " + yeni_esya.isim)
	return eski_esya
