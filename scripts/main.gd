extends Node3D

const SAVE_PATH := "user://savegame.json"
var silver := 120
var xp := 0
var level := 1
var catches: Array[Dictionary] = []
var phase := "ready"
var tension := 0.0
var cast_timer := 0.0
var bite_delay := 0.0
var fish_power := 0.45
var look_touch := -1
var last_touch := Vector2.ZERO
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var status_label: Label
var silver_label: Label
var tension_bar: ProgressBar
var shop_panel: PanelContainer
var shop_open := false
var move_vector := Vector2.ZERO
var touch_look := false
var rod_line: MeshInstance3D
var time_of_day := 0.25

func _ready() -> void:
    _build_world()
    _build_player()
    _build_hud()
    _load_game()
    _set_status("Озеро «Тихая заводь»\nВыбери место и забрось снасть.")
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_SKY
    e.sky = Sky.new()
    e.sky.sky_material = ProceduralSkyMaterial.new()
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.62, 0.7, 0.78)
    e.ambient_light_energy = 0.8
    e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = e
    add_child(env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-38, -25, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)
    _box("Ground", Vector3(0,-0.35,0), Vector3(100,0.6,100), Color(0.22,0.31,0.16))
    _box("Lake", Vector3(0,-0.08,-22), Vector3(70,0.12,38), Color(0.08,0.34,0.43,0.88), true)
    _box("Pier", Vector3(0,0.08,-5), Vector3(3.4,0.28,8), Color(0.35,0.22,0.12))
    for i in range(13):
        var x := -17.0 + float(i) * 2.8
        _tree(Vector3(x,0,-2.0 - float((i*7)%5)))
        _tree(Vector3(x,0,9.0 + float((i*3)%4)))
    for i in range(24):
        var x := -15.0 + float((i*13)%30)
        var z := -1.0 + float((i*17)%16)
        _box("Reed", Vector3(x,0.65,z), Vector3(0.08,1.3,0.08), Color(0.42,0.48,0.18))
    for i in range(5):
        _box("VillageHouse", Vector3(14 + i*4,1.2,13), Vector3(3.5,2.4,3.5), Color(0.48,0.29,0.17))
        _box("Roof", Vector3(14 + i*4,2.8,13), Vector3(4.1,0.6,4.1), Color(0.28,0.15,0.12))
    _box("Road", Vector3(18,0.01,20), Vector3(30,0.08,4), Color(0.36,0.32,0.24))
    var label := Label3D.new()
    label.text = "МАГАЗИН СНАСТЕЙ"
    label.position = Vector3(22,3.5,11)
    label.font_size = 48
    add_child(label)

func _box(n: String, pos: Vector3, size: Vector3, color: Color, transparent := false) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.28 if n == "Lake" else 0.92
    if transparent:
        mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    m.material_override = mat
    add_child(m)
    var body := StaticBody3D.new()
    body.name = n + "Collision"
    body.position = pos
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return m

func _tree(pos: Vector3) -> void:
    var trunk := _box("TreeTrunk", pos + Vector3(0,1.2,0), Vector3(0.45,2.4,0.45), Color(0.25,0.15,0.09))
    var crown := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 1.7
    mesh.height = 3.2
    crown.mesh = mesh
    crown.position = pos + Vector3(0,3.2,0)
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.12,0.29,0.13)
    mat.roughness = 1.0
    crown.material_override = mat
    add_child(crown)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.position = Vector3(0,1.0,4)
    add_child(player)
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.height = 1.8
    capsule.radius = 0.36
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)
    camera = Camera3D.new()
    camera.position.y = 1.55
    camera.current = true
    player.add_child(camera)
    var rod := MeshInstance3D.new()
    var cylinder := CylinderMesh.new()
    cylinder.top_radius = 0.025
    cylinder.bottom_radius = 0.06
    cylinder.height = 2.3
    rod.mesh = cylinder
    rod.position = Vector3(0.48,-0.25,-1.0)
    rod.rotation_degrees.z = -28
    var rodmat := StandardMaterial3D.new()
    rodmat.albedo_color = Color(0.12,0.1,0.07)
    rod.material_override = rodmat
    camera.add_child(rod)
    var line := MeshInstance3D.new()
    var im := ImmediateMesh.new()
    im.surface_begin(Mesh.PRIMITIVE_LINES)
    im.surface_add_vertex(Vector3(0.48,-0.1,-2.0))
    im.surface_add_vertex(Vector3(0.4,-0.5,-6.0))
    im.surface_end()
    line.mesh = im
    var lm := StandardMaterial3D.new()
    lm.albedo_color = Color(0.9,0.9,0.7)
    line.material_override = lm
    camera.add_child(line)

