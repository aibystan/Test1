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
var input_bekleme = false
var kapaninca_calisacak_fonksiyon: Callable = Callable()

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS 

func baslat(isim, gelen_mesaj, sonraki_islem: Callable = Callable()):
	if visible: return
	yazi_alani.visible_ratio = 0 
	yazi_alani.text = ""
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
	
	# 4. Input bekleme
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
	if input_bekleme: return

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
	
	# ÖNEMLİ: Input'u temizle - bir sonraki frame'de Z basılı kalmasın
	Input.action_release("tus_z")
	
	# Oyunu devam ettir
	get_tree().paused = false
	
	# Sinyali gönder
	diyalog_bitti.emit()
	
	# Eğer bir görev varsa onu çalıştır
	if kapaninca_calisacak_fonksiyon.is_valid():
		kapaninca_calisacak_fonksiyon.call()
		kapaninca_calisacak_fonksiyon = Callable()
