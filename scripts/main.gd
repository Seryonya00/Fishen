extends Node3D

const SAVE_PATH := "user://fishing_legend_save.json"
var player: CharacterBody3D
var camera: Camera3D
var status_label: Label
var money_label: Label
var catch_label: Label
var joystick := Vector2.ZERO
var joystick_touch := -1
var look_touch := -1
var joystick_origin := Vector2.ZERO
var last_look := Vector2.ZERO
var state := "ready"
var bite_time := 0.0
var tension := 0.25
var reeling := false
var money := 120
var xp := 0
var level := 1
var catches: Array[Dictionary] = []
var fish_weight := 0.0

func _ready() -> void:
    randomize()
    _build_world()
    _build_player()
    _build_hud()
    _load_game()
    _status("Тихая заводь\nИсследуй берег и забрось удочку.")
    _update_money()

func _build_world() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    sky.sky_material = ProceduralSkyMaterial.new()
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.55, 0.66, 0.73)
    env.ambient_light_energy = 0.85
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-42, -25, 0)
    sun.light_energy = 1.1
    sun.shadow_enabled = true
    add_child(sun)

    _box("GrassBank", Vector3(0, -0.4, 4), Vector3(70, 0.8, 45), Color(0.24, 0.34, 0.18), true)
    _box("Lake", Vector3(0, -0.12, -19), Vector3(70, 0.18, 27), Color(0.08, 0.32, 0.42), false)
    _box("WetShore", Vector3(0, -0.12, -4.9), Vector3(70, 0.12, 2.2), Color(0.38, 0.33, 0.22), true)
    _box("Pier", Vector3(0, 0.12, -3.2), Vector3(3.2, 0.25, 7), Color(0.34, 0.22, 0.12), true)

    for i in range(18):
        var x := -29.0 + float(i) * 3.4
        _tree(Vector3(x, 0.0, 7.0 + float((i * 7) % 5)))
    for i in range(32):
        var x := -30.0 + float((i * 17) % 60)
        var z := -3.0 + float((i * 13) % 9)
        _box("Reed", Vector3(x, 0.65, z), Vector3(0.07, 1.3, 0.07), Color(0.49, 0.52, 0.22), true)
    for i in range(5):
        var x := 15.0 + float(i) * 4.2
        _box("VillageHouse", Vector3(x, 1.0, 15), Vector3(3.4, 2.0, 3.4), Color(0.48, 0.31, 0.19), true)
        _box("Roof", Vector3(x, 2.35, 15), Vector3(4.0, 0.6, 4.0), Color(0.25, 0.15, 0.12), true)
    _box("VillageRoad", Vector3(21, 0.02, 20), Vector3(34, 0.08, 3.5), Color(0.39, 0.34, 0.25), true)

    var shop_sign := Label3D.new()
    shop_sign.text = "МАГАЗИН СНАСТЕЙ"
    shop_sign.position = Vector3(23, 3.3, 12.7)
    shop_sign.font_size = 48
    add_child(shop_sign)