func _build_hud() -> void:
    hud = CanvasLayer.new()
    add_child(hud)
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud.add_child(root)
    var cross := Label.new()
    cross.text = "＋"
    cross.add_theme_font_size_override("font_size", 28)
    cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    cross.position = Vector2(-10,-18)
    root.add_child(cross)
    silver_label = Label.new()
    silver_label.position = Vector2(24,20)
    silver_label.add_theme_font_size_override("font_size", 24)
    root.add_child(silver_label)
    status_label = Label.new()
    status_label.position = Vector2(24,58)
    status_label.size = Vector2(550,80)
    status_label.add_theme_font_size_override("font_size", 20)
    root.add_child(status_label)
    tension_bar = ProgressBar.new()
    tension_bar.position = Vector2(24,145)
    tension_bar.size = Vector2(230,22)
    tension_bar.max_value = 100
    tension_bar.visible = false
    root.add_child(tension_bar)
    _button(root,"ЗАБРОС",Vector2(-210,-100),Vector2(180,64),_cast)
    _button(root,"ПОДСЕЧКА",Vector2(-210,-174),Vector2(180,64),_hook)
    _button(root,"КАТУШКА",Vector2(-210,-248),Vector2(180,64),_reel)
    _button(root,"САДОК",Vector2(24,-100),Vector2(130,54),_keep_catch)
    _button(root,"МАГАЗИН",Vector2(24,-162),Vector2(130,54),_toggle_shop)
    _button(root,"ПРОДАТЬ",Vector2(24,-224),Vector2(130,54),_sell_catch)
    var help := Label.new()
    help.text = "WASD / стик — ходьба • свайп справа — обзор"
    help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    help.position = Vector2(24,-36)
    root.add_child(help)
    var joystick := Control.new()
    joystick.name = "JoystickArea"
    joystick.position = Vector2(24,-210)
    joystick.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
    joystick.size = Vector2(170,170)
    root.add_child(joystick)
    var ring := ColorRect.new()
    ring.position = Vector2(0,0)
    ring.size = Vector2(150,150)
    ring.color = Color(0.1,0.15,0.16,0.32)
    joystick.add_child(ring)
    _refresh_hud()

func _button(parent: Control, caption: String, offset: Vector2, size: Vector2, action: Callable) -> void:
    var b := Button.new()
    b.text = caption
    b.size = size
    b.anchor_left = 1.0
    b.anchor_right = 1.0
    b.anchor_top = 1.0
    b.anchor_bottom = 1.0
    b.position = offset
    b.add_theme_font_size_override("font_size", 18)
    b.pressed.connect(action)
    parent.add_child(b)

func _process(delta: float) -> void:
    time_of_day = fmod(time_of_day + delta * 0.0007, 1.0)
    if phase == "waiting":
        cast_timer += delta
        if cast_timer >= bite_delay:
            phase = "bite"
            _set_status("ПОКЛЁВКА! Жми «ПОДСЕЧКА»!")
    elif phase == "fight":
        tension = clampf(tension + (fish_power - 0.35) * delta * 18.0, 5.0, 100.0)
        if tension >= 96.0:
            phase = "ready"
            tension_bar.visible = false
            _set_status("Обрыв! Ослабь натяжение и следи за рывками.")
        tension_bar.value = tension
    _refresh_hud()

