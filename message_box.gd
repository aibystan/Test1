extends Panel

@onready var mesaj_label = $MarginContainer/MesajLabel

var mesaj_kuyrugu: Array = []
var aktif_mesaj = false

func _ready():
	pass

func mesaj_goster(mesaj: String, sure: float = 2.0):
	mesaj_kuyrugu.append({"mesaj": mesaj, "sure": sure})
	
	if not aktif_mesaj:
		sonraki_mesaj()

func sonraki_mesaj():
	if mesaj_kuyrugu.is_empty():
		aktif_mesaj = false
		mesaj_label.text = ""
		return
	
	aktif_mesaj = true
	var veri = mesaj_kuyrugu.pop_front()
	
	# Mesajı göster
	mesaj_label.text = veri["mesaj"]
	
	# Typewriter efekti (opsiyonel - şimdilik direkt)
	# await typewriter_efekti(veri["mesaj"])
	
	# Bekle
	await get_tree().create_timer(veri["sure"]).timeout
	
	# Sonraki mesaj
	sonraki_mesaj()

func typewriter_efekti(tam_mesaj: String):
	mesaj_label.text = ""
	for i in range(tam_mesaj.length()):
		mesaj_label.text += tam_mesaj[i]
		await get_tree().create_timer(0.03).timeout

func temizle():
	mesaj_kuyrugu.clear()
	mesaj_label.text = ""
	aktif_mesaj = false