func _box(node_name: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    instance.position = pos
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.32 if node_name == "Lake" else 0.92
    if node_name == "Lake":
        material.metallic = 0.08
    instance.material_override = material
    add_child(instance)
    if collision:
        var body := StaticBody3D.new()
        body.position = pos
        var shape_node := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        shape_node.shape = shape
        body.add_child(shape_node)
        add_child(body)
    return instance

func _tree(pos: Vector3) -> void:
    _box("TreeTrunk", pos + Vector3(0, 1.0, 0), Vector3(0.35, 2.0, 0.35), Color(0.27, 0.17, 0.1), true)
    var crown := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 1.45
    sphere.height = 2.8
    crown.mesh = sphere
    crown.position = pos + Vector3(0, 2.7, 0)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.12, 0.28, 0.13)
    material.roughness = 1.0
    crown.material_override = material
    add_child(crown)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.position = Vector3(0, 0.15, 4)
    add_child(player)
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.height = 1.8
    capsule.radius = 0.32
    collider.shape = capsule
    collider.position.y = 0.9
    player.add_child(collider)
    camera = Camera3D.new()
    camera.position.y = 1.55
    camera.current = true
    player.add_child(camera)

    var rod := MeshInstance3D.new()
    var rod_mesh := CylinderMesh.new()
    rod_mesh.top_radius = 0.018
    rod_mesh.bottom_radius = 0.045
    rod_mesh.height = 1.7
    rod.mesh = rod_mesh
    rod.position = Vector3(0.42, -0.28, -0.9)
    rod.rotation_degrees.z = -28
    var rod_material := StandardMaterial3D.new()
    rod_material.albedo_color = Color(0.12, 0.09, 0.06)
    rod.material_override = rod_material
    camera.add_child(rod)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(root)

    money_label = Label.new()
    money_label.position = Vector2(24, 18)
    money_label.add_theme_font_size_override("font_size", 24)
    root.add_child(money_label)

    status_label = Label.new()
    status_label.position = Vector2(24, 58)
    status_label.size = Vector2(570, 95)
    status_label.add_theme_font_size_override("font_size", 21)
    root.add_child(status_label)

    catch_label = Label.new()
    catch_label.position = Vector2(24, 155)
    catch_label.add_theme_font_size_override("font_size", 18)
    root.add_child(catch_label)

    _make_button(root, "ЗАБРОС", Vector2(-202, -90), Vector2(176, 64), _cast)
    _make_button(root, "ПОДСЕЧКА", Vector2(-202, -164), Vector2(176, 64), _hook)
    _make_button(root, "КАТУШКА", Vector2(-202, -238), Vector2(176, 64), _reel)
    _make_button(root, "САДОК", Vector2(24, -90), Vector2(132, 54), _show_catches)
    _make_button(root, "МАГАЗИН", Vector2(24, -152), Vector2(132, 54), _shop)
    _make_button(root, "ПРОДАТЬ", Vector2(24, -214), Vector2(132, 54), _sell)
    var hint := Label.new()
    hint.text = "Левый свайп — движение · правый — обзор"
    hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    hint.position = Vector2(24, -32)
    root.add_child(hint)

func _make_button(parent: Control, caption: String, offset: Vector2, size: Vector2, action: Callable) -> void:
    var button := Button.new()
    button.text = caption
    button.size = size
    button.anchor_left = 1.0
    button.anchor_right = 1.0
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.position = offset
    button.add_theme_font_size_override("font_size", 18)
    button.pressed.connect(action)
    parent.add_child(button)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            var width := get_viewport().get_visible_rect().size.x
            if event.position.x < width * 0.42 and event.position.y > get_viewport().get_visible_rect().size.y * 0.42:
                joystick_touch = event.index
                joystick_origin = event.position
                joystick = Vector2.ZERO
            elif event.position.x > width * 0.42:
                look_touch = event.index
                last_look = event.position
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                joystick = Vector2.ZERO
            if event.index == look_touch:
                look_touch = -1
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            joystick = ((event.position - joystick_origin) / 70.0).limit_length(1.0)
        elif event.index == look_touch:
            var delta := event.position - last_look
            player.rotate_y(-delta.x * 0.004)
            camera.rotate_x(-delta.y * 0.003)
            camera.rotation.x = clampf(camera.rotation.x, -1.15, 0.7)
            last_look = event.position
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        player.rotate_y(-event.relative.x * 0.003)
        camera.rotate_x(-event.relative.y * 0.003)
        camera.rotation.x = clampf(camera.rotation.x, -1.15, 0.7)

func _physics_process(delta: float) -> void:
    var move := joystick
    move.x += Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
    move.y += Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
    move = move.limit_length(1.0)
    var direction := (player.global_transform.basis * Vector3(move.x, 0.0, move.y)).normalized()
    player.velocity.x = direction.x * 4.2
    player.velocity.z = direction.z * 4.2
    if not player.is_on_floor():
        player.velocity.y -= 20.0 * delta
    else:
        player.velocity.y = -0.1
    player.move_and_slide()

