extends Control
class_name MainMenuController


enum MenuMode {
	MAIN_MENU,
	PAUSE_MENU,
}


# Rutas fijas del proyecto.
const GAME_SCENE_PATH := "res://Game.tscn"
const MAIN_MENU_SCENE_PATH := "res://Menu.tscn"


@export_category("Menu behavior")

## En Menu.tscn usa MAIN_MENU.
## En Pause.tscn usa PAUSE_MENU.
@export var menu_mode: MenuMode = MenuMode.MAIN_MENU

## Hace que la escena comience negra y aparezca suavemente.
@export var fade_on_enter: bool = true

## Hace aparecer los botones uno por uno al cargar la escena.
@export var animate_buttons_on_enter: bool = true


@export_category("Main menu")

## Contenedor de los tres botones principales.
@export var main_menu: Control

## En Menu.tscn representa Play.
## En Pause.tscn representa Continue.
@export var play_button: Button

@export var options_button: Button

## En Menu.tscn cierra la aplicación.
## En Pause.tscn vuelve a Menu.tscn.
@export var exit_button: Button


@export_category("Options menu")

@export var options_menu: Control
@export var back_button: Button

## Agregá labels, sliders y el botón Back en el orden deseado.
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


var _busy: bool = true
var _main_controls: Array[Control] = []


func _ready() -> void:
	_main_controls = [
		play_button,
		options_button,
		exit_button,
	]

	if not _validate_required_nodes():
		return

	_connect_buttons()

	main_menu.visible = true
	options_menu.visible = false

	_set_buttons_enabled(false)

	# Esperamos a que Containers y Controls calculen su tamaño.
	await get_tree().process_frame

	_prepare_controls(options_controls)

	if fade_on_enter:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 1.0
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		fade_overlay.visible = true
		fade_overlay.modulate.a = 0.0
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if animate_buttons_on_enter:
		_reset_controls_for_entrance(_main_controls)
	else:
		_prepare_controls(_main_controls)

	if fade_on_enter:
		await _fade_from_black()

	if animate_buttons_on_enter:
		await _show_controls(_main_controls)

	_busy = false
	_set_buttons_enabled(true)

	if play_button != null:
		play_button.grab_focus()


func _validate_required_nodes() -> bool:
	var valid := true

	if main_menu == null:
		push_error(
			"MainMenuController: falta asignar Main Menu."
		)
		valid = false

	if play_button == null:
		push_error(
			"MainMenuController: falta asignar Play/Continue Button."
		)
		valid = false

	if options_button == null:
		push_error(
			"MainMenuController: falta asignar Options Button."
		)
		valid = false

	if exit_button == null:
		push_error(
			"MainMenuController: falta asignar Exit Button."
		)
		valid = false

	if options_menu == null:
		push_error(
			"MainMenuController: falta asignar Options Menu."
		)
		valid = false

	if back_button == null:
		push_error(
			"MainMenuController: falta asignar Back Button."
		)
		valid = false

	if fade_overlay == null:
		push_error(
			"MainMenuController: falta asignar Fade Overlay."
		)
		valid = false

	return valid


func _connect_buttons() -> void:
	if not play_button.pressed.is_connected(
		_on_play_pressed
	):
		play_button.pressed.connect(
			_on_play_pressed
		)

	if not options_button.pressed.is_connected(
		_on_options_pressed
	):
		options_button.pressed.connect(
			_on_options_pressed
		)

	if not exit_button.pressed.is_connected(
		_on_exit_pressed
	):
		exit_button.pressed.connect(
			_on_exit_pressed
		)

	if not back_button.pressed.is_connected(
		_on_back_pressed
	):
		back_button.pressed.connect(
			_on_back_pressed
		)


func _prepare_controls(
	controls: Array[Control]
) -> void:
	for control: Control in controls:
		if control == null:
			continue

		control.pivot_offset = control.size * 0.5
		control.scale = Vector2.ONE
		control.modulate.a = 1.0


