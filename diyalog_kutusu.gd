extends CanvasLayer

# --- SİNYALLER ---
signal diyalog_bitti 

# --- BAĞLANTILAR ---
@onready var yazi_alani = $Arkaplan/MetinLabel
@onready var isim_label = $Arkaplan/IsimLabel
@onready var arkaplan = $Arkaplan

# --- DEĞİŞKENLER ---
var diyalog_listesi = []
var suanki_satir_index = 0
var yaziyor = false
var tween
var input_bekleme = false # YENİ: Tuşlara hemen basılmasın diye kilit
var kapaninca_calisacak_fonksiyon: Callable = Callable() # YENİ: Tüccar için hafıza

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS 

# --- BAŞLAT (GÜNCELLENDİ: "sonraki_islem" parametresi eklendi) ---
func baslat(isim, gelen_mesaj, sonraki_islem: Callable = Callable()):
	if visible: return
	yazi_alani.visible_ratio = 0 
	yazi_alani.text = "" # Garanti olsun diye içini de boşaltalım
	# Hafızaya at (Eğer varsa diyalog bitince bu fonksiyonu çalıştıracağız)
	kapaninca_calisacak_fonksiyon = sonraki_islem
	
	# 1. Oyunu Durdur
	get_tree().paused = true
	visible = true
	
	# 2. İsmi Ayarla
	isim_label.text = isim
	
	# 3. Mesaj Listesini Ayarla
	suanki_satir_index = 0
	if typeof(gelen_mesaj) == TYPE_STRING:
		diyalog_listesi = [gelen_mesaj]
	else:
		diyalog_listesi = gelen_mesaj
	
	# 4. YENİ: Hemen tuş algılamayı kapat (0.2 sn bekle)
	# Böylece açtığımız tuşla (Z) yazıyı yanlışlıkla geçmeyiz.
	input_bekleme = true
	await get_tree().create_timer(0.2).timeout
	input_bekleme = false
	
	satiri_goster()

func satiri_goster():
	if suanki_satir_index >= diyalog_listesi.size():
		kutuyu_kapat()
		return
		
	yazi_alani.text = diyalog_listesi[suanki_satir_index]
	yazi_alani.visible_ratio = 0
	yaziyor = true
	
	if tween: tween.kill()
	
	tween = create_tween()
	var sure = yazi_alani.text.length() * 0.05
	tween.tween_property(yazi_alani, "visible_ratio", 1.0, sure)
	
	tween.finished.connect(_yazim_bitti)

func _yazim_bitti():
	yaziyor = false

func _process(_delta):
	if not visible: return
	if input_bekleme: return # Kilitliyse tuşlara bakma

	# X Tuşu: Hızlıca tamamla
	if Input.is_action_just_pressed("tus_x"):
		hizli_tamamla()
			
	# Z Tuşu: İlerle
	if Input.is_action_just_pressed("tus_z"):
		if yaziyor:
			hizli_tamamla()
		else:
			suanki_satir_index += 1
			satiri_goster()

func hizli_tamamla():
	if tween: tween.kill()
	yazi_alani.visible_ratio = 1.0
	yaziyor = false

func kutuyu_kapat():
	visible = false
	if tween: tween.kill()
	
	# Oyunu devam ettir
	get_tree().paused = false
	
	# Sinyali gönder
	diyalog_bitti.emit()
	
	# YENİ: Eğer bir görev (Tüccar menüsü vb.) varsa onu çalıştır
	if kapaninca_calisacak_fonksiyon.is_valid():
		kapaninca_calisacak_fonksiyon.call()
		kapaninca_calisacak_fonksiyon = Callable() # Hafızayı temizle
