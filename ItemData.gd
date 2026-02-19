extends Resource
class_name ItemData

enum Tip { TUKETILEBILIR, SILAH, ZIRH }

# --- YENİ EKLENECEK KISIM ---
# Hangi karakterler bunu kullanabilir?
# Örnek: ["Ryu", "Nina"] yazarsak ikisi de giyer.
# Sadece ["Ryu"] yazarsak Nina giyemez.
# Boş bırakırsak [] herkes giyebilir (Yiyecekler gibi).
@export var kullanabilir_karakterler: Array[String] = [] 

@export_group("Temel Bilgiler")
@export var isim: String = "Eşya İsmi"
# ... (Diğer değişkenlerin aynen kalsın) ...
@export_multiline var aciklama: String = "Bu eşya ne işe yarar?"
@export var ikon: Texture2D # Eşyanın resmi
@export var tur: Tip = Tip.TUKETILEBILIR

@export_group("Etkiler")
# Eğer yiyecekse kaç can verir, silahsa kaç vurur?
@export var etki_degeri: int = 10
enum EtkiTuru { HP, QUT }
@export var etki_turu: EtkiTuru = EtkiTuru.HP

@export_group("Ekonomi")
@export var fiyat: int = 100 # Varsayılan fiyat
@export var satilabilir_mi: bool = true # Belki görev eşyalarını satmak istemeyiz
