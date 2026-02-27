extends CanvasLayer

func _ready():
	print("=== SavasBitisEfekti _ready, viewport: ", get_viewport().get_visible_rect().size)
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 1)
	rect.size = get_viewport().get_visible_rect().size
	rect.position = Vector2.ZERO
	add_child(rect)
	
	var tw = create_tween()
	tw.tween_property(rect, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(queue_free)
