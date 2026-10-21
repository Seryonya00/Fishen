extends Node3D

const WALK_SPEED := 4.2
const RUN_SPEED := 6.8
var player: CharacterBody3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.12
var cast_state := "ready" # ready, waiting, bite, hooked, caught
var bite_timer := 0.0
var fish_weight := 0.0
var tension := 0.0
var reeling := false
var look_touch := -1
var joystick_touch := -1
var joystick_origin := Vector2.ZERO
var last_touch := Vector2.ZERO
var joystick := Vector2.ZERO
var status_label: Label
var fish_label: Label
var cast_button: Button
var hook_button: Button
var reel_button: Button
var run_button: Button
var store_button: Button
var store_panel: Panel
var money := 120
var inventory := ["Червь × 10"]

func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()
	_update_status("Тихий пруд. Выбери точку и забрось удочку.")

func _build_world() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	e.sky = Sky.new()
	e.sky.sky_material = ProceduralSkyMaterial.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.66, 0.75)
	e.ambient_light_energy = 0.8
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.15
	add_child(sun)
	# Shore and water are lightweight procedural geometry: no external assets required for the prototype.
	_add_box(Vector3(0, -0.35, 0), Vector3(42, 0.7, 18), Color("#71634b"), "Shore")
	_add_box(Vector3(0, -0.16, -17), Vector3(42, 0.18, 18), Color("#287f9a"), "Pond")
	_add_box(Vector3(0, -0.24, -8.8), Vector3(42, 0.22, 1.0), Color("#9a8764"), "WetSand")
	for i in range(26):
		var x := randf_range(-19, 19)
		var z := randf_range(1.0, 8.0)
		var bush := _make_sphere(Color("#426b35" if i % 2 == 0 else "#587c3b"), Vector3(randf_range(.35,.8),randf_range(.4,1.0),randf_range(.35,.8)))
		bush.position = Vector3(x, 0.25, z)
		add_child(bush)
	for i in range(12):
		var x := randf_range(-18,18)
		var reed := _add_box(Vector3(x, 0.9, randf_range(-3,1)), Vector3(.08,1.8,.08), Color("#82934c"), "Reed")

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1.0, 5.0)
	add_child(player)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.32
	collision.shape = capsule
	player.add_child(collision)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0.62, 0)
	camera.current = true
	player.add_child(camera)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)
	status_label = Label.new()
	status_label.position = Vector2(24, 18)
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(status_label)
	fish_label = Label.new()
	fish_label.position = Vector2(24, 58)
	fish_label.add_theme_font_size_override("font_size", 18)
	fish_label.add_theme_color_override("font_color", Color("#f6d77a"))
	root.add_child(fish_label)
	# Touch look: drag anywhere outside the left movement pad.
	var hint := Label.new()
	hint.text = "Левый круг — ходьба · свайп справа — обзор"
	hint.position = Vector2(24, -38)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	root.add_child(hint)
	cast_button = _button(root, "ЗАБРОС", Vector2(-230,-170), Vector2(190,76), Control.PRESET_BOTTOM_RIGHT)
	cast_button.pressed.connect(_cast)
	hook_button = _button(root, "ПОДСЕЧКА", Vector2(-230,-260), Vector2(190,76), Control.PRESET_BOTTOM_RIGHT)
	hook_button.pressed.connect(_hook)
	reel_button = _button(root, "ТЯНУТЬ", Vector2(-230,-80), Vector2(190,76), Control.PRESET_BOTTOM_RIGHT)
	reel_button.pressed.connect(_toggle_reel)
	run_button = _button(root, "БЕГ", Vector2(28,-105), Vector2(120,68), Control.PRESET_BOTTOM_LEFT)
	store_button = _button(root, "МАГАЗИН", Vector2(24,105), Vector2(150,60), Control.PRESET_TOP_LEFT)
	store_button.pressed.connect(_open_store)
	store_panel = Panel.new()
	store_panel.visible = false
	store_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	store_panel.position = Vector2(-220,-170)
	store_panel.size = Vector2(440,340)
	root.add_child(store_panel)
	var store_text := Label.new()
	store_text.text = "МАГАЗИН\n\nЧерви — 20 серебра\nКукуруза — 35 серебра\nПоплавок — 50 серебра\n\nНажми кнопку покупки ниже"
	store_text.position = Vector2(24,20)
	store_text.add_theme_font_size_override("font_size",22)
	store_panel.add_child(store_text)
	var buy := Button.new()
	buy.text = "КУПИТЬ ЧЕРВЕЙ (20)"
	buy.position = Vector2(25,250)
	buy.size = Vector2(390,60)
	buy.pressed.connect(_buy_worms)
	store_panel.add_child(buy)
	var close := Button.new()
	close.text = "×"
	close.position = Vector2(390,0)
	close.size = Vector2(45,45)
	close.pressed.connect(func(): store_panel.visible = false)
	store_panel.add_child(close)

