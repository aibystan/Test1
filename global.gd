extends Node

var max_hp = 100
var current_hp = 100

var max_qut = 200
var current_qut = 200

var graze_points = 0

var parti_uyeleri = ["Ryu", "Nina"]

# --- ENVANTER SİSTEMİ ---
var inventory: Array[ItemData] = []
var MAX_ENVANTER_KAPASITESI = 14

var party_data = [
	{
		"isim": "Ryu",
		"hp": 100,
		"max_hp": 100,
		"atk": 15,
		"def": 10,
		"qut": 200,
		"max_qut": 200,
		"silah": null,
		"zirh": null,
		"baygin": false
	},
	{
		"isim": "Nina",
		"hp": 70,
		"max_hp": 70,
		"atk": 25,
		"def": 5,
		"qut": 200,
		"max_qut": 200,
		"silah": null,
		"zirh": null,
		"baygin": false
	}
]

# Deltarune tarzı hasar dağıtıcı
# Hasar önce aktif karakterden alınır, taşarsa diğerine geçer
func parti_hasar_al(miktar: int, baslangic_index: int = 0) -> Array:
	var etkilenenler = []
	var kalan = miktar
	var i = baslangic_index
	var deneme = 0
	
	while kalan > 0 and deneme < party_data.size():
		var k = party_data[i % party_data.size()]
		if not k["baygin"]:
			var alinacak = min(kalan, k["hp"])
			k["hp"] -= alinacak
			kalan -= alinacak
			etkilenenler.append({"isim": k["isim"], "hasar": alinacak})
			if k["hp"] <= 0:
				k["hp"] = 0
				k["baygin"] = true
		i = (i + 1) % party_data.size()
		deneme += 1
	
	return etkilenenler

var secili_karakter_index = 0 
var gidilecek_kapi_ismi = "" 
var yuklenen_pozisyon = null

# --- EKONOMİ ---
var altin: int = 500

# --- KAYIT SİSTEMİ (3 SLOT) ---
const KAYIT_DOSYASI_1 = "user://oyun_kaydi_slot1.save"
const KAYIT_DOSYASI_2 = "user://oyun_kaydi_slot2.save"
const KAYIT_DOSYASI_3 = "user://oyun_kaydi_slot3.save"

# --- ENVANTER FONKSİYONLARI ---
func envantere_ekle(esya: ItemData) -> bool:
	if inventory.size() >= MAX_ENVANTER_KAPASITESI:
		print("ENVANTER DOLU! Eşya eklenemedi: ", esya.isim)
		return false
	inventory.append(esya)
	print("Envantere eklendi: ", esya.isim, " (", inventory.size(), "/", MAX_ENVANTER_KAPASITESI, ")")
	return true

func envanterden_cikar(index: int):
	if index >= 0 and index < inventory.size():
		var esya = inventory[index]
		inventory.remove_at(index)
		print("Envanterden çıkarıldı: ", esya.isim)

func envanter_dolu_mu() -> bool:
	return inventory.size() >= MAX_ENVANTER_KAPASITESI

func bos_slot_sayisi() -> int:
	return MAX_ENVANTER_KAPASITESI - inventory.size()

# --- GELİŞMİŞ KAYDETME FONKSİYONU ---
func oyunu_kaydet(oyuncu_pozisyonu: Vector2, sahne_yolu: String, slot: int = 1):
	# Tüm karakterlerin canını full yap
	for karakter in party_data:
		karakter["hp"] = karakter["max_hp"]
	
	# Envanter verisini hazırla (ItemData'yı path olarak kaydet)
	var envanter_kaydi = []
	for esya in inventory:
		envanter_kaydi.append(esya.resource_path)
	
	# Party verilerini hazırla
	var party_kaydi = []
	for karakter in party_data:
		var karakter_verisi = {
			"isim": karakter["isim"],
			"hp": karakter["hp"],
			"max_hp": karakter["max_hp"],
			"atk": karakter["atk"],
			"def": karakter["def"],
			"silah": karakter["silah"].resource_path if karakter["silah"] else null,
			"zirh": karakter["zirh"].resource_path if karakter["zirh"] else null
		}
		party_kaydi.append(karakter_verisi)
	
	# Tam veri paketi
	var veriler = {
		"poz_x": oyuncu_pozisyonu.x,
		"poz_y": oyuncu_pozisyonu.y,
		"sahne": sahne_yolu,
		"altin": altin,
		"qut": current_qut,  # Qut kaydediliyor (HP kaydedilmiyor çünkü full oluyor)
		"graze": graze_points,
		"envanter": envanter_kaydi,
		"party": party_kaydi,
		"secili_karakter": secili_karakter_index,
		"kayit_zamani": Time.get_datetime_string_from_system()
	}
	
	# Slot'a göre dosya seç
	var dosya_yolu = KAYIT_DOSYASI_1
	if slot == 2:
		dosya_yolu = KAYIT_DOSYASI_2
	elif slot == 3:
		dosya_yolu = KAYIT_DOSYASI_3
	
	# Kaydet
	var dosya = FileAccess.open(dosya_yolu, FileAccess.WRITE)
	var json_veri = JSON.stringify(veriler)
	dosya.store_line(json_veri)
	
	print("Oyun Kaydedildi! Slot: ", slot, " Zaman: ", veriler["kayit_zamani"])
	return true