func _physics_process(delta: float) -> void:
    if player == null:
        return
    var input_vec := Input.get_vector("move_left","move_right","move_forward","move_back")
    if move_vector.length() > 0.15:
        input_vec = move_vector
    var direction := (player.transform.basis * Vector3(input_vec.x,0,input_vec.y)).normalized()
    player.velocity.x = direction.x * 4.5
    player.velocity.z = direction.z * 4.5
    if not player.is_on_floor():
        player.velocity.y -= 20.0 * delta
    else:
        player.velocity.y = -0.2
    player.move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        player.rotate_y(-event.relative.x * 0.0025)
        camera.rotate_x(-event.relative.y * 0.0025)
        camera.rotation.x = clampf(camera.rotation.x,-1.2,1.2)
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    elif event is InputEventScreenTouch:
        if event.pressed:
            look_touch = event.index
            last_touch = event.position
        elif event.index == look_touch:
            look_touch = -1
    elif event is InputEventScreenDrag and event.index == look_touch:
        var d: Vector2 = event.position - last_touch
        player.rotate_y(-d.x * 0.004)
        camera.rotate_x(-d.y * 0.004)
        camera.rotation.x = clampf(camera.rotation.x,-1.2,1.2)
        last_touch = event.position

func _cast() -> void:
    if phase != "ready":
        _set_status("Сначала закончи текущую рыбалку.")
        return
    phase = "waiting"
    cast_timer = 0.0
    bite_delay = randf_range(5.0,13.0)
    _set_status("Заброс выполнен. Следи за поплавком...")
    
func _hook() -> void:
    if phase == "bite":
        phase = "fight"
        tension = 35.0
        fish_power = randf_range(0.35,0.75)
        tension_bar.visible = true
        _set_status("Рыба на крючке! Нажимай «КАТУШКА», контролируй натяжение.")
    elif phase == "waiting":
        _set_status("Пока тихо. Жди поклёвку.")
    else:
        _set_status("Сейчас подсекать не нужно.")

func _reel() -> void:
    if phase != "fight":
        return
    tension = maxf(0.0,tension - 17.0)
    if randf() < 0.24:
        var fish := _random_fish()
        catches.append(fish)
        xp += int(fish.weight * 10.0)
        if xp >= level * 100:
            xp = 0
            level += 1
        phase = "ready"
        tension_bar.visible = false
        _set_status("Улов: %s — %.2f кг! Рыба в садке." % [fish.name,fish.weight])
        _save_game()
    else:
        fish_power = randf_range(0.25,0.9)
        _set_status("Подматывай! Натяжение %.0f%%" % tension)

func _random_fish() -> Dictionary:
    var names := ["Плотва","Окунь","Карась","Лещ","Щука"]
    var weights := [0.25,0.4,0.65,1.2,2.4]
    var i := randi_range(0,names.size()-1)
    return {"name":names[i],"weight":snappedf(randf_range(weights[i]*0.5,weights[i]*1.8),0.01),"price":int(weights[i]*35+10)}

func _keep_catch() -> void:
    if catches.is_empty():
        _set_status("Садок пуст. Поймай рыбу!")
        return
    _set_status("В садке %d рыб. Опыт: %d / уровень %d." % [catches.size(),xp,level])

func _sell_catch() -> void:
    if catches.is_empty():
        _set_status("Продавать пока нечего.")
        return
    var total := 0
    for fish in catches:
        total += int(fish.price)
    silver += total
    catches.clear()
    _save_game()
    _set_status("Улов продан за %d серебра." % total)

func _toggle_shop() -> void:
    shop_open = not shop_open
    if shop_open:
        _set_status("МАГАЗИН: червь 5 серебра • опарыш 8 • кукуруза 12. Баланс: %d" % silver)
        if silver >= 5:
            silver -= 5
            _set_status("Куплена порция червей за 5 серебра. Баланс: %d" % silver)
    else:
        _set_status("Магазин закрыт.")
    _save_game()

func _set_status(message: String) -> void:
    if status_label:
        status_label.text = message

func _refresh_hud() -> void:
    if silver_label:
        silver_label.text = "Fishing Legend   •   %d серебра   •   Ур. %d" % [silver,level]

func _save_game() -> void:
    var f := FileAccess.open(SAVE_PATH,FileAccess.WRITE)
    if f:
        f.store_string(JSON.stringify({"silver":silver,"xp":xp,"level":level,"catches":catches}))

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var f := FileAccess.open(SAVE_PATH,FileAccess.READ)
    if not f:
        return
    var parsed = JSON.parse_string(f.get_as_text())
    if typeof(parsed) == TYPE_DICTIONARY:
        silver = int(parsed.get("silver",silver))
        xp = int(parsed.get("xp",xp))
        level = int(parsed.get("level",level))
        catches.assign(parsed.get("catches",[]))
