extends Node
class_name HoverManager

@export var buttons: Array[BaseButton] = []
@export var hover_texture: Texture2D

# Si querés “sin nada”, dejamos el icon en null.
@export var clear_texture: Texture2D = null

var _hovered: BaseButton = null

func _ready() -> void:
	# Conectamos señales de cada botón
	for b in buttons:
		if b == null:
			continue
		# Opcional: asegurá que arranquen sin icono
		_set_icon(b, clear_texture)

		# IMPORTANTE: usamos mouse_entered/mouse_exited del Control
		b.mouse_entered.connect(_on_button_mouse_entered.bind(b))
		b.mouse_exited.connect(_on_button_mouse_exited.bind(b))

func _on_button_mouse_entered(b: BaseButton) -> void:
	_hovered = b
	_update_icons()

func _on_button_mouse_exited(b: BaseButton) -> void:
	# Si salimos del mismo que estaba marcado, lo limpiamos.
	if _hovered == b:
		_hovered = null
	_update_icons()

func _update_icons() -> void:
	for b in buttons:
		if b == null:
			continue
		_set_icon(b, hover_texture if b == _hovered else clear_texture)

func _set_icon(b: BaseButton, tex: Texture2D) -> void:
	# En Godot 4, Button tiene "icon"
	if b is Button:
		(b as Button).icon = tex
	else:
		# Para otros BaseButton (TextureButton, etc.) podrías extender acá.
		# Por defecto, no hacemos nada.
		pass