func _process(delta: float) -> void:
    if state == "waiting":
        bite_time -= delta
        if bite_time <= 0.0:
            state = "bite"
            _status("ПОКЛЁВКА! Нажми «ПОДСЕЧКА».")
    elif state == "fight" and reeling:
        tension = clampf(tension + randf_range(-0.12, 0.18) * delta, 0.0, 1.0)
        if tension >= 0.98:
            state = "ready"
            reeling = false
            _status("Обрыв лески! Попробуй другую тактику.")
        elif randf() < 0.025:
            fish_weight = snappedf(randf_range(0.25, 2.8), 0.01)
            var fish_name := ["Плотва", "Окунь", "Карась", "Лещ", "Щука"][randi_range(0, 4)]
            catches.append({"name": fish_name, "weight": fish_weight, "price": int(12 + fish_weight * 34.0)})
            xp += int(fish_weight * 10.0)
            if xp >= level * 100:
                xp -= level * 100
                level += 1
            state = "caught"
            reeling = false
            _status("Поймано: %s, %.2f кг!" % [fish_name, fish_weight])
            catch_label.text = "Последний улов: %s · %.2f кг" % [fish_name, fish_weight]
            _save_game()
    _update_money()

func _cast() -> void:
    if state == "ready" or state == "caught":
        state = "waiting"
        bite_time = randf_range(4.0, 11.0)
        _status("Заброс выполнен. Следи за поклёвкой…")
    else:
        _status("Заверши текущую ловлю перед новым забросом.")

func _hook() -> void:
    if state == "bite":
        state = "fight"
        tension = 0.35
        reeling = true
        _status("Рыба на крючке! Контролируй натяжение катушкой.")
    elif state == "waiting":
        _status("Пока тихо. Жди поклёвку.")
    else:
        _status("Сейчас подсекать не нужно.")

func _reel() -> void:
    if state != "fight":
        if state == "caught":
            state = "ready"
            _status("Снасть готова к следующему забросу.")
        else:
            _status("Сначала дождись поклёвки и подсечки.")
        return
    reeling = not reeling
    tension = clampf(tension + (0.1 if reeling else -0.18), 0.0, 1.0)
    _status("Вываживание %s · натяжение %.0f%%" % ["включено" if reeling else "пауза", tension * 100.0])

func _show_catches() -> void:
    if catches.is_empty():
        _status("Садок пуст. Забрось удочку!")
        return
    var total_weight := 0.0
    for fish in catches:
        total_weight += float(fish.get("weight", 0.0))
    _status("В садке: %d рыб, %.2f кг. Уровень %d, опыт %d." % [catches.size(), total_weight, level, xp])

func _sell() -> void:
    if catches.is_empty():
        _status("Садок пуст — продавать нечего.")
        return
    var total := 0
    for fish in catches:
        total += int(fish.get("price", 0))
    catches.clear()
    money += total
    _save_game()
    catch_label.text = ""
    _status("Улов продан за %d серебра." % total)

func _shop() -> void:
    if money < 5:
        _status("Не хватает серебра на червей.")
        return
    money -= 5
    _save_game()
    _status("Куплены черви за 5 серебра. В наличии: червь, кукуруза, опарыш.")
    _update_money()

func _status(message: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = message

func _update_money() -> void:
    if is_instance_valid(money_label):
        money_label.text = "Fishing Legend  ·  %d серебра  ·  ур. %d" % [money, level]

func _save_game() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"money": money, "xp": xp, "level": level, "catches": catches}))

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var data = JSON.parse_string(file.get_as_text())
    if typeof(data) == TYPE_DICTIONARY:
        money = int(data.get("money", money))
        xp = int(data.get("xp", xp))
        level = int(data.get("level", level))
        var loaded = data.get("catches", [])
        if loaded is Array:
            catches.assign(loaded)