# --- KAYIT VARMI KONTROLÜ ---
func kayit_var_mi(slot: int) -> bool:
	var dosya_yolu = KAYIT_DOSYASI_1
	if slot == 2:
		dosya_yolu = KAYIT_DOSYASI_2
	elif slot == 3:
		dosya_yolu = KAYIT_DOSYASI_3
	return FileAccess.file_exists(dosya_yolu)

# --- KAYIT BİLGİSİ AL ---
func kayit_bilgisi_al(slot: int) -> Dictionary:
	var dosya_yolu = KAYIT_DOSYASI_1
	if slot == 2:
		dosya_yolu = KAYIT_DOSYASI_2
	elif slot == 3:
		dosya_yolu = KAYIT_DOSYASI_3
	
	if not FileAccess.file_exists(dosya_yolu):
		return {"var": false}
	
	var dosya = FileAccess.open(dosya_yolu, FileAccess.READ)
	var json_veri = dosya.get_line()
	var veriler = JSON.parse_string(json_veri)
	
	if veriler:
		return {
			"var": true,
			"zaman": veriler.get("kayit_zamani", "Bilinmiyor"),
			"sahne": veriler.get("sahne", ""),
			"altin": veriler.get("altin", 0)
		}
	return {"var": false}

# --- GELİŞMİŞ YÜKLEME FONKSİYONU ---
func oyunu_yukle(slot: int = 1):
	var dosya_yolu = KAYIT_DOSYASI_1
	if slot == 2:
		dosya_yolu = KAYIT_DOSYASI_2
	elif slot == 3:
		dosya_yolu = KAYIT_DOSYASI_3
	
	if not FileAccess.file_exists(dosya_yolu):
		print("Slot ", slot, " için kayıt dosyası bulunamadı!")
		return false
	
	var dosya = FileAccess.open(dosya_yolu, FileAccess.READ)
	var json_veri = dosya.get_line()
	var veriler = JSON.parse_string(json_veri)
	
	if veriler:
		# Pozisyon
		yuklenen_pozisyon = Vector2(veriler["poz_x"], veriler["poz_y"])
		
		# Ekonomi ve stats
		altin = veriler.get("altin", 500)
		current_qut = veriler.get("qut", 200)
		graze_points = veriler.get("graze", 0)
		secili_karakter_index = veriler.get("secili_karakter", 0)
		
		# Envanter yükle
		inventory.clear()
		for esya_path in veriler.get("envanter", []):
			var esya = load(esya_path)
			if esya:
				inventory.append(esya)
		
		# Party yükle
		var party_verileri = veriler.get("party", [])
		for i in range(party_verileri.size()):
			if i < party_data.size():
				var karakter_veri = party_verileri[i]
				party_data[i]["hp"] = karakter_veri["hp"]
				party_data[i]["max_hp"] = karakter_veri["max_hp"]
				party_data[i]["atk"] = karakter_veri["atk"]
				party_data[i]["def"] = karakter_veri["def"]
				
				# Ekipman yükle
				if karakter_veri["silah"]:
					party_data[i]["silah"] = load(karakter_veri["silah"])
				else:
					party_data[i]["silah"] = null
					
				if karakter_veri["zirh"]:
					party_data[i]["zirh"] = load(karakter_veri["zirh"])
				else:
					party_data[i]["zirh"] = null
		
		# Sahneyi değiştir
		Gecis.sahne_degistir(veriler["sahne"]) 
		print("Oyun Yüklendi! Slot: ", slot)
		return true
	return false

func _ready():
	var elma = load("res://Items/elma.tres") 
	var kilic = load("res://Items/pasli_kilic.tres")
	
	if elma and kilic:
		envantere_ekle(elma)
		envantere_ekle(elma)
		envantere_ekle(kilic)
		print("Test eşyaları envantere eklendi! Toplam: ", inventory.size(), "/", MAX_ENVANTER_KAPASITESI)
	else:
		print("HATA: Eşya dosyaları bulunamadı! Yolları kontrol et.")

# --- EŞYA KULLANIM FONKSİYONLARI ---
func karakteri_iyilestir(miktar):
	var karakter = party_data[secili_karakter_index]
	karakter["hp"] += miktar
	if karakter["hp"] > karakter["max_hp"]:
		karakter["hp"] = karakter["max_hp"]
	print(karakter["isim"] + " iyileşti. Yeni HP: " + str(karakter["hp"]))

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