func _button(parent: Control, caption: String, pos: Vector2, sz: Vector2, preset: int) -> Button:
	var b := Button.new()
	b.text = caption
	b.set_anchors_and_offsets_preset(preset)
	b.position = pos
	b.size = sz
	b.add_theme_font_size_override("font_size", 24)
	parent.add_child(b)
	return b

func _add_box(pos: Vector3, size: Vector3, color: Color, node_name: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	m.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	m.material_override = mat
	m.position = pos
	m.name = node_name
	add_child(m)
	return m

func _make_sphere(color: Color, size: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	m.mesh = mesh
	m.scale = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	m.material_override = mat
	return m

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x * 0.42:
				joystick_touch = event.index
				joystick_origin = event.position
				joystick = Vector2.ZERO
			else:
				look_touch = event.index
				last_touch = event.position
		else:
			if event.index == look_touch:
				look_touch = -1
			if event.index == joystick_touch:
				joystick_touch = -1
				joystick = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == joystick_touch:
			joystick = ((event.position - joystick_origin) / 75.0).limit_length(1.0)
	elif event is InputEventScreenDrag and event.index == look_touch and look_touch >= 0:
		var delta := event.position - last_touch
		last_touch = event.position
		_rotate_view(delta)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_rotate_view(event.relative)

func _rotate_view(delta: Vector2) -> void:
	yaw -= delta.x * 0.004
	pitch = clamp(pitch - delta.y * 0.003, -1.15, 0.7)
	player.rotation.y = yaw
	camera.rotation.x = pitch

func _process(delta: float) -> void:
	# Keyboard controls are convenient in the desktop editor; touch UI is the Android path.
	var input_dir := joystick
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	if input_dir.length() > 1: input_dir = input_dir.normalized()
	var basis := player.global_transform.basis
	var dir := (basis.x * input_dir.x + basis.z * input_dir.y)
	var speed := RUN_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED
	player.velocity.x = dir.x * speed
	player.velocity.z = dir.z * speed
	player.velocity.y -= 20.0 * delta
	player.move_and_slide()
	if cast_state == "waiting":
		bite_timer -= delta
		if bite_timer <= 0:
			cast_state = "bite"
			_update_status("ПОКЛЁВКА! Нажми «Подсечка»")
	elif cast_state == "hooked":
		if reeling:
			tension += delta * randf_range(0.14,0.42)
			if randf() < 0.035: tension -= randf_range(0.08,0.2)
			tension = clamp(tension,0,1.2)
			if tension > 1.0:
				cast_state = "ready"
				reeling = false
				_update_status("Леска оборвалась! Попробуй ещё раз.")
			elif tension > 0.65:
				_update_status("Натяжение: опасно! Ослабь тормоз.")
			elif randf() < 0.012:
				cast_state = "caught"
				fish_weight = randf_range(0.4,3.8)
				money += int(fish_weight * 18)
				_update_status("Улов: карась %.2f кг · +%d серебра" % [fish_weight, int(fish_weight*18)])
				fish_label.text = "🐟 Карась · %.2f кг · Садок: 1/20" % fish_weight

func _cast() -> void:
	if store_panel.visible: return
	if cast_state in ["ready", "caught"]:
		cast_state = "waiting"
		bite_timer = randf_range(5.0,14.0)
		fish_label.text = "Поплавок на воде…"
		_update_status("Заброс! Ждём поклёвку…")
	elif cast_state == "waiting":
		_update_status("Поплавок уже на воде.")
	elif cast_state == "bite":
		_update_status("Клюёт! Подсекай!")

func _hook() -> void:
	if cast_state == "bite":
		cast_state = "hooked"
		tension = 0.28
		reeling = true
		_update_status("Рыба на крючке! Нажми «Тянуть» чтобы вываживать.")
	elif cast_state == "hooked":
		tension = max(0.0, tension - 0.18)
		_update_status("Подсечка/контроль натяжения: %.0f%%" % (tension*100))
	else:
		_update_status("Пока нет поклёвки.")

func _toggle_reel() -> void:
	if cast_state == "hooked":
		reeling = not reeling
		_update_status("Вываживание: %s · натяжение %.0f%%" % ["тянем" if reeling else "пауза", tension*100])
	elif cast_state == "caught":
		cast_state = "ready"
		fish_label.text = ""
		_update_status("Снасть готова к следующему забросу.")
	else:
		_update_status("Сначала дождись поклёвки и подсекни.")

func _open_store() -> void:
	store_panel.visible = not store_panel.visible
	_update_status("Серебро: %d" % money)

func _buy_worms() -> void:
	if money >= 20:
		money -= 20
		inventory.append("Червь × 10")
		_update_status("Куплено 10 червей. Серебро: %d" % money)
	else:
		_update_status("Не хватает серебра.")

func _update_status(msg: String) -> void:
	status_label.text = msg