func _on_play_pressed() -> void:
	if _busy:
		return

	# En el menú principal significa Play.
	# En la pausa significa Continue.
	# Ambos llevan a Game.tscn.
	await _leave_menu_and_change_scene(
		GAME_SCENE_PATH
	)


func _on_exit_pressed() -> void:
	if _busy:
		return

	_busy = true
	_set_buttons_enabled(false)

	await _hide_controls(_main_controls)
	await _fade_to_black()

	match menu_mode:
		MenuMode.MAIN_MENU:
			# Exit desde el menú principal cierra la demo.
			get_tree().quit()

		MenuMode.PAUSE_MENU:
			# Exit desde la pausa vuelve al menú.
			await _change_scene(
				MAIN_MENU_SCENE_PATH
			)


func _on_options_pressed() -> void:
	if _busy:
		return

	_busy = true
	_set_buttons_enabled(false)

	await _hide_controls(_main_controls)

	main_menu.visible = false
	options_menu.visible = true

	await get_tree().process_frame

	_reset_controls_for_entrance(options_controls)
	await _show_controls(options_controls)

	_busy = false
	_set_buttons_enabled(true)

	back_button.grab_focus()


func _on_back_pressed() -> void:
	if _busy:
		return

	_busy = true
	_set_buttons_enabled(false)

	await _hide_controls(options_controls)

	options_menu.visible = false
	main_menu.visible = true

	await get_tree().process_frame

	_reset_controls_for_entrance(_main_controls)
	await _show_controls(_main_controls)

	_busy = false
	_set_buttons_enabled(true)

	play_button.grab_focus()


func _leave_menu_and_change_scene(
	scene_path: String
) -> void:
	if _busy:
		return

	_busy = true
	_set_buttons_enabled(false)

	await _hide_controls(_main_controls)
	await _fade_to_black()
	await _change_scene(scene_path)


func _change_scene(
	scene_path: String
) -> void:
	if scene_path.is_empty():
		push_error(
			"La ruta de la escena está vacía."
		)
		await _recover_menu_after_error()
		return

	if not ResourceLoader.exists(scene_path):
		push_error(
			"No existe la escena: %s" % scene_path
		)
		await _recover_menu_after_error()
		return

	var error := get_tree().change_scene_to_file(
		scene_path
	)

	if error != OK:
		push_error(
			"No se pudo cargar '%s'. Código: %s"
			% [scene_path, error]
		)

		await _recover_menu_after_error()


func _recover_menu_after_error() -> void:
	await _fade_from_black()

	main_menu.visible = true
	options_menu.visible = false

	_reset_controls_for_entrance(_main_controls)
	await _show_controls(_main_controls)

	_busy = false
	_set_buttons_enabled(true)


func _hide_controls(
	controls: Array[Control]
) -> void:
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

		if item_delay > 0.0:
			await get_tree().create_timer(
				item_delay
			).timeout

	for tween: Tween in active_tweens:
		if tween != null and tween.is_running():
			await tween.finished


func _show_controls(
	controls: Array[Control]
) -> void:
	var active_tweens: Array[Tween] = []

	for control: Control in controls:
		if control == null:
			continue

		control.visible = true

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

		if item_delay > 0.0:
			await get_tree().create_timer(
				item_delay
			).timeout

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


func _fade_from_black() -> void:
	fade_overlay.visible = true
	fade_overlay.modulate.a = 1.0
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		fade_overlay,
		"modulate:a",
		0.0,
		fade_duration
	)

	await tween.finished

	fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _set_buttons_enabled(
	enabled: bool
) -> void:
	if play_button != null:
		play_button.disabled = not enabled

	if options_button != null:
		options_button.disabled = not enabled

	if exit_button != null:
		exit_button.disabled = not enabled

	if back_button != null:
		back_button.disabled = not enabled
