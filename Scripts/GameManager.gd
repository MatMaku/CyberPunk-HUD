extends Node
class_name GameManager


enum ScreenMode {
	GAME,
	INVENTORY,
}


const GAME_SCENE_PATH := "res://Game.tscn"
const INVENTORY_SCENE_PATH := "res://Inventory.tscn"
const PAUSE_SCENE_PATH := "res://Pause.tscn"


@export_category("Current screen")

## En Game.tscn elegí GAME.
## En Inventory.tscn elegí INVENTORY.
@export var screen_mode: ScreenMode = ScreenMode.GAME


var _changing_scene: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if _changing_scene:
		return

	if event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		await _handle_tab()
		return

	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		await _change_scene(PAUSE_SCENE_PATH)


func _handle_tab() -> void:
	match screen_mode:
		ScreenMode.GAME:
			await _change_scene(INVENTORY_SCENE_PATH)

		ScreenMode.INVENTORY:
			await _change_scene(GAME_SCENE_PATH)


func _change_scene(scene_path: String) -> void:
	if _changing_scene:
		return

	if scene_path.is_empty():
		push_error(
			"GameManager: la ruta de la escena está vacía."
		)
		return

	if not ResourceLoader.exists(scene_path):
		push_error(
			"GameManager: no existe la escena '%s'."
			% scene_path
		)
		return

	_changing_scene = true

	var error := get_tree().change_scene_to_file(
		scene_path
	)

	if error != OK:
		push_error(
			"GameManager: no se pudo cargar '%s'. Código: %s"
			% [scene_path, error]
		)

		_changing_scene = false
