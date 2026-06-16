extends Control
class_name BackgroundSlideshow


@export_category("Images")
@export var backgrounds: Array[Texture2D] = []
@export var random_order: bool = true


@export_category("Timing")
@export_range(1.0, 30.0, 0.1)
var image_duration: float = 7.0

@export_range(0.1, 3.0, 0.1)
var fade_duration: float = 0.8


@export_category("Movement")
@export_range(1.0, 1.4, 0.001)
var start_zoom: float = 1.06

@export_range(1.0, 1.4, 0.001)
var end_zoom: float = 1.14

@export_range(0.0, 100.0, 1.0)
var movement_distance: float = 25.0


@export_category("References")
@export var background: TextureRect


var _current_index: int = -1
var _motion_tween: Tween
var _running: bool = false


func _ready() -> void:
	if backgrounds.is_empty():
		push_warning("No hay imágenes asignadas al slideshow.")
		return

	if background == null:
		push_error("No se asignó el TextureRect Background.")
		return

	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.modulate.a = 0.0

	await get_tree().process_frame

	_running = true
	_show_next_background()
	await _fade_in()

	while _running and is_inside_tree():
		await get_tree().create_timer(image_duration).timeout

		if not _running:
			return

		await _fade_out()

		_show_next_background()

		await _fade_in()


func _show_next_background() -> void:
	_current_index = _get_next_index()
	background.texture = backgrounds[_current_index]

	background.position = Vector2.ZERO
	background.scale = Vector2.ONE * start_zoom
	background.pivot_offset = background.size * 0.5

	_start_motion()


func _start_motion() -> void:
	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()

	var direction := _get_random_direction()

	_motion_tween = create_tween()
	_motion_tween.set_parallel(true)
	_motion_tween.set_trans(Tween.TRANS_SINE)
	_motion_tween.set_ease(Tween.EASE_IN_OUT)

	_motion_tween.tween_property(
		background,
		"scale",
		Vector2.ONE * end_zoom,
		image_duration
	)

	_motion_tween.tween_property(
		background,
		"position",
		direction * movement_distance,
		image_duration
	)


func _fade_out() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		background,
		"modulate:a",
		0.0,
		fade_duration
	)

	await tween.finished


func _fade_in() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		background,
		"modulate:a",
		1.0,
		fade_duration
	)

	await tween.finished


func _get_next_index() -> int:
	if backgrounds.size() == 1:
		return 0

	if random_order:
		var next_index := randi_range(0, backgrounds.size() - 1)

		while next_index == _current_index:
			next_index = randi_range(0, backgrounds.size() - 1)

		return next_index

	return wrapi(_current_index + 1, 0, backgrounds.size())


func _get_random_direction() -> Vector2:
	var directions: Array[Vector2] = [
		Vector2(1.0, 0.25),
		Vector2(-1.0, 0.25),
		Vector2(1.0, -0.25),
		Vector2(-1.0, -0.25),
		Vector2(0.25, 1.0),
		Vector2(-0.25, 1.0),
	]

	return directions.pick_random().normalized()


func stop() -> void:
	_running = false

	if _motion_tween != null and _motion_tween.is_valid():
		_motion_tween.kill()
