extends Control
class_name MainMenuController


@export_category("Scenes")
@export var game_scene: PackedScene


@export_category("Main menu")
@export var main_menu: Control
@export var play_button: Button
@export var options_button: Button
@export var exit_button: Button


@export_category("Options menu")
@export var options_menu: Control
@export var back_button: Button

# Incluye aquí labels, sliders, botón volver, etc.
@export var options_controls: Array[Control] = []


@export_category("Transition")
@export var fade_overlay: ColorRect

@export_range(0.05, 1.0, 0.01)
var item_duration: float = 0.18

@export_range(0.0, 0.5, 0.01)
var item_delay: float = 0.06

@export_range(0.05, 2.0, 0.01)
var fade_duration: float = 0.45

@export_range(0.1, 1.0, 0.01)
var hidden_scale: float = 0.65


var _busy: bool = false
var _main_controls: Array[Control] = []


func _ready() -> void:
	_main_controls = [
		play_button,
		options_button,
		exit_button,
	]

	# Conectar botones.
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# El menú de opciones comienza oculto.
	options_menu.visible = false

	# El overlay existe, pero comienza transparente.
	fade_overlay.visible = true
	fade_overlay.modulate.a = 0.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Esperamos un frame para que los Containers calculen tamaños.
	await get_tree().process_frame

	_prepare_controls(_main_controls)
	_prepare_controls(options_controls)


func _prepare_controls(controls: Array[Control]) -> void:
	for control: Control in controls:
		if control == null:
			continue

		# Hace que la escala ocurra desde el centro.
		control.pivot_offset = control.size * 0.5
		control.scale = Vector2.ONE
		control.modulate.a = 1.0


func _on_play_pressed() -> void:
	if _busy:
		return

	_busy = true
	_set_buttons_enabled(false)

	await _hide_controls(_main_controls)
	await _fade_to_black()

	if game_scene == null:
		push_error("No se asignó game_scene en MainMenuController.")
		_busy = false
		return

	var error := get_tree().change_scene_to_packed(game_scene)

	if error != OK:
		push_error(
			"No se pudo cargar la escena de juego. Código: %s" % error
		)


func _on_exit_pressed() -> void:
	if _busy:
		return

	_busy = true
	_set_buttons_enabled(false)

	await _hide_controls(_main_controls)
	await _fade_to_black()

	get_tree().quit()


func _on_options_pressed() -> void:
	if _busy:
		return

	_busy = true
	_set_buttons_enabled(false)

	await _hide_controls(_main_controls)

	main_menu.visible = false
	options_menu.visible = true

	_reset_controls_for_entrance(options_controls)
	await _show_controls(options_controls)

	_busy = false
	_set_buttons_enabled(true)


func _on_back_pressed() -> void:
	if _busy:
		return

	_busy = true
	_set_buttons_enabled(false)

	await _hide_controls(options_controls)

	options_menu.visible = false
	main_menu.visible = true

	_reset_controls_for_entrance(_main_controls)
	await _show_controls(_main_controls)

	_busy = false
	_set_buttons_enabled(true)


func _hide_controls(controls: Array[Control]) -> void:
	var active_tweens: Array[Tween] = []

	for control: Control in controls:
		if control == null:
			continue

		var tween := create_tween()
		active_tweens.append(tween)

		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_IN)

		tween.set_parallel(true)
		tween.tween_property(
			control,
			"scale",
			Vector2.ONE * hidden_scale,
			item_duration
		)
		tween.tween_property(
			control,
			"modulate:a",
			0.0,
			item_duration
		)

		# Espera breve antes de comenzar con el siguiente elemento.
		await get_tree().create_timer(item_delay).timeout

	# Esperar a que todas las animaciones hayan terminado.
	for tween: Tween in active_tweens:
		if tween != null and tween.is_running():
			await tween.finished


func _show_controls(controls: Array[Control]) -> void:
	var active_tweens: Array[Tween] = []

	for control: Control in controls:
		if control == null:
			continue

		var tween := create_tween()
		active_tweens.append(tween)

		tween.set_trans(Tween.TRANS_BACK)
		tween.set_ease(Tween.EASE_OUT)

		tween.set_parallel(true)
		tween.tween_property(
			control,
			"scale",
			Vector2.ONE,
			item_duration
		)
		tween.tween_property(
			control,
			"modulate:a",
			1.0,
			item_duration
		)

		await get_tree().create_timer(item_delay).timeout

	for tween: Tween in active_tweens:
		if tween != null and tween.is_running():
			await tween.finished


func _reset_controls_for_entrance(
	controls: Array[Control]
) -> void:
	for control: Control in controls:
		if control == null:
			continue

		control.pivot_offset = control.size * 0.5
		control.scale = Vector2.ONE * hidden_scale
		control.modulate.a = 0.0


func _fade_to_black() -> void:
	fade_overlay.visible = true
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		fade_overlay,
		"modulate:a",
		1.0,
		fade_duration
	)

	await tween.finished


func _set_buttons_enabled(enabled: bool) -> void:
	play_button.disabled = not enabled
	options_button.disabled = not enabled
	exit_button.disabled = not enabled
	back_button.disabled = not enabled
