extends Control

const MAP_W: float = 1670.0
const MAP_H: float = 942.0
const POLITICAL: Texture2D = preload("res://assets/political.png")
const BIOMES: Texture2D = preload("res://assets/biomes.png")
const RESOURCES: Texture2D = preload("res://assets/resources.png")
const SEA: Texture2D = preload("res://assets/sea.png")
const SUPPLY_BASE: Texture2D = preload("res://assets/supply_cached.png")
const OUTLINES: Array[Texture2D] = [preload("res://assets/outline_1.png"), preload("res://assets/outline_2.png"), preload("res://assets/outline_3.png"), preload("res://assets/outline_4.png"), preload("res://assets/outline_5.png")]
const BORDERS: Texture2D = preload("res://assets/boundaries.png")
const PROVINCE_IDS: Texture2D = preload("res://assets/province_ids.png")
const FLAGS: Array[Texture2D] = [preload("res://assets/flag_1.png"), preload("res://assets/flag_2.png"), preload("res://assets/flag_3.png"), preload("res://assets/flag_4.png"), preload("res://assets/flag_5.png")]
const NAMES: Array[String] = ["", "Нордланд", "Вестория", "Эльдара", "Монтара", "Саутвейл"]
const COLORS: Array[Color] = [Color("#84a7c1"), Color("#ed91ae"), Color("#92bd77"), Color("#e5c275"), Color("#b18fcd"), Color("#88b9d9")]
const TERRAIN_NAMES: Array[String] = ["Равнины", "Леса", "Горы", "Холмы", "Болота"]
const RESOURCE_NAMES: Array[String] = ["Плодородная земля", "Смешанные ресурсы", "Рудные земли", "Промышленный потенциал"]
const SAVE_PATH: String = "user://PoliticalEarth_v0_1_20.json"
# All speeds are km/h. Towed guns are vehicle-transported versions.
const BATTALIONS: Dictionary = {
    "infantry": {"label":"Пехота", "icon":"♟", "men":800,"attack":12,"defense":18,"org":70,"speed":4,"armor":0,"piercing":1,"supply":15},
    "cavalry": {"label":"Кавалерия", "icon":"♞", "men":800,"attack":13,"defense":15,"org":60,"speed":6,"armor":0,"piercing":1,"supply":18},
    "artillery": {"label":"Артиллерия", "icon":"✹", "men":500,"attack":35,"defense":6,"org":30,"speed":4,"armor":0,"piercing":5,"supply":25},
    "towed_artillery": {"label":"Моториз. артиллерия", "icon":"✹", "men":500,"attack":35,"defense":6,"org":30,"speed":12,"armor":0,"piercing":5,"supply":28,"fuel":true},
    "anti_tank": {"label":"ПТО", "icon":"⌖", "men":450,"attack":9,"hard_attack":100,"defense":8,"org":40,"speed":4,"armor":0,"piercing":60,"supply":19},
    "towed_anti_tank": {"label":"Моториз. ПТО", "icon":"⌖", "men":450,"attack":9,"hard_attack":100,"defense":8,"org":40,"speed":12,"armor":0,"piercing":60,"supply":22,"fuel":true},
    "anti_air": {"label":"ПВО", "icon":"✦", "men":450,"attack":11,"defense":10,"org":45,"speed":4,"armor":0,"piercing":8,"supply":18},
    "towed_anti_air": {"label":"Моториз. ПВО", "icon":"✦", "men":450,"attack":11,"defense":10,"org":45,"speed":12,"armor":0,"piercing":8,"supply":21,"fuel":true},
    "tanks": {"label":"Танки", "icon":"▰", "men":600,"attack":32,"defense":24,"org":45,"speed":8,"armor":65,"piercing":45,"supply":40,"fuel":true},
    "motorized": {"label":"Мотопехота", "icon":"▣", "men":750,"attack":14,"defense":18,"org":65,"speed":12,"armor":3,"piercing":4,"supply":27,"fuel":true},
    "engineers": {"label":"Инженеры", "icon":"⚒", "men":350,"attack":5,"defense":15,"org":55,"speed":4,"armor":0,"piercing":2,"supply":12},
    "recon": {"label":"Разведка", "icon":"◉", "men":250,"attack":5,"defense":8,"org":60,"speed":4,"armor":0,"piercing":3,"supply":9},
    "medics": {"label":"Медики", "icon":"✚", "men":250,"attack":1,"defense":6,"org":65,"speed":4,"armor":0,"piercing":0,"supply":10},
    "repair": {"label":"Ремонтная", "icon":"⚙", "men":250,"attack":1,"defense":6,"org":55,"speed":4,"armor":0,"piercing":0,"supply":10},
    "supply_company": {"label":"Рота снабжения", "icon":"▤", "men":250,"attack":1,"defense":6,"org":55,"speed":4,"armor":0,"piercing":0,"supply":10},
    "signals": {"label":"Рота связи", "icon":"⌁", "men":250,"attack":1,"defense":6,"org":55,"speed":4,"armor":0,"piercing":0,"supply":10},
    "sappers": {"label":"Сапёры", "icon":"⚒", "men":350,"attack":5,"defense":10,"org":50,"speed":4,"armor":0,"piercing":2,"supply":12}
}


var province_image: Image
var provinces: Dictionary = {}
var countries: Dictionary = {}
var divisions: Array[Dictionary] = []
var armies: Array[Dictionary] = []
var army_counter: int = 1
var player: int = 0
var selected_country: int = 0
var selected_province: int = -1
var mode: int = 0
var zoom: float = 1.0
var offset: Vector2 = Vector2.ZERO
var drag_mouse: bool = false
var mouse_last: Vector2 = Vector2.ZERO
var drag_length: float = 0.0
var touch_points: Dictionary = {}
var pinch_dist: float = 0.0
var day: int = 1
var month: int = 1
var year: int = 2000
var division_number: int = 1
var template_infantry: int = 3
var template_artillery: int = 1
var moving_division: int = -1
# Selection and orders. Drag with selection mode enabled to select a group.
var selected_division_ids: Array[int] = []
var selection_mode: bool = false
var route_order_mode: bool = false
var selection_button: Button
var route_button: Button
var clear_selection_button: Button
var selection_start: Vector2 = Vector2.ZERO
var selection_end: Vector2 = Vector2.ZERO
var selecting_rectangle: bool = false
var last_tap_ms: int = 0
var last_tap_pos: Vector2 = Vector2(-9999,-9999)
var last_touch_event_ms: int = -100000

var world_clock: Label
var speed: int = 0
var clock_accum: float = 0.0
var speed_buttons: Array[Button] = []
var map_mode_label: Label
var training_panel: PanelContainer
var editor_panel: PanelContainer
var template_list: VBoxContainer
var training_list: VBoxContainer
var editor_grid: GridContainer
var editor_stats: Label
var editor_effects: Label
var editor_combat_rows: VBoxContainer
var editor_needs_rows: VBoxContainer
var editor_support_rows: VBoxContainer
var editor_category: String = ""
var editor_name: Label
var editor_name_input: LineEdit
var editor_division_icon: TextureRect
var editor_icon_button: Button
var editor_icon_kind: String = "infantry"
var name_keyboard_open: bool = false
var cached_screen_height: float = 0.0
var settlement_ids: Array[int] = []
var company_picker: PanelContainer
var selected_company_slot: int = -1
var editing_index: int = 0
var editing_cells: Array[String] = []
var division_templates: Array[Dictionary] = []
var pending_train: int = -1
var training_batch_count: int = 1
var training_repeat_count: int = 1
var training_repeat_unlimited: bool = false
var training_queue: Array[Dictionary] = []
var training_next_id: int = 1
var refit_division_id: int = -1
var show_hidden_templates: bool = false
var game_menu_button: Button
var diplomacy_tab_buttons: Array[Button] = []
var game_menu_panel: PanelContainer
var dev_panel: PanelContainer
var developer_mode: bool = false
var developer_speed: bool = false
var game_log_panel: PanelContainer
var game_log_text: TextEdit
var feedback_timer: float = 0.0
var diplomacy_panel: PanelContainer
var diplomacy_flag: TextureRect
var diplomacy_name: Label
var diplomacy_details: Label
var diplomacy_relations_list: VBoxContainer
var diplomacy_war: Button
var diplomacy_actions_container: VBoxContainer
var diplomacy_overview_container: VBoxContainer
var diplomacy_tab: int = 0
var diplomacy_shown: bool = false
# Single tap immediately selects; second consecutive tap opens diplomacy.
var pending_province_click: int = -1
var pending_province_country: int = 0
var pending_province_position: Vector2 = Vector2.ZERO
var pending_province_timestamp: int = 0
const COUNTRY_DOUBLE_DETECTION_MS: int = 340
var wars: Dictionary = {}
var capitulated: Dictionary = {}
var occupation_texture: ImageTexture
var supply_texture: Texture2D = SUPPLY_BASE
var occupation_dirty: bool = false
var battle_fx_time: float = 0.0
var battle_redraw_clock: float = 0.0
var max_frame_ms: float = 0.0
var slow_frames: int = 0
var last_slow_frame_ms: float = 0.0

# Lightweight profiling. Timings cover only GDScript sections; GPU and OS work
# can appear in frame delays without appearing in these section samples.
var perf_sections: Dictionary = {}
var perf_spikes: Array[String] = []
var perf_frame_samples: int = 0
var perf_profile_enabled: bool = true

func _profile_finish(section: String, started_us: int) -> void:
    if not perf_profile_enabled:
        return
    var elapsed_ms: float = float(Time.get_ticks_usec() - started_us) / 1000.0
    var stat: Dictionary = perf_sections.get(section, {"n": 0, "total": 0.0, "max": 0.0, "last": 0.0, "over_16": 0})
    stat["n"] = int(stat["n"]) + 1
    stat["total"] = float(stat["total"]) + elapsed_ms
    stat["max"] = maxf(float(stat["max"]), elapsed_ms)
    stat["last"] = elapsed_ms
    if elapsed_ms >= 16.0:
        stat["over_16"] = int(stat["over_16"]) + 1
    perf_sections[section] = stat
    if elapsed_ms >= 50.0:
        perf_spikes.append("%s: %.1f мс · %02d.%02d.%04d" % [section,elapsed_ms,day,month,year])
        if perf_spikes.size() > 12:
            perf_spikes.pop_front()

func _profile_report() -> String:
    var lines: Array[String] = []
    lines.append("ПРОФИЛИРОВАНИЕ (мс: среднее / пик / последнее | вызовов | >16мс)")
    var sections: Array = perf_sections.keys()
    sections.sort_custom(func(a: String, b: String) -> bool:
        return float(perf_sections[a]["max"]) > float(perf_sections[b]["max"])
    )
    if sections.is_empty():
        lines.append("Нет замеров; выполните несколько игровых дней и действий")
    for section in sections:
        var p: Dictionary = perf_sections[section]
        var n: int = maxi(1, int(p["n"]))
        lines.append("%s: %.2f / %.2f / %.2f | %d | %d" % [section,float(p["total"])/float(n),float(p["max"]),float(p["last"]),n,int(p["over_16"])])
    lines.append("ПОСЛЕДНИЕ ДОЛГИЕ ОПЕРАЦИИ:")
    if perf_spikes.is_empty():
        lines.append("Нет зафиксированных операций >50 мс")
    else:
        for item in perf_spikes:
            lines.append(item)
    lines.append("Внимание: GPU, Android и ожидание кадров не измеряются этими таймерами")
    return "\n".join(PackedStringArray(lines))

func _profile_reset() -> void:
    perf_sections.clear()
    perf_spikes.clear()
    max_frame_ms = 0.0
    slow_frames = 0
    last_slow_frame_ms = 0.0

var in_battle: bool = false
var battle_progress: Dictionary = {}
var battle_reports: Dictionary = {}
var battle_panel: PanelContainer
var battle_details: Label
var battle_title: Label
var battle_units_row: HBoxContainer
var active_battle_id: int = -1
var status_flash: Label

var country_choice: PanelContainer
var choice_text: Label
var choice_btn: Button
var header: HBoxContainer
var flag_panel: PanelContainer
var flag_label: Label
var flag_tex: TextureRect
var stats_line: Label
var title_line: Label
var province_panel: PanelContainer
var province_title: Label
var province_text: Label
var farm_btn: Button
var supply_btn: Button
var port_btn: Button
var move_btn: Button
var division_panel: PanelContainer
var division_title: Label
var division_details: Label
var inspected_division_id: int = -1
var army_btn: Button
var templates_panel: PanelContainer
var templates_text: Label
var feedback: Label
var mode_buttons: Array[Button] = []
# State, parties and conscription. One law for each of the five nations.
const LAW_NAMES: Array[String] = ["Добровольцы", "Ограниченный призыв", "Обязательная служба", "Расширенный призыв", "Всеобщая мобилизация"]
const LAW_RATES: Array[float] = [0.03, 0.05, 0.08, 0.12, 0.20]
const PARTY_LABELS: Array[String] = ["Реформисты", "Традиционалисты", "Народный союз", "Военная партия"]
const PARTY_COLORS: Array[Color] = [Color("#7da6c7"),Color("#d9ab65"),Color("#91b78b"),Color("#bc7f8a")]
const GOVERNMENTS: Array[String] = ["", "Республика", "Парламентская республика", "Конституционная монархия", "Республика", "Парламентская республика"]
const LEADER_NAMES: Array[String] = ["", "Александр Рейн", "Михаил Вест", "Эдвард Эльдар", "Виктор Монт", "Сергей Вейл"]
var country_government: Dictionary = {}
var government_panel: PanelContainer
var government_body: VBoxContainer
var government_tab: int = 0
var law_detail_open: bool = false
var government_tab_buttons: Array[Button] = []
var gov_scroll: ScrollContainer
var government_countdown_label: Label
var government_rendered_law: int = -1
var government_rendered_pending: int = -2
var government_rendered_player: int = -1
var government_rendered_month: int = -1
var debug_button: Button
var debug_messages: Array[String] = []
var unit_drag_id: int = -1
var unit_drag_start: Vector2 = Vector2.ZERO
var unit_drag_pos: Vector2 = Vector2.ZERO
var unit_drag_active: bool = false
var unit_drag_destination: int = -1


func _ready() -> void:
    texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    if OS.has_feature("mobile"):
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
    clip_contents = true
    province_image = PROVINCE_IDS.get_image()
    province_image.convert(Image.FORMAT_RGBA8)
    _init_provinces()
    # Cache settlement locations for map drawing; avoid scanning all provinces per repaint.
    settlement_ids.clear()
    for settlement_id in provinces.keys():
        if str(provinces[settlement_id]["place"]) != "":
            settlement_ids.append(int(settlement_id))
    _init_countries()
    _spawn_border_divisions()
    _init_templates()
    # Every launch begins a new campaign; old saved games are not loaded.
    _recalculate_supply()
    _update_division_supply()
    var has_occupation: bool = false
    for id in provinces.keys():
        if int(provinces[id]["owner"]) != int(provinces[id]["controller"]):
            has_occupation = true
            break
    if has_occupation:
        _rebuild_occupation_texture()
    for id in provinces.keys():
        if bool(provinces[id]["depot"]) or bool(provinces[id]["port"]):
            _rebuild_supply_texture()
            break
    _build_ui()
    _apply_saved_ui_layout()
    game_menu_button.move_to_front()
    resized.connect(_fit_screen)
    call_deferred("_fit_screen")
    _refresh()

func _apply_saved_ui_layout() -> void:
    # Export from the companion Android-friendly browser layout editor.
    # On Android, place ui_layout.json in the project's root before import.
    var layout_path: String = "res://ui_layout.json"
    if not FileAccess.file_exists(layout_path):
        return
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(layout_path))
    if not (data is Dictionary):
        return
    var targets: Dictionary = {
        "editor": editor_panel,
        "training": training_panel,
        "government": government_panel,
        "diplomacy": diplomacy_panel,
        "province": province_panel
    }
    for key in targets.keys():
        if not data.has(key) or not (data[key] is Dictionary):
            continue
        var cfg: Dictionary = data[key]
        var node: Control = targets[key]
        if node == null:
            continue
        var x: float = clampf(float(cfg.get("x", 0)), 0.0, 0.95)
        var y: float = clampf(float(cfg.get("y", 0)), 0.0, 0.95)
        var w: float = clampf(float(cfg.get("w", 0.5)), 0.05, 1.0 - x)
        var h: float = clampf(float(cfg.get("h", 0.5)), 0.05, 1.0 - y)
        # Anchor layout to the available viewport. This prevents windows extending
        # outside the screen in both landscape tablet and phone aspect ratios.
        node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
        node.anchor_left = x
        node.anchor_top = y
        node.anchor_right = x + w
        node.anchor_bottom = y + h
        node.offset_left = 0.0
        node.offset_right = 0.0
        node.offset_top = 0.0
        node.offset_bottom = 0.0

func _init_provinces() -> void:
    var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/provinces.json"))
    if not (decoded is Array):
        return
    for item in decoded:
        var id: int = int(item["id"])
        provinces[id] = {"id": id, "owner": int(item["owner"]), "pos": Vector2(float(item["x"]), float(item["y"])), "terrain": int(item["terrain"]), "resource": int(item["resource"]), "slots": int(item["slots"]), "population": int(item["pop"]) * 150, "original_population": int(item["pop"]) * 150, "recruited":0, "neighbors": item["neighbors"], "polygons": item["polygons"], "coast": bool(item["coast"]), "farms": 0, "depot": false, "port": false, "place": "", "source": 0, "supply": 0, "controller": int(item["owner"])}
    for item in decoded:
        var id: int = int(item["id"])
        provinces[id]["place"] = str(item.get("place", ""))
        provinces[id]["source"] = int(item.get("source", 0))

func _init_countries() -> void:
    for n in range(1, 6):
        var population: int = 0
        for id in provinces.keys():
            if int(provinces[id]["owner"]) == n:
                population += int(provinces[id]["population"])
        countries[n] = {"population": population, "industry": 3}
        var base_support: Array = [34 + n * 2, 29 - n, 23 + n, 14 - n * 2]
        country_government[n] = {"law":0,"pending_law":-1,"law_days":0,"mobilization_ready":1.0,"parties":base_support,"war_days":0}

func _spawn_border_divisions() -> void:
    for nation in range(1, 6):
        var near_border: Array[int] = []
        for id in provinces.keys():
            var p: Dictionary = provinces[id]
            if int(p["owner"]) != nation:
                continue
            for neighbor in p["neighbors"]:
                if provinces.has(int(neighbor)) and int(provinces[int(neighbor)]["owner"]) != nation:
                    near_border.append(int(id))
                    break
        if near_border.is_empty():
            for id in provinces.keys():
                if int(provinces[id]["owner"]) == nation:
                    near_border.append(int(id))
        near_border.sort()
        var amount: int = near_border.size()
        for k in range(amount):
            var pid: int = near_border[k]
            _make_division(nation, pid, 3, 1)

func _make_division(nation: int, pid: int, inf: int, art: int) -> void:
    divisions.append({"id": division_number, "name": "%d-я дивизия" % division_number, "owner": nation, "province": pid, "infantry": inf, "artillery": art, "men": inf * 800 + art * 500, "equipment": 100, "org": 100, "supply": 100, "army": 0, "battle_target": -1, "route": [], "travel_from": pid, "experience": 0.0, "travel_progress":0.0, "max_men": inf * 800 + art * 500, "org_float":100.0, "equip_float":100.0, "hp":29.0, "level":2, "fortification":0.0, "supply_reserve":3.0, "refit_target":-1, "template_id":0})
    var companies: Array = []
    for i in range(inf):
        companies.append("infantry")
    for i in range(art):
        companies.append("artillery")
    divisions[divisions.size() - 1]["companies"] = companies
    division_number += 1

func _fit_screen() -> void:
    if size.x < 50.0 or size.y < 50.0:
        return
    # The Android editor's embedded viewport can shrink when the system keyboard appears.
    # Ignore such transient geometry changes: preserve camera zoom and map position.
    if name_keyboard_open or DisplayServer.virtual_keyboard_get_height() > 0:
        return
    if cached_screen_height > 0.0 and size.y < cached_screen_height * 0.70:
        return
    cached_screen_height = size.y
    zoom = maxf(size.y / MAP_H, size.x / MAP_W * 0.88)
    offset = Vector2((size.x - MAP_W * zoom) * 0.5, (size.y - MAP_H * zoom) * 0.5)
    _limit_camera()
    queue_redraw()

func _limit_camera() -> void:
    offset.y = clampf(offset.y, minf(0.0, size.y - MAP_H * zoom), 0.0)
    offset.x = fposmod(offset.x, MAP_W * zoom)

func _draw() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    var tex: Texture2D = POLITICAL
    if mode == 1:
        tex = BIOMES
    elif mode == 2:
        tex = RESOURCES
    elif mode == 3:
        tex = supply_texture
    var width: float = MAP_W * zoom
    if width < 1.0:
        _profile_finish("Карта: команды рисования", _perf_start_us)
        return
    var count: int = int(ceil(size.x / width)) + 3
    for k in range(count):
        var xx: float = offset.x + (float(k) - 1.0) * width
        if xx > size.x or xx + width < 0.0:
            continue
        draw_set_transform(Vector2(xx, offset.y), 0.0, Vector2(zoom, zoom))
        draw_texture(tex, Vector2.ZERO)
        if occupation_texture != null:
            draw_texture(occupation_texture, Vector2.ZERO)
        draw_texture(BORDERS, Vector2.ZERO)
        if mode == 3 and zoom >= 0.42:
            for id in provinces.keys():
                var p: Dictionary = provinces[id]
                var pos: Vector2 = p["pos"]
                var available: int = int(p["supply"]) - _province_demand(int(id))
                draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 5), str(available), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#11272d"))
        for id in settlement_ids:
            var p: Dictionary = provinces[id]
            if str(p["place"]) != "":
                var pos: Vector2 = p["pos"]
                var city_radius: float = 8.0 if str(p["place"]) == "Столица" else (5.0 if str(p["place"]) == "Город" else 3.0)
                draw_circle(pos, city_radius + 1.0, Color("#213843"))
                draw_circle(pos, maxf(1.0,city_radius - 1.0), Color("#ffe6aa"))
                if zoom > 0.7:
                    draw_string(ThemeDB.fallback_font, pos + Vector2(10, -4), str(p["place"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#1a2933"))
        var occupied_positions: Array[Vector2] = []
        var attackers_by_target: Dictionary = {}
        for battle_unit in divisions:
            var attack_pid: int = int(battle_unit.get("battle_target",-1))
            if attack_pid >= 0 and not attackers_by_target.has(attack_pid):
                attackers_by_target[attack_pid] = int(battle_unit["province"])
        for d in divisions:
            var pid: int = int(d["province"])
            if not provinces.has(pid):
                continue
            var division_pos: Vector2 = _division_position(d, occupied_positions)
            occupied_positions.append(division_pos)
            if selected_division_ids.has(int(d["id"])):
                _draw_division_route(d, division_pos)
            if int(d.get("travel_from", pid)) != pid and provinces.has(int(d.get("travel_from", pid))):
                var origin_pos: Vector2 = provinces[int(d["travel_from"])]["pos"]
                var time_fraction: float = clampf(clock_accum / _day_interval(), 0.0, 1.0) if speed > 0 else 1.0
                division_pos = origin_pos.lerp(division_pos, time_fraction)
            var target: int = int(d.get("battle_target", -1))
            var battle_pid: int = target
            var attacker_origin: int = pid
            if target < 0:
                if attackers_by_target.has(pid):
                    battle_pid = pid
                    attacker_origin = int(attackers_by_target[pid])
            if battle_pid >= 0 and provinces.has(battle_pid) and provinces.has(attacker_origin):
                var center: Vector2 = provinces[battle_pid]["pos"]
                var origin: Vector2 = provinces[attacker_origin]["pos"]
                var direction: Vector2 = (center - origin).normalized()
                if direction.length_squared() < 0.001:
                    direction = Vector2.RIGHT
                var advance: float = clampf(float(battle_progress.get(battle_pid,0.0)) / 100.0,0.0,1.0)
                var dist: float = clampf(center.distance_to(origin) * 0.38,18.0,46.0)
                var front: Vector2 = center + direction * (-dist + advance * dist * 1.85)
                var noise: float = sin(battle_fx_time*2.5 + float(int(d["id"]))) * 1.5
                if target >= 0:
                    division_pos = front - direction * 13.0 + direction.orthogonal() * noise
                else:
                    division_pos = front + direction * 13.0 + direction.orthogonal() * noise
                if target >= 0 and advance > 0.01:
                    # Render a narrow moving occupation trail, not a territory-wide fill.
                    var trail_start: Vector2 = front - direction * (advance * dist * 1.55 + 9.0)
                    draw_line(trail_start, front - direction * 9.0, COLORS[int(d["owner"])].lightened(0.16), 8.0, true)
                draw_circle(division_pos,16.0,Color("#efcd8a",0.18))
            var c: Color = COLORS[int(d["owner"])]
            draw_rect(Rect2(division_pos - Vector2(11, 8), Vector2(22, 16)), Color("#172a38"), true)
            draw_rect(Rect2(division_pos - Vector2(9, 6), Vector2(18, 12)), c, true)
            draw_line(division_pos + Vector2(-5, 0), division_pos + Vector2(5, 0), Color("#142431"), 2)
            # Compact per-division organization and supply bars.
            draw_rect(Rect2(division_pos + Vector2(-10,10),Vector2(20,3)),Color("#172b38"),true)
            draw_rect(Rect2(division_pos + Vector2(-10,10),Vector2(20.0*clampf(float(d["org"])/100.0,0.0,1.0),3)),Color("#81cb78") if int(d["org"]) >= 30 else Color("#e1a25b"),true)
            draw_rect(Rect2(division_pos + Vector2(-10,14),Vector2(20,3)),Color("#172b38"),true)
            draw_rect(Rect2(division_pos + Vector2(-10,14),Vector2(20.0*clampf(float(d["equipment"])/100.0,0.0,1.0),3)),Color("#7dbfe5"),true)
            if selected_division_ids.has(int(d["id"])):
                draw_rect(Rect2(division_pos - Vector2(14,11), Vector2(28,22)), Color("#fff3a5"), false, 2.5)
        # Clickable circular battle progress markers.
        for reported in battle_reports.keys():
            var battle_pid: int = int(reported)
            if not provinces.has(battle_pid):
                continue
            var battle_pos: Vector2 = provinces[battle_pid]["pos"]
            var fraction: float = clampf(float(battle_reports[battle_pid].get("advantage",0.5)),0.0,1.0)
            var radius: float = 17.0
            var player_attacking: bool = int(battle_reports[battle_pid].get("attacker",0)) == player
            var player_defending: bool = int(battle_reports[battle_pid].get("defender",0)) == player
            var my_fraction: float = fraction if player_attacking else (1.0-fraction if player_defending else fraction)
            var fill: Color = Color("#ee5164").lerp(Color("#35d789"),my_fraction)
            if player_defending:
                var hex_points: PackedVector2Array = PackedVector2Array()
                for ix in range(6):
                    var an: float = PI/6.0 + TAU*float(ix)/6.0
                    hex_points.append(battle_pos+Vector2(cos(an),sin(an))*(radius+3.0))
                draw_colored_polygon(hex_points,fill)
            else:
                draw_circle(battle_pos,radius,fill)
            draw_arc(battle_pos,radius-3.0,-PI/2.0,-PI/2.0+TAU*my_fraction,32,Color("#fff6b5",0.85),3.0,true)
            draw_string(ThemeDB.fallback_font,battle_pos+Vector2(-12,5),"%d" % int(round(my_fraction*100.0)),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.WHITE)
        if selected_country > 0 and selected_country != player and player > 0:
            draw_texture(OUTLINES[selected_country - 1], Vector2.ZERO, Color.WHITE)
        if selected_province >= 0 and provinces.has(selected_province):
            var selected_p: Dictionary = provinces[selected_province]
            for raw in selected_p["polygons"]:
                var points: PackedVector2Array = PackedVector2Array()
                for xy in raw:
                    points.append(Vector2(float(xy[0]), float(xy[1])))
                if points.size() > 2:
                    points.append(points[0])
                    draw_polyline(points, Color.WHITE, 2.0, false)
        draw_set_transform(Vector2.ZERO)
    if selecting_rectangle and selection_mode:
        draw_rect(Rect2(selection_start, selection_end - selection_start).abs(), Color("#ffe4a0",0.13),true)
    if unit_drag_active and unit_drag_id >= 0:
        draw_line(unit_drag_start,unit_drag_pos,Color("#fff0a9"),3.0,true)
        draw_circle(unit_drag_pos,7.0,Color("#f7d18a"))
        if provinces.has(unit_drag_destination):
            var target_prov: Dictionary = provinces[unit_drag_destination]
            for polygon in target_prov["polygons"]:
                var outline: PackedVector2Array = PackedVector2Array()
                for xy in polygon:
                    outline.append(offset + Vector2(float(xy[0]),float(xy[1]))*zoom)
                if outline.size() >= 3:
                    outline.append(outline[0])
                    draw_polyline(outline,Color.WHITE,2.0,false)
        draw_rect(Rect2(selection_start, selection_end - selection_start).abs(), Color("#ffe4a0"),false,2.0)
    _profile_finish("Карта: команды рисования", _perf_start_us)

func _day_interval() -> float:
    return 0.01 if developer_mode and developer_speed else [99999.0, 1.5, 0.5, 0.16][speed]

func _draw_division_route(d: Dictionary, at: Vector2) -> void:
    var points: PackedVector2Array = PackedVector2Array([at])
    var route: Array = d.get("route", [])
    if int(d.get("battle_target", -1)) >= 0:
        var battle_goal: int = int(d["battle_target"])
        if provinces.has(battle_goal):
            points.append(provinces[battle_goal]["pos"])
    for raw_pid in route:
        var next_pid: int = int(raw_pid)
        if provinces.has(next_pid):
            var p: Vector2 = provinces[next_pid]["pos"]
            if points[points.size() - 1].distance_to(p) > 0.01:
                points.append(p)
    if points.size() < 2:
        return
    draw_polyline(points,Color("#192932"),6.0,true)
    draw_polyline(points,Color("#71808a"),3.0,true)
    if points.size() > 1:
        var head_progress: float = clampf(float(d.get("travel_progress",0.0)),0.0,1.0)
        var active_start: Vector2 = points[0]
        var active_end: Vector2 = points[0].lerp(points[1],head_progress)
        draw_line(active_start,active_end,Color("#ffe198"),4.5,true)
    for i in range(1,points.size()):
        var direction: Vector2 = (points[i] - points[i-1]).normalized()
        var head: Vector2 = points[i]
        draw_line(head,head - direction.rotated(0.55)*13.0,Color("#f9e6a3"),3.0)
        draw_line(head,head - direction.rotated(-0.55)*13.0,Color("#f9e6a3"),3.0)

func _division_position(d: Dictionary, occupied_positions: Array[Vector2]) -> Vector2:
    var pid: int = int(d["province"])
    var center: Vector2 = provinces[pid]["pos"]
    var placement_seed: int = int(d["id"])
    for step in range(32):
        var angle: float = float((placement_seed * 137 + step * 47) % 360) * PI / 180.0
        var radius: float = float(14 + ((placement_seed * 11 + step * 13) % 42))
        var pt: Vector2 = center + Vector2(cos(angle), sin(angle)) * radius
        if pt.x < 0 or pt.y < 0 or pt.x >= MAP_W or pt.y >= MAP_H:
            continue
        if _province_id_at_map(pt) != pid:
            continue
        var valid: bool = true
        for used in occupied_positions:
            if pt.distance_to(used) < 26.0:
                valid = false
                break
        if valid:
            return pt
    return center + Vector2(float(placement_seed % 5) * 12.0, float((placement_seed / 5.0)) * 12.0)

func _province_id_at_map(map_pos: Vector2) -> int:
    var pixel: Color = province_image.get_pixel(int(fposmod(map_pos.x, MAP_W)), clampi(int(map_pos.y),0,int(MAP_H)-1))
    return int(round(pixel.r * 255.0)) + 256 * int(round(pixel.g * 255.0))

func _ui_button(text_value: String, callback: Callable, width_value: float = 0.0) -> Button:
    var b: Button = Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(width_value, 43)
    b.add_theme_font_size_override("font_size", 19)
    b.add_theme_color_override("font_color", Color("#f1e5c7"))
    b.add_theme_color_override("font_hover_color", Color("#fff8da"))
    var normal: StyleBoxFlat = StyleBoxFlat.new()
    normal.bg_color = Color("#253b49")
    normal.border_color = Color("#ad946b")
    normal.set_border_width_all(1)
    normal.set_corner_radius_all(4)
    normal.content_margin_left = 8
    normal.content_margin_right = 8
    normal.content_margin_top = 4
    normal.content_margin_bottom = 4
    var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#416077")
    hover.border_color = Color("#eccb8c")
    var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("#886e4e")
    b.add_theme_stylebox_override("normal",normal)
    b.add_theme_stylebox_override("hover",hover)
    b.add_theme_stylebox_override("pressed",pressed)
    b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
    b.pressed.connect(func() -> void:
        callback.call()
        get_viewport().set_input_as_handled()
    )
    return b

func _plain_panel(bg: Color) -> PanelContainer:
    var panel: PanelContainer = PanelContainer.new()
    panel.mouse_filter = Control.MOUSE_FILTER_STOP
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = Color("#c1a277")
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    style.shadow_color = Color("#10162080")
    style.shadow_size = 4
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    panel.add_theme_stylebox_override("panel", style)
    return panel

func _build_ui() -> void:
    country_choice = _plain_panel(Color("#263b48f5"))
    country_choice.anchor_left = 0.5
    country_choice.anchor_right = 0.5
    country_choice.offset_left = -215
    country_choice.offset_right = 215
    country_choice.offset_top = 12
    country_choice.offset_bottom = 77
    add_child(country_choice)
    var pick_row: HBoxContainer = HBoxContainer.new()
    country_choice.add_child(pick_row)
    choice_text = Label.new()
    choice_text.add_theme_font_size_override("font_size", 20)
    choice_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    pick_row.add_child(choice_text)
    choice_btn = _ui_button("Играть", _choose_country)
    pick_row.add_child(choice_btn)

    # Compact fixed-size header: the source flags are 120 x 80 (3:2).
    # Never scale them into an incorrectly shaped texture rectangle.
    header = HBoxContainer.new()
    header.anchor_left = 0.0
    header.anchor_right = 0.0
    header.offset_left = 0.0
    header.anchor_right = 0.53
    header.offset_right = 0.0
    header.offset_top = 0.0
    header.offset_bottom = 72.0
    header.add_theme_constant_override("separation", 0)
    add_child(header)
    flag_panel = PanelContainer.new()
    flag_panel.custom_minimum_size = Vector2(108, 72)
    flag_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    flag_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    var flag_style: StyleBoxFlat = StyleBoxFlat.new()
    flag_style.bg_color = Color("#233c4a")
    flag_style.border_color = Color("#c1a277")
    flag_style.set_border_width_all(2)
    flag_style.content_margin_left = 0
    flag_style.content_margin_right = 0
    flag_style.content_margin_top = 0
    flag_style.content_margin_bottom = 0
    flag_panel.add_theme_stylebox_override("panel", flag_style)
    header.add_child(flag_panel)
    flag_tex = TextureRect.new()
    flag_tex.custom_minimum_size = Vector2(108, 72)
    flag_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    flag_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    flag_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
    flag_panel.add_child(flag_tex)
    var open_gov_button: Button = Button.new()
    open_gov_button.flat = true
    open_gov_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    open_gov_button.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
    open_gov_button.pressed.connect(func() -> void:
        _open_government()
        get_viewport().set_input_as_handled()
    )
    flag_panel.add_child(open_gov_button)
    flag_label = Label.new()
    var bars: VBoxContainer = VBoxContainer.new()
    bars.custom_minimum_size.x = 500.0
    bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    bars.add_theme_constant_override("separation", 0)
    header.add_child(bars)
    var thin: PanelContainer = _plain_panel(Color("#263e4bf4"))
    thin.custom_minimum_size.y = 27.0
    bars.add_child(thin)
    stats_line = Label.new()
    stats_line.add_theme_font_size_override("font_size", 16)
    thin.add_child(stats_line)
    var big: PanelContainer = _plain_panel(Color("#2d4859fa"))
    big.custom_minimum_size.y = 43.0
    bars.add_child(big)
    var bigrow: HBoxContainer = HBoxContainer.new()
    big.add_child(bigrow)
    title_line = Label.new()
    title_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title_line.add_theme_font_size_override("font_size", 18)
    bigrow.add_child(title_line)
    army_btn = _ui_button("⚔", _show_training, 58)
    army_btn.add_theme_font_size_override("font_size", 24)
    bigrow.add_child(army_btn)

    var clock_panel: PanelContainer = _plain_panel(Color("#263d50f2"))
    clock_panel.anchor_left = 1.0
    clock_panel.anchor_right = 1.0
    clock_panel.offset_left = -349
    clock_panel.offset_right = 0
    clock_panel.offset_top = 0
    clock_panel.offset_bottom = 64
    add_child(clock_panel)
    var clock_row: HBoxContainer = HBoxContainer.new()
    clock_panel.add_child(clock_row)
    world_clock = Label.new()
    world_clock.add_theme_font_size_override("font_size", 19)
    world_clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    clock_row.add_child(world_clock)
    for i in range(4):
        var value: int = i
        var symbol: String = ["Ⅱ", "▶", "▶▶", "▶▶▶"][i]
        var b: Button = _ui_button(symbol, func() -> void: _set_speed(value), 52)
        clock_row.add_child(b)
        speed_buttons.append(b)
    _set_speed(0)

    province_panel = _plain_panel(Color("#243b4af8"))
    province_panel.anchor_top = 1.0
    province_panel.anchor_bottom = 1.0
    province_panel.offset_left = 0
    province_panel.offset_right = 365
    province_panel.offset_top = -195
    province_panel.offset_bottom = 0
    add_child(province_panel)
    var province_v: VBoxContainer = VBoxContainer.new()
    province_v.add_theme_constant_override("separation", 7)
    province_panel.add_child(province_v)
    var province_row: HBoxContainer = HBoxContainer.new()
    province_v.add_child(province_row)
    province_title = Label.new()
    province_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    province_title.add_theme_font_size_override("font_size", 23)
    province_row.add_child(province_title)
    province_row.add_child(_ui_button("×", _clear_map_selection, 40))
    province_text = Label.new()
    province_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    province_text.custom_minimum_size.x = 325.0
    province_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    province_text.add_theme_font_size_override("font_size", 18)
    province_text.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    province_text.clip_text = false
    province_v.add_child(province_text)
    var row1: HBoxContainer = HBoxContainer.new()
    # Construction controls are kept disabled in this informational card.
    farm_btn = _ui_button("Ферма", _build_farm)
    supply_btn = _ui_button("Пункт", _build_depot)
    port_btn = _ui_button("Порт", _build_port)
    row1.visible = false
    row1.add_child(farm_btn)
    farm_btn.visible = false
    row1.add_child(supply_btn)
    row1.add_child(port_btn)
    # Divisions receive orders by dragging their map counters.

    division_panel = _plain_panel(Color("#243745f9"))
    division_panel.anchor_top = 1.0
    division_panel.anchor_bottom = 1.0
    division_panel.offset_left = 0
    division_panel.offset_right = 385
    division_panel.offset_top = -345
    division_panel.offset_bottom = 0
    add_child(division_panel)
    var unit_stack: VBoxContainer = VBoxContainer.new()
    unit_stack.add_theme_constant_override("separation", 10)
    division_panel.add_child(unit_stack)
    var unit_header: HBoxContainer = HBoxContainer.new()
    unit_stack.add_child(unit_header)
    division_title = Label.new()
    division_title.add_theme_font_size_override("font_size", 23)
    division_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    unit_header.add_child(division_title)
    unit_header.add_child(_ui_button("×", func() -> void: inspected_division_id = -1; _refresh(), 40))
    division_details = Label.new()
    division_details.add_theme_font_size_override("font_size", 17)
    division_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    division_details.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    unit_stack.add_child(division_details)
    # Drag divisions directly on the map to issue movement orders.
    unit_stack.add_child(_ui_button("⇄ Сменить шаблон", _start_refit))
    unit_stack.add_child(_ui_button("✕ Расформировать", _disband_inspected))
    division_panel.visible = false

    var modes: HBoxContainer = HBoxContainer.new()
    modes.anchor_left = 1.0
    modes.anchor_right = 1.0
    modes.anchor_top = 0.0
    modes.anchor_bottom = 0.0
    modes.offset_left = -287
    modes.offset_right = -9
    modes.offset_top = 71
    modes.offset_bottom = 140
    modes.add_theme_constant_override("separation", 7)
    add_child(modes)
    var icons: Array[String] = ["◎", "▲", "◆", "≋"]
    for i in range(4):
        var index: int = i
        var b: Button = _ui_button(icons[i], func() -> void: _set_mode(index), 62)
        b.custom_minimum_size.y = 62
        b.add_theme_font_size_override("font_size", 26)
        modes.add_child(b)
        mode_buttons.append(b)
    map_mode_label = Label.new()
    map_mode_label.anchor_left = 1.0
    map_mode_label.anchor_right = 1.0
    map_mode_label.anchor_top = 0.0
    map_mode_label.anchor_bottom = 0.0
    map_mode_label.offset_left = -282
    map_mode_label.offset_right = -10
    map_mode_label.offset_top = 145
    map_mode_label.offset_bottom = 169
    map_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    map_mode_label.add_theme_font_size_override("font_size", 19)
    map_mode_label.add_theme_color_override("font_color", Color("#142f41"))
    map_mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(map_mode_label)
    _set_mode(mode)

    _build_government_ui()
    _build_game_menu()

    training_panel = _plain_panel(Color("#1e3040f9"))
    training_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    training_panel.anchor_left = 0.08
    training_panel.anchor_right = 0.92
    training_panel.anchor_top = 0.18
    training_panel.anchor_bottom = 0.86
    training_panel.offset_left = 0
    training_panel.offset_right = 0
    training_panel.offset_top = 0
    training_panel.offset_bottom = 0
    add_child(training_panel)
    var training_root: VBoxContainer = VBoxContainer.new()
    training_panel.add_child(training_root)
    var t_top: HBoxContainer = HBoxContainer.new()
    training_root.add_child(t_top)
    var t_title: Label = Label.new()
    t_title.text = "⚔   ПОДГОТОВКА ДИВИЗИЙ"
    t_title.add_theme_font_size_override("font_size", 25)
    t_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    t_top.add_child(t_title)
    t_top.add_child(_ui_button("Закрыть ×", _close_army_windows))
    var training_h: HBoxContainer = HBoxContainer.new()
    training_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
    training_root.add_child(training_h)
    var left: ScrollContainer = ScrollContainer.new()
    left.custom_minimum_size.x = 465.0
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left.size_flags_stretch_ratio = 1.25
    left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    training_h.add_child(left)
    training_list = VBoxContainer.new()
    training_list.custom_minimum_size.x = 440.0
    training_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    training_list.add_theme_constant_override("separation", 7)
    left.add_child(training_list)
    var separator: VSeparator = VSeparator.new()
    training_h.add_child(separator)
    var right: ScrollContainer = ScrollContainer.new()
    right.custom_minimum_size.x = 345
    right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.size_flags_stretch_ratio = 0.95
    right.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    training_h.add_child(right)
    template_list = VBoxContainer.new()
    template_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    right.add_child(template_list)
    training_panel.visible = false

    # Compact division editor: left specs, center battalions with support below, right picker.
    editor_panel = _plain_panel(Color("#142736fa"))
    editor_panel.anchor_left = 0.18
    editor_panel.anchor_right = 0.82
    editor_panel.anchor_top = 0.19
    editor_panel.anchor_bottom = 0.84
    editor_panel.offset_left = 0
    editor_panel.offset_right = 0
    editor_panel.offset_top = 0
    editor_panel.offset_bottom = 0
    editor_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(editor_panel)
    var editor_v: VBoxContainer = VBoxContainer.new()
    editor_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
    editor_v.add_theme_constant_override("separation", 5)
    editor_panel.add_child(editor_v)
    var editor_top: HBoxContainer = HBoxContainer.new()
    editor_top.add_theme_constant_override("separation", 4)
    editor_v.add_child(editor_top)
    var editor_heading: Label = Label.new()
    editor_heading.text = "КОНСТРУКТОР ДИВИЗИЙ"
    editor_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    editor_heading.add_theme_font_size_override("font_size", 18)
    editor_top.add_child(editor_heading)
    editor_top.add_child(_ui_button("×", _close_editor, 34))
    var editor_body: HBoxContainer = HBoxContainer.new()
    editor_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    editor_body.add_theme_constant_override("separation", 6)
    editor_v.add_child(editor_body)
    # Dedicated top-left editor: the division icon is selectable, and its name editable.
    var left_stats: VBoxContainer = VBoxContainer.new()
    left_stats.custom_minimum_size.x = 245
    left_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left_stats.size_flags_stretch_ratio = 0.84
    left_stats.add_theme_constant_override("separation", 4)
    editor_body.add_child(left_stats)
    var identity_panel: PanelContainer = _plain_panel(Color("#1c3342fa"))
    left_stats.add_child(identity_panel)
    var identity_box: VBoxContainer = VBoxContainer.new()
    identity_panel.add_child(identity_box)
    identity_box.add_child(_government_label("НАЗВАНИЕ И ЗНАЧОК ДИВИЗИИ", 15))
    var identity_row: HBoxContainer = HBoxContainer.new()
    identity_row.add_theme_constant_override("separation", 6)
    identity_box.add_child(identity_row)
    editor_icon_button = _ui_button("", _cycle_division_icon, 64)
    editor_icon_button.custom_minimum_size.y = 62
    editor_icon_button.expand_icon = false
    identity_row.add_child(editor_icon_button)
    editor_division_icon = TextureRect.new()
    editor_division_icon.visible = false
    identity_row.add_child(editor_division_icon)
    editor_name_input = LineEdit.new()
    editor_name_input.placeholder_text = ""
    editor_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    editor_name_input.add_theme_font_size_override("font_size", 17)
    editor_name_input.focus_entered.connect(func() -> void:
        name_keyboard_open = true
    )
    editor_name_input.focus_exited.connect(func() -> void:
        name_keyboard_open = false
    )
    identity_row.add_child(editor_name_input)
    editor_name = Label.new()
    editor_name.visible = false
    identity_box.add_child(editor_name)
    var needs_band: HBoxContainer = HBoxContainer.new()
    left_stats.add_child(needs_band)
    editor_needs_rows = _editor_section(needs_band, "СОСТАВ И ОБЕСПЕЧЕНИЕ")
    var combat_band: HBoxContainer = HBoxContainer.new()
    left_stats.add_child(combat_band)
    editor_combat_rows = _editor_section(combat_band, "БОЕВЫЕ ХАРАКТЕРИСТИКИ")
    var center_stack: VBoxContainer = VBoxContainer.new()
    center_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center_stack.size_flags_stretch_ratio = 1.46
    center_stack.add_theme_constant_override("separation", 5)
    editor_body.add_child(center_stack)
    var grid_block: VBoxContainer = VBoxContainer.new()
    grid_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    center_stack.add_child(grid_block)
    grid_block.add_child(_government_label("СОСТАВ ДИВИЗИИ · 5 × 4", 17))
    editor_grid = GridContainer.new()
    editor_grid.columns = 5
    editor_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    editor_grid.add_theme_constant_override("h_separation", 4)
    editor_grid.add_theme_constant_override("v_separation", 3)
    grid_block.add_child(editor_grid)
    editor_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
    grid_block.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    var support_band: HBoxContainer = HBoxContainer.new()
    support_band.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    center_stack.add_child(support_band)
    editor_support_rows = _editor_section(support_band, "СПЕЦИАЛЬНЫЕ МОДИФИКАТОРЫ")
    company_picker = _plain_panel(Color("#1d3442fa"))
    company_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    company_picker.size_flags_stretch_ratio = 0.63
    company_picker.mouse_filter = Control.MOUSE_FILTER_STOP
    editor_body.add_child(company_picker)
    var editor_bottom: HBoxContainer = HBoxContainer.new()
    editor_v.add_child(editor_bottom)
    editor_bottom.add_child(_ui_button("← Назад", _close_editor, 96))
    editor_bottom.add_child(_ui_button("⟲ Сбросить", _reset_template, 109))
    editor_bottom.add_spacer(false)
    editor_bottom.add_child(_ui_button("✓ Сохранить шаблон", _save_template, 172))
    editor_panel.visible = false

    diplomacy_panel = _plain_panel(Color("#202f3df8"))
    diplomacy_panel.offset_left = 0
    diplomacy_panel.offset_right = 425
    diplomacy_panel.anchor_top = 1.0
    diplomacy_panel.anchor_bottom = 1.0
    diplomacy_panel.offset_top = -480
    diplomacy_panel.offset_bottom = 0
    diplomacy_panel.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(diplomacy_panel)
    var dip_v: VBoxContainer = VBoxContainer.new()
    dip_v.add_theme_constant_override("separation", 7)
    diplomacy_panel.add_child(dip_v)
    var dip_header: HBoxContainer = HBoxContainer.new()
    dip_v.add_child(dip_header)
    diplomacy_flag = TextureRect.new()
    diplomacy_flag.custom_minimum_size = Vector2(72,48)
    diplomacy_flag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    diplomacy_flag.stretch_mode = TextureRect.STRETCH_SCALE
    dip_header.add_child(diplomacy_flag)
    diplomacy_name = Label.new()
    diplomacy_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    diplomacy_name.add_theme_font_size_override("font_size",23)
    dip_header.add_child(diplomacy_name)
    dip_header.add_child(_ui_button("×", _close_diplomacy, 40))
    var dip_split: HBoxContainer = HBoxContainer.new()
    dip_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dip_split.add_theme_constant_override("separation",8)
    dip_v.add_child(dip_split)
    var dip_left: VBoxContainer = VBoxContainer.new()
    dip_left.custom_minimum_size.x = 238
    dip_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dip_split.add_child(dip_left)
    var tabs: HBoxContainer = HBoxContainer.new()
    tabs.add_theme_constant_override("separation",4)
    dip_left.add_child(tabs)
    for tab_index in range(2):
        var tab_id: int = tab_index
        var tab_button: Button = _ui_button(["Дипломатия", "Сводка"][tab_index],func() -> void: _set_diplomacy_tab(tab_id))
        tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        tabs.add_child(tab_button)
        diplomacy_tab_buttons.append(tab_button)
    diplomacy_actions_container = VBoxContainer.new()
    dip_left.add_child(diplomacy_actions_container)
    diplomacy_war = _ui_button("⚔ Объявить войну",_declare_war)
    diplomacy_actions_container.add_child(diplomacy_war)
    diplomacy_actions_container.add_child(_ui_button("Играть за страну",_play_as_diplomatic_country))
    diplomacy_overview_container = VBoxContainer.new()
    dip_left.add_child(diplomacy_overview_container)
    diplomacy_overview_container.visible = false
    diplomacy_details = Label.new()
    diplomacy_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    diplomacy_details.add_theme_font_size_override("font_size",18)
    diplomacy_overview_container.add_child(diplomacy_details)
    var countries_row: HBoxContainer = HBoxContainer.new()
    dip_left.add_child(countries_row)
    countries_row.add_child(_ui_button("◀",func() -> void: _switch_diplomacy(-1),48))
    countries_row.add_child(_ui_button("▶",func() -> void: _switch_diplomacy(1),48))
    var dip_right: VBoxContainer = VBoxContainer.new()
    dip_right.custom_minimum_size.x = 136
    dip_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    dip_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dip_split.add_child(dip_right)
    var relations_title: Label = _government_label("ОТНОШЕНИЯ",16)
    dip_right.add_child(relations_title)
    var relations_box: PanelContainer = _plain_panel(Color("#283d4c"))
    relations_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
    dip_right.add_child(relations_box)
    diplomacy_relations_list = VBoxContainer.new()
    diplomacy_relations_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    relations_box.add_child(diplomacy_relations_list)
    diplomacy_panel.visible = false
    # Battle inspector: manually opened by clicking combat marker or province.
    battle_panel = _plain_panel(Color("#1b2c3deF"))
    battle_panel.anchor_left = 1.0
    battle_panel.anchor_right = 1.0
    battle_panel.offset_left = -770
    battle_panel.offset_right = -5
    battle_panel.offset_top = 90
    battle_panel.offset_bottom = 590
    add_child(battle_panel)
    var battle_box: VBoxContainer = VBoxContainer.new()
    battle_box.add_theme_constant_override("separation", 9)
    battle_panel.add_child(battle_box)
    var battle_top: HBoxContainer = HBoxContainer.new()
    battle_box.add_child(battle_top)
    battle_title = Label.new()
    battle_title.text = "⚔  СРАЖЕНИЕ"
    battle_title.add_theme_font_size_override("font_size", 24)
    battle_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    battle_top.add_child(battle_title)
    battle_top.add_child(_ui_button("×", func() -> void: battle_panel.visible = false, 40))
    battle_details = Label.new()
    battle_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    battle_details.add_theme_font_size_override("font_size", 20)
    battle_box.add_child(battle_details)
    var battle_scroll: ScrollContainer = ScrollContainer.new()
    battle_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    battle_box.add_child(battle_scroll)
    battle_units_row = HBoxContainer.new()
    battle_units_row.add_theme_constant_override("separation",12)
    battle_units_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    battle_scroll.add_child(battle_units_row)
    battle_panel.visible = false
    templates_panel = training_panel
    var orders_row: HBoxContainer = HBoxContainer.new()
    orders_row.anchor_top = 1.0
    orders_row.anchor_bottom = 1.0
    orders_row.offset_left = 435
    orders_row.offset_right = 435
    orders_row.offset_top = -62
    orders_row.offset_bottom = -9
    orders_row.add_theme_constant_override("separation",6)
    add_child(orders_row)
    selection_button = _ui_button("□ Выделить", _toggle_division_selection, 155)
    # Removed hidden legacy control; rectangle selection is handled on the map.
    selection_button.visible = false
    route_button = null
    clear_selection_button = null
    feedback = Label.new()
    feedback.anchor_left = 0.39
    feedback.anchor_right = 0.61
    feedback.anchor_top = 1.0
    feedback.anchor_bottom = 1.0
    feedback.offset_top = -49
    feedback.offset_bottom = -6
    feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    feedback.add_theme_font_size_override("font_size", 18)
    feedback.add_theme_color_override("font_color", Color("#fff1be"))
    feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(feedback)
    feedback.visible = false
    game_menu_button.move_to_front()

func _set_mode(index: int) -> void:
    mode = index
    if map_mode_label != null:
        map_mode_label.text = ["ПОЛИТИЧЕСКАЯ", "МЕСТНОСТЬ", "РЕСУРСЫ", "СНАБЖЕНИЕ"][mode]
    for i in range(mode_buttons.size()):
        var style: StyleBoxFlat = StyleBoxFlat.new()
        style.bg_color = Color("#356d8a") if i == mode else Color("#203846")
        style.border_color = Color("#f4d36d") if i == mode else Color("#8397a5")
        style.set_border_width_all(3 if i == mode else 1)
        style.set_corner_radius_all(28)
        mode_buttons[i].add_theme_stylebox_override("normal", style)
        mode_buttons[i].add_theme_stylebox_override("hover", style)
        mode_buttons[i].add_theme_stylebox_override("pressed", style)
    queue_redraw()

func _short_number(v: int) -> String:
    if abs(v) >= 1000000:
        return "%.1fМ" % (float(v) / 1000000.0)
    if abs(v) >= 1000:
        return "%.1fТ" % (float(v) / 1000.0)
    return str(v)

func _refresh() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    if stats_line == null:
        _profile_finish("Интерфейс: общий", _perf_start_us)
        return
    country_choice.visible = player == 0
    choice_btn.visible = selected_country > 0
    choice_text.text = NAMES[selected_country] if selected_country > 0 else "Выберите страну"
    header.visible = player > 0
    if world_clock != null:
        var next_date: String = "%02d.%02d.%04d" % [day, month, year]
        if world_clock.text != next_date:
            world_clock.text = next_date
    if player > 0:
        if flag_tex.texture != FLAGS[player - 1]:
            flag_tex.texture = FLAGS[player - 1]
        var next_stats: String = "♟ %s" % _short_number(_nation_recruitable(player))
        if stats_line.text != next_stats:
            stats_line.text = next_stats
        if title_line.text != NAMES[player]:
            title_line.text = NAMES[player]
    province_panel.visible = selected_province >= 0 and provinces.has(selected_province) and player > 0
    if province_panel.visible:
        var p: Dictionary = provinces[selected_province]
        province_title.text = "ПРОВИНЦИЯ %d" % selected_province
        var units: int = 0
        for d in divisions:
            if int(d["province"]) == selected_province:
                units += 1
        var place: String = str(p["place"])
        if place == "":
            place = "Без поселения"
        province_text.text = "%s · %s\nМестность: %s  ·  %s\nНаселение: %s\nСнабжение: %d свободно / %d нужно\nФермы: %d/%d     Пункт: %s\nДивизии: %d" % [NAMES[int(p["owner"])], place, TERRAIN_NAMES[int(p["terrain"])], RESOURCE_NAMES[int(p["resource"])], _short_number(int(p["population"])), int(p["supply"]) - _province_demand(selected_province), _province_demand(selected_province), int(p["farms"]), int(p["slots"]), "есть" if bool(p["depot"]) else "нет", units]
        if units > 0:
            var visible_units: int = 0
            for unit in divisions:
                if int(unit["province"]) != selected_province:
                    continue
                province_text.text += "\n%s: орг. %d%% · снаб. %d%%" % [str(unit["name"]), int(unit["org"]), int(unit["supply"])]
                visible_units += 1
                if visible_units >= 2:
                    if units > visible_units:
                        province_text.text += "\nЕщё: %d" % (units - visible_units)
                    break
        var own: bool = int(p["controller"]) == player
        farm_btn.disabled = not own or int(p["farms"]) >= int(p["slots"])
        supply_btn.disabled = not own or bool(p["depot"])
        port_btn.disabled = not own or not bool(p["coast"]) or bool(p["port"])

    _refresh_division_panel()
    _fit_info_cards()
    if government_panel != null and government_panel.visible:
        _update_government_live()
    if battle_panel != null and battle_panel.visible:
        _refresh_battle_panel()
    queue_redraw()
    _profile_finish("Интерфейс: общий", _perf_start_us)

func _fit_info_cards() -> void:
    # Adapt card heights to the actual text; never hide action buttons below screen.
    if province_panel != null and province_panel.visible:
        var rows: int = province_text.text.count("\n") + 1
        var height_needed: float = 80.0 + float(rows) * 26.0
        province_panel.offset_top = -minf(maxf(120.0,size.y-10.0),height_needed)
        province_panel.offset_bottom = 0.0
    if division_panel != null and division_panel.visible:
        division_panel.offset_top = -minf(maxf(100.0,size.y-90.0),460.0)
        division_panel.offset_bottom = 0.0

func _choose_country() -> void:
    if selected_country <= 0:
        return
    player = selected_country
    selected_country = 0
    selected_province = -1
    _center_on_capital(player)
    feedback.text = "Страна выбрана"
    _save_game()
    _refresh()

func _center_on_capital(nation: int) -> void:
    for pid in provinces.keys():
        if int(provinces[pid]["owner"]) == nation and str(provinces[pid]["place"]) == "Столица":
            var center: Vector2 = provinces[pid]["pos"]
            offset = size * 0.5 - center * zoom
            _limit_camera()
            queue_redraw()
            return

func _init_templates() -> void:
    var initial: Array[String] = []
    for i in range(20):
        initial.append("infantry" if i in [0,5,10] else ("artillery" if i == 1 else ""))
    var guns: Array[String] = []
    for i in range(20):
        guns.append("infantry" if i in [0,5] else ("artillery" if i in [1,6] else ""))
    division_templates = [{"name": "Пехотная дивизия", "cells": initial.duplicate(),"hidden":false}, {"name": "Артиллерийская дивизия", "cells": guns.duplicate(),"hidden":false}]
    # The editor has 5 columns and 4 rows: exactly 20 company slots.
    for t in division_templates:
        var cells: Array = t["cells"]
        while cells.size() < 20:
            cells.append("")
        while cells.size() > 20:
            cells.pop_back()

func _show_training() -> void:
    training_panel.visible = true
    editor_panel.visible = false
    pending_train = -1
    refit_division_id = -1
    _refresh_training()

func _close_army_windows() -> void:
    training_panel.visible = false
    editor_panel.visible = false
    pending_train = -1

func _refresh_training() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    if training_list == null or template_list == null:
        _profile_finish("Интерфейс: подготовка", _perf_start_us)
        return
    for child in template_list.get_children():
        template_list.remove_child(child)
        child.queue_free()
    for child in training_list.get_children():
        training_list.remove_child(child)
        child.queue_free()
    # Left panel: compact recruitment queue and batch controls. The template panel on the right is unchanged.
    var queue_title: Label = _government_label("НАБРАТЬ И РАЗМЕСТИТЬ", 21)
    queue_title.autowrap_mode = TextServer.AUTOWRAP_OFF
    training_list.add_child(queue_title)
    if refit_division_id >= 0:
        training_list.add_child(_ui_button("Отмена переоснащения", func() -> void: refit_division_id = -1; _refresh_training()))
    elif pending_train >= 0:
        var chosen: Dictionary = division_templates[pending_train]
        var setup: PanelContainer = _plain_panel(Color("#253c4d"))
        training_list.add_child(setup)
        var setup_column: VBoxContainer = VBoxContainer.new()
        setup_column.add_theme_constant_override("separation", 7)
        setup.add_child(setup_column)
        var chosen_name: Label = _government_label(str(chosen["name"]), 20)
        chosen_name.autowrap_mode = TextServer.AUTOWRAP_OFF
        setup_column.add_child(chosen_name)
        var qty_row: HBoxContainer = HBoxContainer.new()
        qty_row.add_theme_constant_override("separation", 7)
        setup_column.add_child(qty_row)
        var qty_title: Label = _government_label("Количество", 18)
        qty_title.custom_minimum_size.x = 180.0
        qty_title.autowrap_mode = TextServer.AUTOWRAP_OFF
        qty_row.add_child(qty_title)
        qty_row.add_child(_ui_button("−", func() -> void: _change_training_count(-1), 44))
        var qty_value: Label = _government_label(str(training_batch_count), 20)
        qty_value.custom_minimum_size.x = 46.0
        qty_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        qty_row.add_child(qty_value)
        qty_row.add_child(_ui_button("+", func() -> void: _change_training_count(1), 44))
        var repeat_row: HBoxContainer = HBoxContainer.new()
        repeat_row.add_theme_constant_override("separation", 7)
        setup_column.add_child(repeat_row)
        var repeat_title: Label = _government_label("Повторов", 18)
        repeat_title.custom_minimum_size.x = 180.0
        repeat_title.autowrap_mode = TextServer.AUTOWRAP_OFF
        repeat_row.add_child(repeat_title)
        repeat_row.add_child(_ui_button("−", func() -> void: _change_training_repeats(-1), 44))
        var repeat_value: Label = _government_label("∞" if training_repeat_unlimited else str(training_repeat_count), 20)
        repeat_value.custom_minimum_size.x = 46.0
        repeat_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        repeat_row.add_child(repeat_value)
        repeat_row.add_child(_ui_button("+", func() -> void: _change_training_repeats(1), 44))
        setup_column.add_child(_ui_button("∞  Повторять постоянно" if training_repeat_unlimited else "Повторять постоянно: выкл.", _toggle_training_infinite))
        setup_column.add_child(_ui_button("Выбрать провинцию развёртывания", func() -> void: training_panel.visible = false))
        setup_column.add_child(_ui_button("Отмена", func() -> void: pending_train = -1; _refresh_training()))
    if training_queue.is_empty():
        training_list.add_child(_government_label("Очередь пуста", 17))
    for record in training_queue:
        var record_id: int = int(record["id"])
        var count: int = int(record.get("count", 1))
        var repeats: int = int(record.get("repeat_left", 1))
        var panel: PanelContainer = _plain_panel(Color("#304756"))
        training_list.add_child(panel)
        var column: VBoxContainer = VBoxContainer.new()
        panel.add_child(column)
        var header: HBoxContainer = HBoxContainer.new()
        column.add_child(header)
        var nm: Label = _government_label("%s ×%d" % [str(record["name"]),count], 19)
        nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(nm)
        header.add_child(_ui_button("×", func() -> void: _cancel_training_record(record_id), 40))
        column.add_child(_government_label("Повтор: %s · Провинция %d" % ["∞" if repeats < 0 else str(repeats),int(record["province"])],16))
        var progress: ProgressBar = ProgressBar.new()
        progress.max_value = 30.0
        progress.value = float(record["days"])
        progress.show_percentage = true
        progress.custom_minimum_size.y = 18.0
        column.add_child(progress)
        column.add_child(_government_label("Ожидание пополнения" if bool(record.get("waiting",false)) else "Обучение: %d / 30 дней" % int(record["days"]),16))
    template_list.add_child(_government_label("ШАБЛОНЫ", 22))
    template_list.add_child(_ui_button("Показать скрытые" if not show_hidden_templates else "Скрыть устаревшие", _toggle_hidden_list))
    for i in range(division_templates.size()):
        var idx: int = i
        var template_data: Dictionary = division_templates[i]
        var is_hidden: bool = bool(template_data.get("hidden",false))
        if is_hidden and not show_hidden_templates and refit_division_id < 0:
            continue
        var card: PanelContainer = _plain_panel(Color("#3c454b") if is_hidden else Color("#344b5a"))
        template_list.add_child(card)
        var line: VBoxContainer = VBoxContainer.new()
        card.add_child(line)
        line.add_child(_government_label(str(template_data["name"]) + ("  [СКРЫТ]" if is_hidden else ""), 21))
        line.add_child(_government_label("Рот: %d · Людей: %d" % [_count_companies(template_data["cells"]),_template_stat(template_data["cells"],"men")], 17))
        var buttons: HBoxContainer = HBoxContainer.new()
        line.add_child(buttons)
        if refit_division_id >= 0:
            buttons.add_child(_ui_button("Выбрать", func() -> void: _begin_refit(idx)))
        else:
            buttons.add_child(_ui_button("Изменить", func() -> void: _open_editor(idx)))
            if not is_hidden:
                buttons.add_child(_ui_button("Обучить", func() -> void: _select_training_template(idx)))
            buttons.add_child(_ui_button("Вернуть" if is_hidden else "Скрыть", func() -> void: _toggle_template_hidden(idx)))
    _profile_finish("Интерфейс: подготовка", _perf_start_us)

func _count_companies(cells: Array) -> int:
    var count: int = 0
    for entry in cells:
        if BATTALIONS.has(str(entry)):
            count += 1
    return count

func _select_training_template(index: int) -> void:
    pending_train = index
    feedback.text = "Выберите свою провинцию для развёртывания"
    _refresh_training()

func _change_training_count(change: int) -> void:
    training_batch_count = clampi(training_batch_count + change, 1, 50)
    _refresh_training()

func _change_training_repeats(change: int) -> void:
    training_repeat_unlimited = false
    training_repeat_count = clampi(training_repeat_count + change, 1, 99)
    _refresh_training()

func _toggle_training_infinite() -> void:
    training_repeat_unlimited = not training_repeat_unlimited
    _refresh_training()

func _cancel_training_record(record_id: int) -> void:
    for index in range(training_queue.size()):
        if int(training_queue[index]["id"]) == record_id:
            training_queue.remove_at(index)
            break
    _refresh_training()

func _reserve_training_batch(record: Dictionary) -> bool:
    var pid: int = int(record["province"])
    var owner_id: int = int(record["owner"])
    if not provinces.has(pid) or int(provinces[pid]["controller"]) != owner_id:
        return false
    var needed: int = _template_stat(record["cells"],"men") * int(record.get("count",1))
    var pools: Array[int] = _recruitment_pools(pid,owner_id)
    var available: int = 0
    for pool_id in pools:
        available += _recruitable_people(pool_id,owner_id)
    if available < needed:
        return false
    return _draw_recruits_proportionally(pools,needed,owner_id) == needed

func _toggle_hidden_list() -> void:
    show_hidden_templates = not show_hidden_templates
    _refresh_training()

func _toggle_template_hidden(index: int) -> void:
    division_templates[index]["hidden"] = not bool(division_templates[index].get("hidden",false))
    if bool(division_templates[index]["hidden"]) and pending_train == index:
        pending_train = -1
    _save_game()
    _refresh_training()

func _begin_refit(index: int) -> void:
    for d in divisions:
        if int(d["id"]) == refit_division_id and int(d["owner"]) == player:
            d["refit_target"] = index
            d["refit_progress"] = 0.0
            _log_event("Дивизия %d начала переоснащение: %s" % [int(d["id"]),str(division_templates[index]["name"])])
            break
    refit_division_id = -1
    training_panel.visible = false
    _refresh()

func _start_refit() -> void:
    if inspected_division_id < 0:
        return
    refit_division_id = inspected_division_id
    training_panel.visible = true
    editor_panel.visible = false
    _refresh_training()

func _finish_training(record_id: int, early: bool = false) -> void:
    for index in range(training_queue.size()):
        var item: Dictionary = training_queue[index]
        if int(item["id"]) != record_id:
            continue
        var template_index: int = int(item["template"])
        var pid: int = int(item["province"])
        var count: int = int(item.get("count",1))
        for i in range(count):
            _make_division(int(item["owner"]),pid,0,0)
            var unit: Dictionary = divisions[divisions.size()-1]
            unit["companies"] = (item["cells"] as Array).duplicate()
            unit["max_men"] = _template_stat(unit["companies"],"men")
            unit["men"] = int(unit["max_men"])
            unit["template_id"] = template_index
            unit["level"] = 1 if early else 2
            unit["org"] = 100
        _log_event("Подготовлено дивизий: %d (%s)" % [count,"досрочно" if early else "полностью"])
        var repeats: int = int(item.get("repeat_left",1))
        if repeats == 1:
            training_queue.remove_at(index)
        else:
            if repeats > 1:
                item["repeat_left"] = repeats - 1
            item["days"] = 0
            item["waiting"] = not _reserve_training_batch(item)
        if training_panel.visible:
            _refresh_training()
        _refresh()
        return

func _advance_training() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    var finished: Array[int] = []
    for item in training_queue:
        if bool(item.get("waiting",false)):
            if _reserve_training_batch(item):
                item["waiting"] = false
            else:
                continue
        item["days"] = int(item["days"]) + 1
        if int(item["days"]) >= 30:
            finished.append(int(item["id"]))
    for record_id in finished:
        _finish_training(record_id)
    if training_panel.visible and not training_queue.is_empty() and day % 3 == 0:
        _refresh_training()
    _profile_finish("Сутки: подготовка", _perf_start_us)

func _template_stat(cells: Array, which: String) -> int:
    var result: float = 0.0
    var weighted: float = 0.0
    var soldiers: float = 0.0
    var slowest: int = 100
    var armor_weight: float = 0.0
    var max_piercing: int = 0
    for entry in cells:
        var typ: String = str(entry)
        if not BATTALIONS.has(typ):
            continue
        var unit: Dictionary = BATTALIONS[typ]
        var count: int = int(unit["men"])
        soldiers += float(count)
        if which == "org":
            weighted += float(unit["org"]) * float(count)
        elif which == "speed":
            if _battalion_group(typ) != "support":
                slowest = mini(slowest,int(unit["speed"]))
        elif which == "armor":
            armor_weight += float(unit["armor"]) * float(count)
        elif which == "piercing":
            max_piercing = maxi(max_piercing,int(unit["piercing"]))
        elif which == "hardness":
            result += float(count) if typ == "tanks" else 0.0
        elif which == "hp":
            result += maxf(1.0,float(count)/100.0)
        elif which == "hard_attack":
            result += float(unit.get("hard_attack",float(unit.get("piercing",0))*0.45))
        elif which == "toughness":
            result += float(count) * (1.0 + float(unit["defense"]) / 100.0)
        else:
            result += float(unit.get(which,0))
    match which:
        "org": return int(round(weighted / maxf(1.0,soldiers)))
        "speed": return 4 if slowest == 100 else slowest
        "armor": return int(round(armor_weight / maxf(1.0,soldiers)))
        "piercing": return max_piercing
        "hardness": return int(round(100.0 * result / maxf(1.0,soldiers)))
        "supply": return maxi(1,int(ceil(result * (1.0-0.02*float(cells.count("supply_company"))))))
        _: return int(round(result))

func _division_cells(d: Dictionary) -> Array:
    if d.has("companies") and d["companies"] is Array:
        return d["companies"]
    var legacy: Array = []
    for i in range(int(d.get("infantry",0))):
        legacy.append("infantry")
    for i in range(int(d.get("artillery",0))):
        legacy.append("artillery")
    return legacy

func _division_stat(d: Dictionary, which: String) -> int:
    return _template_stat(_division_cells(d),which)

func _province_victory_points(pid: int) -> int:
    var settlement_name: String = str(provinces[pid].get("place",""))
    match settlement_name:
        "Столица": return 20
        "Город": return 5
        "Село": return 2
        _: return 1

func _check_capitulations() -> void:
    for nation in range(1,6):
        if bool(capitulated.get(str(nation),false)):
            continue
        var total: int = 0
        var remaining: int = 0
        var dominant: Dictionary = {}
        for pid in provinces.keys():
            var pp: Dictionary = provinces[pid]
            if int(pp["owner"]) != nation:
                continue
            var points: int = _province_victory_points(int(pid))
            total += points
            if int(pp["controller"]) == nation:
                remaining += points
            else:
                var attacker_id: int = int(pp["controller"])
                dominant[attacker_id] = int(dominant.get(attacker_id,0)) + points
        if total == 0 or remaining * 5 > total:
            continue
        var victor: int = 0
        var best: int = -1
        for contender in dominant.keys():
            if int(dominant[contender]) > best:
                victor = int(contender)
                best = int(dominant[contender])
        if victor == 0:
            continue
        capitulated[str(nation)] = true
        for pid in provinces.keys():
            if int(provinces[pid]["owner"]) == nation and int(provinces[pid]["controller"]) == nation:
                provinces[pid]["controller"] = victor
        for d in divisions:
            if int(d["owner"]) == nation:
                d["men"] = 0
                d["org"] = 0
        for key in wars.keys():
            var nations: PackedStringArray = str(key).split("_")
            if nations.size() == 2 and (int(nations[0]) == nation or int(nations[1]) == nation):
                wars[key] = false
        occupation_dirty = true
        feedback.text = "%s капитулировал! (осталось %d%% очков)" % [NAMES[nation],int(round(100.0*float(remaining)/float(total)))]
    if occupation_dirty:
        _rebuild_occupation_texture()
        _recalculate_supply()
        occupation_dirty = false

func _open_editor(index: int) -> void:
    editing_index = index
    editing_cells.clear()
    for cell in division_templates[index]["cells"]:
        editing_cells.append(str(cell))
    editor_panel.visible = true
    company_picker_render_key = ""
    editor_name_input.text = str(division_templates[index]["name"])
    editor_icon_kind = str(division_templates[index].get("icon", "infantry"))
    selected_company_slot = -1
    editor_category = ""
    training_panel.visible = false
    _refresh_editor()

func _cycle_division_icon() -> void:
    var choices: Array[String] = ["infantry", "cavalry", "motorized", "tanks", "artillery", "anti_tank", "anti_air", "engineers", "recon", "medics", "repair", "signals", "supply_company", "sappers"]
    var next: int = (choices.find(editor_icon_kind) + 1) % choices.size()
    editor_icon_kind = choices[next]
    _refresh_editor_icon()

func _refresh_editor_icon() -> void:
    if editor_icon_button != null:
        editor_icon_button.icon = _editor_icon_for_type(editor_icon_kind)

func _close_editor() -> void:
    editor_panel.visible = false
    training_panel.visible = true
    _refresh_training()

func _battalion_group(typ: String) -> String:
    match typ:
        "artillery", "anti_tank", "anti_air", "towed_artillery", "towed_anti_tank", "towed_anti_air": return "artillery"
        "infantry": return "infantry"
        "cavalry": return "infantry"
        "motorized": return "motorized"
        "tanks": return "armor"
        "engineers", "recon", "medics", "repair", "supply_company", "signals", "sappers": return "support"
        _: return ""

func _column_group(col: int, except_slot: int = -1) -> String:
    for row in range(4):
        var at: int = row * 5 + col
        if at == except_slot:
            continue
        var typ: String = editing_cells[at]
        if typ != "":
            return _battalion_group(typ)
    return ""

func _slot_is_available(index: int) -> bool:
    if editing_cells[index] != "":
        return true
    var row: int = int(float(index) / 5.0)
    if row == 0:
        return true
    return editing_cells[(row-1)*5 + index%5] != ""

func _editor_categories() -> Array[String]:
    return ["Пехота", "Передвижные", "Артиллерия", "Спецотряды"]

func _editor_category_types(category: String) -> Array[String]:
    match category:
        "Пехота": return ["infantry", "cavalry"]
        "Передвижные": return ["motorized", "tanks"]
        "Артиллерия": return ["artillery", "anti_tank", "anti_air", "towed_artillery", "towed_anti_tank", "towed_anti_air"]
        "Спецотряды": return ["engineers", "recon", "medics", "repair", "signals", "sappers", "supply_company"]
    return []

func _editor_icon_for_type(typ: String) -> Texture2D:
    var icon_name: String = "person"
    match typ:
        "infantry": icon_name = "person"
        "cavalry": icon_name = "horse"
        "motorized": icon_name = "truck"
        "tanks": icon_name = "tank"
        "artillery": icon_name = "gun"
        "towed_artillery": icon_name = "towed_gun"
        "anti_tank": icon_name = "anti_tank"
        "towed_anti_tank": icon_name = "towed_anti_tank"
        "anti_air": icon_name = "anti_air"
        "towed_anti_air": icon_name = "towed_anti_air"
        "engineers": icon_name = "engineer"
        "recon": icon_name = "recon"
        "medics": icon_name = "medic"
        "repair": icon_name = "repair"
        "supply_company": icon_name = "supply"
        "signals": icon_name = "signal"
        "sappers": icon_name = "sapper"
    return load("res://assets/ui/%s.png" % icon_name) as Texture2D

func _editor_icon_for_category(category: String) -> Texture2D:
    match category:
        "Пехота": return _editor_icon_for_type("infantry")
        "Передвижные": return _editor_icon_for_type("motorized")
        "Артиллерия": return _editor_icon_for_type("artillery")
        "Спецотряды": return _editor_icon_for_type("engineers")
    return null

var company_picker_render_key: String = ""

func _refresh_company_picker() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    var group_key: String = ""
    var selected_kind: String = ""
    if selected_company_slot >= 0 and selected_company_slot < editing_cells.size():
        group_key = _column_group(selected_company_slot % 5, selected_company_slot)
        selected_kind = str(editing_cells[selected_company_slot])
    var next_key: String = "%d/%s/%s/%s" % [selected_company_slot, editor_category, group_key, selected_kind]
    if company_picker_render_key == next_key:
        _profile_finish("Интерфейс: выбор рот", _perf_start_us)
        return
    company_picker_render_key = next_key
    for child in company_picker.get_children():
        company_picker.remove_child(child)
        child.queue_free()
    var root: VBoxContainer = VBoxContainer.new()
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    company_picker.add_child(root)
    root.add_child(_government_label("ВЫБОР РОТЫ", 17))
    var col_group: String = ""
    if selected_company_slot >= 0:
        col_group = _column_group(selected_company_slot % 5,selected_company_slot)
    var category_grid: GridContainer = GridContainer.new()
    category_grid.columns = 2
    root.add_child(category_grid)
    for category in _editor_categories():
        var category_name: String = category
        var available: bool = false
        for kind in _editor_category_types(category_name):
            if col_group == "" or _battalion_group(kind) == col_group:
                available = true
                break
        if not available:
            continue
        var choose_category: Button = _ui_button(category_name,func() -> void:
            editor_category = category_name
            _refresh_company_picker()
        )
        choose_category.icon = _editor_icon_for_category(category_name)
        choose_category.expand_icon = false
        choose_category.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
        choose_category.custom_minimum_size.y = 44
        choose_category.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        choose_category.add_theme_font_size_override("font_size", 15)
        if editor_category == category_name:
            _editor_card_style(choose_category, Color("#285b6b"), Color("#4ad1e9"))
        category_grid.add_child(choose_category)
    if selected_company_slot < 0:
        _profile_finish("Интерфейс: выбор рот", _perf_start_us)
        return
    if editor_category == "":
        _profile_finish("Интерфейс: выбор рот", _perf_start_us)
        return
    root.add_child(_government_label(editor_category.to_upper(), 17))
    var list_scroll: ScrollContainer = ScrollContainer.new()
    list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(list_scroll)
    var cards: GridContainer = GridContainer.new()
    cards.columns = 2
    cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list_scroll.add_child(cards)
    for kind in _editor_category_types(editor_category):
        var typ: String = kind
        if col_group != "" and _battalion_group(typ) != col_group:
            continue
        var unit: Dictionary = BATTALIONS[typ]
        var card: Button = _ui_button(str(unit["label"]),func() -> void: _set_company(typ))
        card.icon = _editor_icon_for_type(typ)
        card.expand_icon = false
        card.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
        card.custom_minimum_size.y = 58
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.add_theme_font_size_override("font_size", 15)
        _editor_card_style(card, Color("#324454"), Color("#b99c70"))
        cards.add_child(card)
    if editing_cells[selected_company_slot] != "":
        root.add_child(_ui_button("− Удалить выбранную роту",func() -> void: _set_company("")))
    _profile_finish("Интерфейс: выбор рот", _perf_start_us)

func _editor_card_style(button: Button, bg_color: Color, line_color: Color) -> void:
    var state_style: StyleBoxFlat = StyleBoxFlat.new()
    state_style.bg_color = bg_color
    state_style.border_color = line_color
    state_style.set_border_width_all(1)
    state_style.set_corner_radius_all(4)
    state_style.content_margin_left = 4
    state_style.content_margin_right = 4
    state_style.content_margin_top = 4
    state_style.content_margin_bottom = 4
    button.add_theme_stylebox_override("normal", state_style)
    var hover_style: StyleBoxFlat = state_style.duplicate() as StyleBoxFlat
    hover_style.bg_color = bg_color.lightened(0.14)
    button.add_theme_stylebox_override("hover", hover_style)

func _editor_section(parent: HBoxContainer, heading: String) -> VBoxContainer:
    var frame: PanelContainer = _plain_panel(Color("#1c3342fa"))
    frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(frame)
    var col: VBoxContainer = VBoxContainer.new()
    col.add_theme_constant_override("separation", 3)
    frame.add_child(col)
    var caption: Label = Label.new()
    caption.text = heading
    caption.add_theme_color_override("font_color", Color("#f3d9a0"))
    caption.add_theme_font_size_override("font_size", 16)
    col.add_child(caption)
    var rows: VBoxContainer = VBoxContainer.new()
    rows.add_theme_constant_override("separation", 1)
    col.add_child(rows)
    return rows

# Stable statistic rows: update text and color, never delete the controls.
# Keys are scoped to the parent instance so independently rendered sections
# cannot collide when they have similarly named entries.
var editor_stat_cache: Dictionary = {}

func _editor_stat_row(parent: VBoxContainer, symbol: String, heading: String, value_text: String, change: int = 0, show_change: bool = false) -> void:
    var row_key: String = "%d/%s" % [parent.get_instance_id(), heading]
    if editor_stat_cache.has(row_key):
        var references: Array = editor_stat_cache[row_key]
        var value_label: Label = references[0] as Label
        var delta_label: Label = references[1] as Label
        if is_instance_valid(value_label) and is_instance_valid(delta_label):
            if value_label.text != value_text:
                value_label.text = value_text
            var difference_text: String = ""
            if show_change and change != 0:
                difference_text = "+%d" % change if change > 0 else "−%d" % abs(change)
            if delta_label.text != difference_text:
                delta_label.text = difference_text
            delta_label.visible = difference_text != ""
            if difference_text != "":
                delta_label.add_theme_color_override("font_color", Color("#65df83") if change > 0 else Color("#f16f6f"))
            return
    var back: PanelContainer = PanelContainer.new()
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("#243c4c") if parent.get_child_count() % 2 == 0 else Color("#1a3040")
    style.content_margin_left = 3
    style.content_margin_right = 4
    style.content_margin_top = 0
    style.content_margin_bottom = 0
    back.add_theme_stylebox_override("panel", style)
    parent.add_child(back)
    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 1)
    back.add_child(row)
    var icon_label: Label = Label.new()
    icon_label.text = symbol
    icon_label.custom_minimum_size.x = 17.0
    icon_label.add_theme_color_override("font_color", Color("#f2d7a0"))
    icon_label.add_theme_font_size_override("font_size", 15)
    row.add_child(icon_label)
    var label_name: Label = Label.new()
    label_name.text = heading
    label_name.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
    label_name.add_theme_font_size_override("font_size", 15)
    row.add_child(label_name)
    var value_label: Label = Label.new()
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_label.add_theme_font_size_override("font_size", 15)
    value_label.add_theme_color_override("font_color", Color("#ffffff"))
    row.add_child(value_label)
    var delta_label: Label = Label.new()
    delta_label.add_theme_font_size_override("font_size", 15)
    row.add_child(delta_label)
    editor_stat_cache[row_key] = [value_label, delta_label]
    _editor_stat_row(parent, symbol, heading, value_text, change, show_change)

# Stable appearance keys: do not allocate 40 StyleBoxFlat objects after every edit.
var editor_slot_style_keys: Dictionary = {}

func _refresh_editor() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    editor_name.text = "КОНСТРУКТОР ДИВИЗИЙ"
    _refresh_editor_icon()
    var original: Array = division_templates[editing_index]["cells"]
    # Display the CURRENT value, with its change immediately adjacent.
    var combat_stats: Array = [
        ["◈","Организация","org"], ["✚","Прочность","hp"],
        ["⚔","Атака","attack"], ["✦","Бронебойная атака","hard_attack"],
        ["➤","Пробитие","piercing"], ["⬟","Защита","defense"],
        ["▰","Броня","armor"], ["»","Скорость","speed"]
    ]
    for row_data in combat_stats:
        var stat_id: String = str(row_data[2])
        var current_value: int = _template_stat(editing_cells,stat_id)
        var original_value: int = _template_stat(original,stat_id)
        var suffix: String = " км/ч" if stat_id == "speed" else ""
        _editor_stat_row(editor_combat_rows,str(row_data[0]),str(row_data[1]),str(current_value)+suffix,current_value-original_value,true)
    var people: int = _template_stat(editing_cells,"men")
    _editor_stat_row(editor_needs_rows,"♟","Люди",str(people),people-_template_stat(original,"men"),true)
    _editor_stat_row(editor_needs_rows,"▣","Снаряжение",str(people),people-_template_stat(original,"men"),true)
    var current_supply: int = _template_stat(editing_cells,"supply")
    _editor_stat_row(editor_needs_rows,"▤","Снабжение",str(current_supply)+" / день",current_supply-_template_stat(original,"supply"),true)
    var fuel_count: int = 0
    var original_fuel_count: int = 0
    for unit_kind in editing_cells:
        if BATTALIONS.has(unit_kind) and bool(BATTALIONS[unit_kind].get("fuel",false)):
            fuel_count += 1
    for unit_kind in original:
        if BATTALIONS.has(unit_kind) and bool(BATTALIONS[unit_kind].get("fuel",false)):
            original_fuel_count += 1
    _editor_stat_row(editor_needs_rows,"▣","Расход топлива",str(fuel_count)+" / день",fuel_count-original_fuel_count,true)
    _editor_stat_row(editor_support_rows,"▥","Укреплённость",str(editing_cells.count("engineers")),editing_cells.count("engineers")-original.count("engineers"),true)
    _editor_stat_row(editor_support_rows,"✚","Сохранение людей","%d%%" % editing_cells.count("medics"),editing_cells.count("medics")-original.count("medics"),true)
    _editor_stat_row(editor_support_rows,"⚙","Сохранение снаряжения","%d%%" % editing_cells.count("repair"),editing_cells.count("repair")-original.count("repair"),true)
    _editor_stat_row(editor_support_rows,"▤","Снижение расхода","%d%%" % (2*editing_cells.count("supply_company")),2*(editing_cells.count("supply_company")-original.count("supply_company")),true)
    _editor_stat_row(editor_support_rows,"⌁","Ускорение подкреплений","%d%%" % editing_cells.count("signals"),editing_cells.count("signals")-original.count("signals"),true)
    _editor_stat_row(editor_support_rows,"⚒","Подавление укреплений","%d%%" % (2*editing_cells.count("sappers")),2*(editing_cells.count("sappers")-original.count("sappers")),true)
    _editor_stat_row(editor_support_rows,"◉","Разведка","0%")
    # Create slot controls only once. Reuse them when editing a battalion:
    # repeated Button/Texture/Style allocations caused visible UI stalls.
    if editor_grid.get_child_count() != 20:
        editor_slot_style_keys.clear()
        for old_slot in editor_grid.get_children():
            editor_grid.remove_child(old_slot)
            old_slot.queue_free()
        for i in range(20):
            var idx: int = i
            var slot: Button = _ui_button("+", func() -> void: _choose_company(idx))
            slot.expand_icon = false
            slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            slot.custom_minimum_size = Vector2(49,52)
            slot.add_theme_font_size_override("font_size",27)
            editor_grid.add_child(slot)
    for i in range(20):
        var b: Button = editor_grid.get_child(i) as Button
        var typ: String = str(editing_cells[i])
        var next_label: String = "+" if typ == "" else ""
        if b.text != next_label:
            b.text = next_label
        var next_icon: Texture2D = null if typ == "" else _editor_icon_for_type(typ)
        if b.icon != next_icon:
            b.icon = next_icon
        var next_disabled: bool = not _slot_is_available(i)
        if b.disabled != next_disabled:
            b.disabled = next_disabled
        var group_id: String = _battalion_group(typ) if typ != "" else ""
        if str(editor_slot_style_keys.get(i, "")) != group_id:
            editor_slot_style_keys[i] = group_id
            var slot_color: Color = Color("#394e5f")
            match group_id:
                "infantry": slot_color = Color("#304b39")
                "motorized", "armor": slot_color = Color("#304e62")
                "artillery": slot_color = Color("#59443c")
                "support": slot_color = Color("#51405c")
            _editor_card_style(b,slot_color,Color("#c2aa79"))
    _refresh_company_picker()
    _profile_finish("Интерфейс: конструктор", _perf_start_us)

func _choose_company(index: int) -> void:
    if not _slot_is_available(index):
        return
    selected_company_slot = index
    editor_category = ""
    _refresh_company_picker()
    _refresh_editor()

func _set_company(company_type: String) -> void:
    if selected_company_slot < 0 or selected_company_slot >= editing_cells.size():
        return
    var col: int = selected_company_slot % 5
    var row: int = int(float(selected_company_slot) / 5.0)
    if company_type != "":
        if not BATTALIONS.has(company_type) or not _slot_is_available(selected_company_slot):
            return
        var group: String = _column_group(col,selected_company_slot)
        if group != "" and _battalion_group(company_type) != group:
            return
        editing_cells[selected_company_slot] = company_type
    else:
        # Removing a company removes all units below it in this column.
        for r in range(row,4):
            editing_cells[r*5+col] = ""
    _refresh_editor()

func _save_template() -> void:
    division_templates[editing_index]["cells"] = editing_cells.duplicate()
    division_templates[editing_index]["icon"] = editor_icon_kind
    var new_name: String = editor_name_input.text.strip_edges()
    if not new_name.is_empty():
        division_templates[editing_index]["name"] = new_name
    _save_game()
    feedback.text = "Шаблон сохранён"
    _close_editor()

func _reset_template() -> void:
    selected_company_slot = -1
    editor_category = ""
    for i in range(editing_cells.size()):
        editing_cells[i] = ""
    _refresh_editor()

func _draw_recruits_proportionally(pools: Array[int], target_count: int, nation: int) -> int:
    if target_count <= 0:
        return 0
    var capacities: Dictionary = {}
    var total: int = 0
    for pool_id in pools:
        var available: int = _recruitable_people(pool_id,nation)
        capacities[pool_id] = available
        total += available
    if total <= 0:
        return 0
    var wanted: int = mini(target_count,total)
    var taken_total: int = 0
    for pool_id in pools:
        var amount: int = mini(int(capacities[pool_id]),int(floor(float(wanted)*float(capacities[pool_id])/float(total))))
        provinces[pool_id]["population"] = int(provinces[pool_id]["population"])-amount
        provinces[pool_id]["recruited"] = int(provinces[pool_id]["recruited"])+amount
        taken_total += amount
    var remaining: int = wanted-taken_total
    for pool_id in pools:
        if remaining <= 0:
            break
        var available: int = _recruitable_people(pool_id,nation)
        var more: int = mini(remaining,available)
        provinces[pool_id]["population"] = int(provinces[pool_id]["population"])-more
        provinces[pool_id]["recruited"] = int(provinces[pool_id]["recruited"])+more
        taken_total += more
        remaining -= more
    return taken_total

func _deploy_pending() -> void:
    if pending_train < 0:
        return
    if player <= 0 or bool(capitulated.get(str(player),false)) or not provinces.has(selected_province) or int(provinces[selected_province]["controller"]) != player:
        feedback.text = "Выберите свою провинцию для развёртывания"
        return
    var cells: Array = division_templates[pending_train]["cells"]
    var valid_count: int = 0
    for cell in cells:
        if BATTALIONS.has(str(cell)):
            valid_count += 1
    if valid_count == 0:
        feedback.text = "Шаблон пуст"
        return
    var required_men: int = _template_stat(cells,"men") * training_batch_count
    var draft_pools: Array[int] = _recruitment_pools(selected_province,player)
    var total_available: int = 0
    for pool_id in draft_pools:
        total_available += _recruitable_people(pool_id,player)
    if total_available < required_men:
        _log_event("Не удалось обучить: доступно %d, нужно %d" % [total_available,required_men])
        feedback.text = "Недостаточно военнообязанных по закону: %d / %d. Увеличьте призыв." % [total_available,required_men]
        return
    var actually_recruited: int = _draw_recruits_proportionally(draft_pools, required_men, player)
    if actually_recruited < required_men:
        feedback.text = "Не удалось собрать военнообязанных: %d/%d" % [actually_recruited,required_men]
        return
    training_queue.append({"id":training_next_id,"template":pending_train,"name":str(division_templates[pending_train]["name"]),"cells":cells.duplicate(),"owner":player,"province":selected_province,"days":0,"count":training_batch_count,"repeat_left":(-1 if training_repeat_unlimited else training_repeat_count),"waiting":false})
    training_next_id += 1
    pending_train = -1
    training_panel.visible = true
    _log_event("Добавлена подготовка дивизии в провинции %d" % selected_province)
    feedback.text = "Дивизия на подготовке: 0/30 дней"
    _refresh_training()
    _refresh()

func _toggle_templates() -> void:
    _show_training()

func _form_army() -> void:
    if player == 0 or not provinces.has(selected_province) or int(provinces[selected_province]["controller"]) != player:
        feedback.text = "Выберите свою провинцию"
        return
    var members: Array[int] = []
    for d in divisions:
        if int(d["owner"]) == player and int(d["province"]) == selected_province and int(d.get("army", 0)) == 0:
            members.append(int(d["id"]))
    if members.is_empty():
        feedback.text = "Здесь нет свободных дивизий"
        return
    for d in divisions:
        if members.has(int(d["id"])):
            d["army"] = army_counter
    armies.append({"id": army_counter, "owner": player, "name": "%d-я армия" % army_counter})
    feedback.text = "Сформирована армия из %d дивизий" % members.size()
    army_counter += 1
    _save_game()
    _refresh()

func _build_farm() -> void:
    if not provinces.has(selected_province):
        return
    var p: Dictionary = provinces[selected_province]
    if int(p["controller"]) != player or int(p["farms"]) >= int(p["slots"]):
        return
    p["farms"] = int(p["farms"]) + 1
    feedback.text = "Построена ферма: +22 еды/день"
    _save_game()
    _refresh()

func _build_depot() -> void:
    if not provinces.has(selected_province):
        return
    var p: Dictionary = provinces[selected_province]
    if int(p["controller"]) != player or bool(p["depot"]):
        return
    p["depot"] = true
    _recalculate_supply()
    _rebuild_supply_texture()
    feedback.text = "Пункт снабжения построен"
    _save_game()
    _refresh()

func _build_port() -> void:
    if not provinces.has(selected_province):
        return
    var p: Dictionary = provinces[selected_province]
    if int(p["controller"]) != player or not bool(p["coast"]) or bool(p["port"]):
        return
    p["port"] = true
    _recalculate_supply()
    _rebuild_supply_texture()
    feedback.text = "Порт построен"
    _save_game()
    _refresh()

func _toggle_division_selection() -> void:
    selection_mode = not selection_mode
    route_order_mode = false
    selection_button.text = "✓ Выделение" if selection_mode else "□ Выделить"
    feedback.text = "Касайтесь дивизий или обведите их рамкой" if selection_mode else "Выделено дивизий: %d" % selected_division_ids.size()
    queue_redraw()

func _clear_division_selection() -> void:
    selected_division_ids.clear()
    route_order_mode = false
    selection_mode = false
    selection_button.text = "□ Выделить"
    feedback.text = "Выделение снято"
    queue_redraw()

func _start_group_route() -> void:
    if selected_division_ids.is_empty() and selected_province >= 0:
        for d in divisions:
            if int(d["province"]) == selected_province and int(d["owner"]) == player:
                selected_division_ids.append(int(d["id"]))
    if selected_division_ids.is_empty():
        feedback.text = "Сначала выделите свои дивизии"
        return
    selection_mode = false
    selection_button.text = "□ Выделить"
    route_order_mode = true
    feedback.text = "Укажите конечную провинцию для %d дивизий" % selected_division_ids.size()
    queue_redraw()

func _start_move() -> void:
    _start_group_route()

func _shortest_route(origin: int, destination: int, nation: int) -> Array[int]:
    if origin == destination:
        return []
    var queue: Array[int] = [origin]
    var parent: Dictionary = {origin: -1}
    var cursor: int = 0
    while cursor < queue.size():
        var current: int = queue[cursor]
        cursor += 1
        if current == destination:
            break
        for raw_n in provinces[current]["neighbors"]:
            var nid: int = int(raw_n)
            if parent.has(nid) or not provinces.has(nid):
                continue
            var controller: int = int(provinces[nid]["controller"])
            if controller != nation and (nid != destination or not _at_war(nation, controller)):
                continue
            parent[nid] = current
            queue.append(nid)
    if not parent.has(destination):
        return []
    var path: Array[int] = []
    var node: int = destination
    while node != origin and node >= 0:
        path.push_front(node)
        node = int(parent[node])
    return path

func _assign_group_route(destination: int) -> void:
    var ordered: int = 0
    for d in divisions:
        if not selected_division_ids.has(int(d["id"])) or int(d["owner"]) != player:
            continue
        var path: Array[int] = _shortest_route(int(d["province"]), destination, player)
        if path.is_empty():
            continue
        d["route"] = path
        d["battle_target"] = -1
        d["travel_from"] = int(d["province"])
        ordered += 1
    feedback.text = "Маршрут назначен: %d дивизий" % ordered if ordered > 0 else "Нет доступного пути к провинции"
    if ordered == 0:
        _log_event("Не удалось проложить маршрут в провинцию %d" % destination)
    route_order_mode = false
    if ordered > 0:
        _save_game()
    queue_redraw()

func _advance_division_routes() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    for d in divisions:
        if int(d.get("battle_target",-1)) >= 0:
            continue
        if _province_in_battle(int(d["province"])):
            continue
        var path: Array = d.get("route", [])
        if path.is_empty():
            d["travel_from"] = int(d["province"])
            continue
        var destination: int = int(path[0])
        if not provinces.has(destination):
            d["route"] = []
            continue
        var from_id: int = int(d["province"])
        var adjacent: bool = false
        for raw_neighbor in provinces[from_id]["neighbors"]:
            if int(raw_neighbor) == destination:
                adjacent = true
                break
        if not adjacent:
            d["route"] = []
            continue
        var controller: int = int(provinces[destination]["controller"])
        if controller == int(d["owner"]):
            # Slowest company determines the number of days needed to enter a province.
            var speed_factor: float = maxf(1.0,float(_division_stat(d,"speed"))) / 4.0
            d["fortification"] = 0.0
            d["travel_progress"] = float(d.get("travel_progress",0.0)) + speed_factor
            if float(d["travel_progress"]) < 1.0:
                continue
            d["travel_progress"] = maxf(0.0,float(d["travel_progress"])-1.0)
            d["travel_from"] = from_id
            d["province"] = destination
            path.pop_front()
            d["route"] = path
        elif _at_war(int(d["owner"]), controller):
            if float(d.get("org_float",d["org"])) < 20.0:
                continue
            d["fortification"] = 0.0
            d["battle_target"] = destination
            battle_progress[destination] = float(battle_progress.get(destination,0.0))
        else:
            d["route"] = []
    _profile_finish("Сутки: перемещения", _perf_start_us)

func _hit_division(screen_pos: Vector2) -> int:
    var best_id: int = -1
    var best_distance: float = 22.0
    for d in divisions:
        if int(d["owner"]) != player or not provinces.has(int(d["province"])):
            continue
        var visual_pos: Vector2 = _division_position(d, [])
        var x: float = offset.x + visual_pos.x * zoom
        var y: float = offset.y + visual_pos.y * zoom
        var period: float = MAP_W * zoom
        x += round((screen_pos.x - x)/period) * period
        var dist: float = screen_pos.distance_to(Vector2(x,y))
        if dist < best_distance:
            best_distance = dist
            best_id = int(d["id"])
    return best_id

func _pick_division(screen_pos: Vector2) -> bool:
    var hit_id: int = _hit_division(screen_pos)
    if hit_id < 0:
        return false
    if selected_division_ids.has(hit_id):
        selected_division_ids.erase(hit_id)
    else:
        selected_division_ids.append(hit_id)
    feedback.text = "Выделено дивизий: %d" % selected_division_ids.size()
    if selected_division_ids.size() == 1:
        inspected_division_id = selected_division_ids[0]
    _refresh()
    return true

func _select_divisions_in_rectangle(rect: Rect2) -> void:
    if rect.size.length() < 10.0:
        _pick_division(selection_end)
        return
    for d in divisions:
        if int(d["owner"]) != player or not provinces.has(int(d["province"])):
            continue
        var position_map: Vector2 = _division_position(d, [])
        var current_pos: Vector2 = offset + position_map * zoom
        var period: float = MAP_W * zoom
        for k in range(-2,3):
            if rect.has_point(current_pos + Vector2(float(k)*period,0)):
                if not selected_division_ids.has(int(d["id"])):
                    selected_division_ids.append(int(d["id"]))
                break
    feedback.text = "Выделено дивизий: %d" % selected_division_ids.size()
    if selected_division_ids.size() == 1:
        inspected_division_id = selected_division_ids[0]
    _refresh()

func _province_demand(pid: int) -> int:
    var demand: int = 0
    for d in divisions:
        if int(d["province"]) == pid:
            demand += _division_stat(d,"supply")
    return demand

func _recalculate_supply() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    for id in provinces.keys():
        var p: Dictionary = provinces[id]
        p["supply"] = maxi(int(float(p["source"]) * 0.75), maxi(83 if bool(p["depot"]) else 0, 90 if bool(p["port"]) else 0))
    for step in range(40):
        var changed: bool = false
        for id in provinces.keys():
            var p: Dictionary = provinces[id]
            var best: int = int(p["supply"])
            for neighbor in p["neighbors"]:
                var nid: int = int(neighbor)
                if provinces.has(nid) and int(provinces[nid]["controller"]) == int(p["controller"]):
                    best = maxi(best, int(provinces[nid]["supply"]) - 14)
            if best > int(p["supply"]):
                p["supply"] = best
                changed = true
        if not changed:
            break
    _profile_finish("Снабжение: пересчёт карты", _perf_start_us)

func _food_income(nation: int) -> int:
    var sum_food: int = 20
    for id in provinces.keys():
        if int(provinces[id]["owner"]) == nation:
            sum_food += int(provinces[id]["farms"]) * 22
    return sum_food

func _set_speed(value: int) -> void:
    speed = value
    developer_speed = false
    for i in range(speed_buttons.size()):
        speed_buttons[i].modulate = Color("#f4cf7c") if i == speed else Color.WHITE

func _process(delta: float) -> void:
    var _process_perf_us: int = Time.get_ticks_usec()
    var frame_ms: float = delta * 1000.0
    max_frame_ms = maxf(max_frame_ms,frame_ms)
    if frame_ms > 50.0:
        slow_frames += 1
        last_slow_frame_ms = frame_ms
    if drag_mouse and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        drag_mouse = false
        unit_drag_id = -1
        unit_drag_active = false
        selecting_rectangle = false
    battle_fx_time += delta
    battle_redraw_clock += delta
    if battle_redraw_clock >= 0.15 and speed > 0 and not battle_reports.is_empty():
        battle_redraw_clock = 0.0
        queue_redraw()
    if speed <= 0 or player <= 0:
        _profile_finish("Кадр: скрипт управления", _process_perf_us)
        return
    clock_accum += delta
    var interval: float = _day_interval()
    if not selected_division_ids.is_empty():
        queue_redraw()
    if clock_accum >= interval:
        var ticks: int = 1
        if developer_mode and developer_speed:
            ticks = mini(8, maxi(1,int(clock_accum / interval)))
        clock_accum = maxf(0.0,clock_accum - interval*float(ticks))
        for tick in range(ticks):
            _next_day()
    _profile_finish("Кадр: скрипт управления", _process_perf_us)

func _update_division_supply() -> void:
    var demands: Dictionary = {}
    for d in divisions:
        var pid: int = int(d["province"])
        demands[pid] = int(demands.get(pid,0)) + _division_stat(d,"supply")
    for d in divisions:
        var pid: int = int(d["province"])
        var required: int = maxi(1,int(demands.get(pid,0)))
        d["supply"] = clampi(int(round(100.0 * float(provinces[pid]["supply"]) / float(required))),0,100)

func _next_day() -> void:
    if player <= 0:
        return
    var _day_perf_us: int = Time.get_ticks_usec()
    # Supplies are territorial capacity, not stockpiled resources.
    var province_needs: Dictionary = {}
    for d in divisions:
        var pid: int = int(d["province"])
        province_needs[pid] = int(province_needs.get(pid, 0)) + _division_stat(d,"supply")
    for d in divisions:
        var pid: int = int(d["province"])
        var need: int = maxi(1,int(province_needs.get(pid,0)))
        var capacity: int = int(provinces[pid]["supply"])
        var ratio: float = minf(1.0,float(capacity) / float(need))
        d["supply"] = int(round(ratio * 100.0))
        var reserve: float = float(d.get("supply_reserve",3.0))
        if ratio < 0.999:
            reserve = maxf(0.0,reserve - (1.0-ratio))
        else:
            reserve = minf(3.0,reserve+0.5)
        d["supply_reserve"] = reserve
        if ratio < 0.65 and reserve <= 0.0:
            var shortage: float = (0.65 - ratio) / 0.65
            d["men"] = maxi(0,int(d["men"]) - maxi(1,int(ceil(float(d["men"]) * 0.0015 * shortage))))
            d["equip_float"] = maxf(0.0,float(d.get("equip_float",d["equipment"])) - 0.8*shortage)
            d["equipment"] = int(round(float(d["equip_float"])))
            # Shortage causes attrition but not direct organization damage.
        else:
            var fighting: bool = int(d.get("battle_target",-1)) >= 0 or _province_in_battle(pid)
            if not fighting:
                d["org"] = mini(100,int(d["org"]) + maxi(1,int(round(5.0 * ratio))))
                d["org_float"] = float(d["org"])
                if d.get("route",[]).is_empty():
                    var engineering: int = _division_cells(d).count("engineers")
                    d["fortification"] = minf(5.0+float(engineering)*5.0,float(d.get("fortification",0.0))+0.5)
            var cap: int = int(d.get("max_men",_division_stat(d,"men")))
            var missing: int = maxi(0,cap-int(d["men"]))
            if missing > 0:
                var signal_bonus: float = 1.0+0.01*float(_division_cells(d).count("signals")) if fighting else 1.0
                var draft: int = mini(missing,maxi(1,int(round(float(cap) * (0.02 if fighting else 0.06) * ratio * signal_bonus))))
                # Draw from the current province first, then directly neighboring friendly provinces.
                var pools: Array[int] = [pid]
                for raw_neighbor in provinces[pid]["neighbors"]:
                    var adjacent_pid: int = int(raw_neighbor)
                    if provinces.has(adjacent_pid) and int(provinces[adjacent_pid]["controller"]) == int(d["owner"]):
                        pools.append(adjacent_pid)
                var recruited: int = _draw_recruits_proportionally(pools,draft,int(d["owner"]))
                d["men"] = mini(cap,int(d["men"]) + recruited)
                if recruited > 0:
                    d["experience"] = float(d.get("experience",0.0)) * (1.0 - float(recruited)/float(maxi(cap,1)))
            d["equip_float"] = minf(100.0,float(d.get("equip_float",d["equipment"])) + (2.0 if fighting else 6.0)*ratio)
            d["equipment"] = int(round(float(d["equip_float"])))
            var next_template: int = int(d.get("refit_target",-1))
            if next_template >= 0 and next_template < division_templates.size():
                d["refit_progress"] = minf(100.0,float(d.get("refit_progress",0.0)) + (2.0 if fighting else 6.0) * ratio)
                if float(d["refit_progress"]) >= 100.0:
                    var new_cells: Array = division_templates[next_template]["cells"]
                    var former_men: int = int(d["men"])
                    d["companies"] = new_cells.duplicate()
                    d["max_men"] = _template_stat(new_cells,"men")
                    d["template_id"] = next_template
                    d["refit_target"] = -1
                    d["refit_progress"] = 0.0
                    d["men"] = mini(former_men,int(d["max_men"]))
                    if former_men > int(d["max_men"]):
                        provinces[pid]["population"] = int(provinces[pid]["population"]) + former_men-int(d["max_men"])
                    _log_event("Дивизия %d переоснащена на шаблон %s" % [int(d["id"]),str(division_templates[next_template]["name"])])
    _profile_finish("Сутки: снабжение и пополнение", _day_perf_us)
    _resolve_battles()
    _advance_division_routes()
    _advance_training()
    _advance_politics()
    _day_perf_us = Time.get_ticks_usec()
    for country_id in countries.keys():
        var pop_total: int = 0
        for province_id in provinces.keys():
            if int(provinces[province_id]["owner"]) == int(country_id):
                pop_total += int(provinces[province_id]["population"])
        countries[country_id]["population"] = pop_total
    _profile_finish("Сутки: население стран", _day_perf_us)
    _day_perf_us = Time.get_ticks_usec()
    var active: Array[Dictionary] = []
    var disbanded: int = 0
    for d in divisions:
        if int(d["men"]) > 0 and (int(d["org"]) > 0 or int(d.get("battle_target",-1)) < 0):
            active.append(d)
        else:
            disbanded += 1
    divisions = active
    _update_division_supply()
    var active_ids: Array[int] = []
    for d in divisions:
        active_ids.append(int(d["id"]))
    for uid in selected_division_ids.duplicate():
        if not active_ids.has(uid):
            selected_division_ids.erase(uid)
    _profile_finish("Сутки: очистка и подсчёт", _day_perf_us)
    _day_perf_us = Time.get_ticks_usec()
    day += 1
    if day > 30:
        day = 1
        month += 1
    if month > 12:
        month = 1
        year += 1
    feedback.text = "+1 день · дивизий: %d · уничтожено: %d" % [divisions.size(), disbanded]
    if day % 5 == 0:
        _save_game()
    _refresh()
    _profile_finish("Сутки: финал", _day_perf_us)

func _province_in_battle(pid: int) -> bool:
    for unit in divisions:
        if int(unit.get("battle_target",-1)) == pid:
            return true
    return false

func _resolve_battles() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    battle_reports.clear()
    var battles: Dictionary = {}
    for unit in divisions:
        var target: int = int(unit.get("battle_target",-1))
        if target < 0 or not provinces.has(target) or int(unit["men"]) <= 0:
            continue
        if float(unit.get("org_float",unit["org"])) < 20.0:
            unit["battle_target"] = -1
            unit["route"] = []
            continue
        if not battles.has(target):
            battles[target] = []
        battles[target].append(unit)
    for raw_target in battles.keys():
        var target: int = int(raw_target)
        var candidates: Array = battles[target]
        var nation: int = int(candidates[0]["owner"])
        var attackers: Array = []
        var defenders: Array = []
        for unit in candidates:
            if int(unit["owner"]) == nation:
                attackers.append(unit)
            else:
                unit["battle_target"] = -1
                unit["route"] = []
        for unit in divisions:
            if int(unit["province"]) == target and int(unit["owner"]) != nation and int(unit["men"]) > 0:
                defenders.append(unit)
        if attackers.is_empty():
            continue
        var att_before: int = 0
        var def_before: int = 0
        var attack_total: float = 0.0
        var defense_total: float = 0.0
        for unit in attackers:
            att_before += int(unit["men"])
            attack_total += _combat_power(unit,"attack")
        for unit in defenders:
            def_before += int(unit["men"])
            defense_total += _combat_power(unit,"attack")
        var active_defenders: Array = []
        for unit in defenders:
            if float(unit.get("org_float",unit["org"])) >= 20.0:
                active_defenders.append(unit)
        var progress: float = float(battle_progress.get(target,0.0))
        var state: String = "Сражение продолжается"
        var trapped_defenders: Array = []
        for defender in defenders:
            if _choose_retreat_province(target,int(defender["owner"])) < 0:
                trapped_defenders.append(defender)
        if not active_defenders.is_empty() or not trapped_defenders.is_empty():
            # All shots are assigned before casualties are applied; target assignment rotates.
            var events: Array[Dictionary] = []
            var hits_per_target: Dictionary = {}
            var attack_seed: int = day + month*30 + year*360
            var defender_targets: Array = active_defenders if not active_defenders.is_empty() else trapped_defenders
            for i in range(attackers.size()):
                var victim: Dictionary = defender_targets[(i + attack_seed) % defender_targets.size()]
                var uid: int = int(victim["id"])
                hits_per_target[uid] = int(hits_per_target.get(uid,0))+1
            for i in range(active_defenders.size()):
                var victim: Dictionary = attackers[(i + attack_seed) % attackers.size()]
                var uid: int = int(victim["id"])
                hits_per_target[uid] = int(hits_per_target.get(uid,0))+1
            for i in range(attackers.size()):
                var shooter: Dictionary = attackers[i]
                var victim: Dictionary = defender_targets[(i + attack_seed) % defender_targets.size()]
                var hits: float = _battle_hits(shooter,victim,true)
                var focus: int = int(hits_per_target.get(int(victim["id"]),1))
                hits /= pow(float(focus),0.16)
                events.append({"target":victim,"hits":hits})
            for i in range(active_defenders.size()):
                var shooter: Dictionary = active_defenders[i]
                var victim: Dictionary = attackers[(i + attack_seed) % attackers.size()]
                var hits: float = _battle_hits(shooter,victim,false)
                var focus: int = int(hits_per_target.get(int(victim["id"]),1))
                hits /= pow(float(focus),0.16)
                events.append({"target":victim,"hits":hits})
            var total_hits: Dictionary = {}
            var by_id: Dictionary = {}
            for item in events:
                var victim: Dictionary = item["target"]
                var uid: int = int(victim["id"])
                total_hits[uid] = float(total_hits.get(uid,0.0))+float(item["hits"])
                by_id[uid] = victim
            for uid in total_hits.keys():
                _apply_battle_damage(by_id[uid],float(total_hits[uid]),1.0)
            for unit in trapped_defenders:
                if float(unit.get("org_float",unit["org"])) <= 0.0 and float(unit.get("hp",0.0)) <= 0.5:
                    var captured_percent: float = float(unit.get("equip_float",unit["equipment"])) * 0.20
                    var recipients: int = maxi(1,attackers.size())
                    for beneficiary in attackers:
                        var new_equipment: float = minf(100.0,float(beneficiary.get("equip_float",beneficiary["equipment"]))+captured_percent/float(recipients))
                        beneficiary["equip_float"] = new_equipment
                        beneficiary["equipment"] = int(round(new_equipment))
                    unit["men"] = 0
                    unit["equipment"] = 0
                    unit["equip_float"] = 0.0
            progress += clampf((attack_total-defense_total)/maxf(1.0,attack_total+defense_total)*10.0,-3.5,3.5)
        var can_attack: bool = false
        var attacker_org: int = 0
        var remaining_attackers: int = 0
        for unit in attackers:
            if int(unit["men"]) > 0 and float(unit.get("org_float",unit["org"])) >= 20.0:
                remaining_attackers += int(unit["men"])
                attacker_org = maxi(attacker_org,int(unit["org"]))
                if float(unit.get("org_float",unit["org"])) >= 20.0:
                    can_attack = true
            else:
                unit["battle_target"] = -1
                unit["route"] = []
        var remaining_defenders: int = 0
        var defender_org: int = 0
        var defenders_fighting: bool = false
        for unit in defenders:
            if int(unit["men"]) > 0:
                remaining_defenders += int(unit["men"])
                defender_org = maxi(defender_org,int(unit["org"]))
                if float(unit.get("org_float",unit["org"])) >= 20.0 or _choose_retreat_province(target,int(unit["owner"])) < 0:
                    defenders_fighting = true
        var victory: bool = not defenders_fighting and can_attack
        if victory:
            for unit in defenders:
                if int(unit["men"]) <= 0:
                    continue
                var retreat: int = _choose_retreat_province(target,int(unit["owner"]))
                if retreat >= 0:
                    unit["province"] = retreat
                    unit["route"] = []
                else:
                    # Surrounded divisions are destroyed only once organization is exhausted.
                    if float(unit.get("org_float",unit["org"])) <= 0.0:
                        unit["men"] = 0
            var occupiers: int = 0
            for unit in attackers:
                if int(unit["men"]) <= 0 or float(unit.get("org_float",unit["org"])) < 20.0:
                    unit["battle_target"] = -1
                    unit["route"] = []
                    continue
                occupiers += 1
                unit["travel_from"] = int(unit["province"])
                unit["province"] = target
                unit["battle_target"] = -1
                unit["travel_progress"] = 0.0
                var path: Array = unit.get("route",[])
                if not path.is_empty() and int(path[0]) == target:
                    path.pop_front()
                    unit["route"] = path
            if occupiers > 0:
                provinces[target]["controller"] = nation
                occupation_dirty = true
                state = "Провинция занята"
                progress = 100.0
                battle_progress.erase(target)
        elif not defenders_fighting or remaining_attackers <= 0:
            state = "Наступление прекращено · позиции сохранены"
            for unit in attackers:
                unit["battle_target"] = -1
                unit["route"] = []
            battle_progress.erase(target)
        var att_ids: Array[int] = []
        var def_ids: Array[int] = []
        for unit in attackers:
            att_ids.append(int(unit["id"]))
        for unit in defenders:
            def_ids.append(int(unit["id"]))
        battle_reports[target] = {"attacker":nation,"defender":int(provinces[target]["owner"]),"att_men":remaining_attackers,"def_men":remaining_defenders,"att_org":attacker_org,"def_org":defender_org,"att_lost":maxi(0,att_before-remaining_attackers),"def_lost":maxi(0,def_before-remaining_defenders),"progress":clampf(progress,0.0,100.0),"status":state,"advantage":clampf(attack_total/maxf(0.01,attack_total+defense_total),0.0,1.0),"attacker_ids":att_ids,"defender_ids":def_ids}
        if not victory and state == "Сражение продолжается":
            battle_progress[target] = clampf(progress,0.0,100.0)
    var active_targets: Dictionary = {}
    for unit in divisions:
        if int(unit.get("battle_target",-1)) >= 0:
            active_targets[int(unit["battle_target"])] = true
    for old_target in battle_progress.keys():
        if not active_targets.has(int(old_target)):
            battle_progress.erase(old_target)
    if occupation_dirty:
        _rebuild_occupation_texture()
        _recalculate_supply()
        occupation_dirty = false
    _check_capitulations()
    _profile_finish("Сутки: бои", _perf_start_us)

func _combat_power(d: Dictionary, which: String) -> float:
    var maximum: float = maxf(1.0,float(d.get("max_men",_division_stat(d,"men"))))
    var manpower: float = clampf(float(d["men"])/maximum,0.0,1.0)
    var equipment: float = clampf(float(d.get("equip_float",d["equipment"]))/100.0,0.0,1.0)
    var effectiveness: float = sqrt(manpower*equipment)
    var experience: float = 1.0 + clampf(float(d.get("experience",0.0)),0.0,100.0)*0.002
    return float(_division_stat(d,which))*effectiveness*experience

func _battle_hits(shooter: Dictionary, victim: Dictionary, attacking: bool) -> float:
    var hardness: float = clampf(float(_division_stat(victim,"hardness"))/100.0,0.0,1.0)
    var soft_attack: float = _combat_power(shooter,"attack")
    var hard_attack: float = _combat_power(shooter,"hard_attack")
    var attack: float = soft_attack*(1.0-hardness)+hard_attack*hardness
    var defense: float = _combat_power(victim,"defense")
    # The defender in its own province gets engineer and dug-in bonuses;
    # the attacking target does not receive those bonuses.
    # Engineers provide exactly one additional 5% fortification level; no terrain double-count.
    if attacking:
        var sappers: int = _division_cells(shooter).count("sappers")
        var enemy_fortification: float = float(victim.get("fortification",0.0))
        defense *= 1.0 + enemy_fortification * 0.01 * maxf(0.0,1.0-float(sappers)*0.02)
    # Defended attacks still cause limited damage; exceeding defense increases it smoothly.
    var hits: float = minf(attack,defense)*0.075+maxf(0.0,attack-defense)*0.22
    # Small, deterministic defensive advantage for an entrenched defender.
    if attacking:
        hits *= 0.94
    # Gradual logistical penalty: no penalty above 90%, reaches 50% at 0%.
    var supplies: float = clampf(float(shooter.get("supply",100))/100.0,0.0,1.0)
    var supply_penalty: float = 0.0
    if supplies < 0.90:
        supply_penalty = (0.90-supplies)/0.90*0.50
    var reserve: float = clampf(float(shooter.get("supply_reserve",3.0))/3.0,0.0,1.0)
    hits *= 1.0-supply_penalty*(1.0-reserve)
    if _division_stat(victim,"armor") > _division_stat(shooter,"piercing"):
        hits *= 0.65
    return hits

func _apply_battle_damage(d: Dictionary, hits: float, armor_factor: float) -> void:
    var maximum: float = maxf(1.0,float(d.get("max_men",_division_stat(d,"men"))))
    var hp_max: float = maxf(1.0,float(_division_stat(d,"hp")))
    var toughness: float = maxf(1.0,float(_division_stat(d,"toughness")))
    var hp_loss: float = hits*0.03*armor_factor
    var loss_ratio: float = hp_loss/hp_max
    var medics: int = _division_cells(d).count("medics")
    d["men"] = maxi(0,int(round(float(d["men"])-maximum*loss_ratio*maxf(0.0,1.0-float(medics)*0.01))))
    var equipment: float = float(d.get("equip_float",d["equipment"]))
    var repair_units: int = _division_cells(d).count("repair")
    equipment = clampf(equipment-loss_ratio*100.0*maxf(0.0,1.0-float(repair_units)*0.01),0.0,100.0)
    d["equip_float"] = equipment
    d["equipment"] = int(round(equipment))
    var org: float = float(d.get("org_float",d["org"]))
    org = maxf(0.0,org-hits*0.65*pow(4500.0/(4500.0+toughness),0.18))
    d["org_float"] = org
    d["org"] = int(round(org))
    var staffing: float = clampf(float(d["men"])/maximum,0.0,1.0)
    d["hp"] = hp_max*sqrt(staffing*(equipment/100.0))
    d["experience"] = minf(100.0,float(d.get("experience",0.0))+0.3)
    if float(d["experience"]) >= 45.0:
        d["level"] = 4
    elif float(d["experience"]) >= 15.0:
        d["level"] = maxi(int(d.get("level",2)),3)

func _province_unguarded(pid: int, nation: int) -> bool:
    for div in divisions:
        if int(div["province"]) == pid and int(div["owner"]) != nation and int(div["men"]) > 0 and int(div["org"]) > 0:
            return false
    return true

func _choose_retreat_province(pid: int, nation: int) -> int:
    for neighbor in provinces[pid]["neighbors"]:
        var nid: int = int(neighbor)
        if provinces.has(nid) and int(provinces[nid]["controller"]) == nation and _province_unguarded(nid, nation):
            return nid
    return -1

func _show_battle(pid: int) -> void:
    if not battle_reports.has(pid):
        feedback.text = "В этой провинции нет сражения"
        return
    active_battle_id = pid
    battle_panel.visible = true
    battle_panel.move_to_front()
    _refresh_battle_panel()

func _refresh_battle_panel() -> void:
    if battle_details == null or not battle_reports.has(active_battle_id):
        if battle_panel != null:
            battle_panel.visible = false
        return
    var report: Dictionary = battle_reports[active_battle_id]
    var advantage: int = int(round(float(report.get("advantage",0.5))*100.0))
    battle_title.text = "⚔  БОЙ ЗА ПРОВИНЦИЮ %d" % active_battle_id
    battle_details.text = "%s → %s    |    Преимущество: %d%%    |    Оттеснение: %d%%\nОрганизация: наступ. %d%% / обор. %d%% · Люди: %d / %d\nПотери за день: %d / %d   •   %s" % [NAMES[int(report["attacker"])],NAMES[int(report["defender"])],advantage,int(report["progress"]),int(report["att_org"]),int(report["def_org"]),int(report["att_men"]),int(report["def_men"]),int(report["att_lost"]),int(report["def_lost"]),str(report["status"])]
    for child in battle_units_row.get_children():
        battle_units_row.remove_child(child)
        child.queue_free()
    var sides: Array = [report.get("attacker_ids",[]),report.get("defender_ids",[])]
    for side in range(2):
        var group: VBoxContainer = VBoxContainer.new()
        group.custom_minimum_size.x = 350
        battle_units_row.add_child(group)
        group.add_child(_government_label("НАСТУПАЮЩИЕ" if side == 0 else "ОБОРОНЯЮЩИЕСЯ",20))
        var unit_ids: Array = sides[side]
        for unit_id in unit_ids:
            for d in divisions:
                if int(d["id"]) != int(unit_id):
                    continue
                var card: PanelContainer = _plain_panel(Color("#344d43") if side == 0 else Color("#543d40"))
                group.add_child(card)
                var info: VBoxContainer = VBoxContainer.new()
                card.add_child(info)
                info.add_child(_government_label("▣  %s" % str(d["name"]),18))
                info.add_child(_government_label("⚔ %d    ⛨ %d    ◉ %d%%    ♟ %s" % [_division_stat(d,"attack"),_division_stat(d,"defense"),int(d["org"]),_short_number(int(d["men"]))],16))
                break
        if unit_ids.is_empty():
            group.add_child(_government_label("Нет боеспособных дивизий",18))

func _cycle_battle() -> void:
    if battle_reports.is_empty():
        battle_panel.visible = false
        return
    var ids: Array = battle_reports.keys()
    ids.sort()
    var index: int = ids.find(active_battle_id)
    active_battle_id = int(ids[(index+1)%ids.size()])
    _refresh_battle_panel()

func _rebuild_occupation_texture() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    occupation_dirty = false
    # Province ID map is RGBA8. Read its raw bytes once, then build the overlay
    # without 1.5M get_pixel/set_pixel/Vector2 calls on the Android CPU.
    var source: PackedByteArray = province_image.get_data()
    var w: int = province_image.get_width()
    var h: int = province_image.get_height()
    if w <= 0 or h <= 0 or source.size() < w * h * 4:
        _profile_finish("Текстура: оккупация", _perf_start_us)
        return
    var occupied_rgba: Dictionary = {}
    for raw_id in provinces.keys():
        var pid: int = int(raw_id)
        var province: Dictionary = provinces[pid]
        if int(province["controller"]) != int(province["owner"]):
            var c: Color = COLORS[int(province["controller"])]
            occupied_rgba[pid] = PackedByteArray([int(round(c.r * 255.0)), int(round(c.g * 255.0)), int(round(c.b * 255.0)), 222])
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(w * h * 4)
    if not occupied_rgba.is_empty():
        for y in range(h):
            var row_base: int = y * w
            for x in range(w):
                if ((x + y) % 18) >= 5:
                    continue
                var idx: int = (row_base + x) * 4
                var pid: int = int(source[idx]) + 256 * int(source[idx + 1])
                if occupied_rgba.has(pid):
                    var rgba: PackedByteArray = occupied_rgba[pid]
                    bytes[idx] = rgba[0]
                    bytes[idx + 1] = rgba[1]
                    bytes[idx + 2] = rgba[2]
                    bytes[idx + 3] = rgba[3]
    var img: Image = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, bytes)
    if occupation_texture == null or occupation_texture.get_width() != w or occupation_texture.get_height() != h:
        occupation_texture = ImageTexture.create_from_image(img)
    else:
        occupation_texture.update(img)
    _profile_finish("Текстура: оккупация", _perf_start_us)

func _pick_at(screen_position: Vector2) -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    if _blocked_by_ui(screen_position):
        _profile_finish("Ввод: выбор карты", _perf_start_us)
        return
    # Double click on a foreign country has priority over province and unit selection.
    var foreign_country: int = _country_under_screen(screen_position)
    if foreign_country > 0 and foreign_country != player and not route_order_mode and pending_train < 0 and selected_province >= 0 and provinces.has(selected_province) and int(provinces[selected_province]["owner"]) == foreign_country and last_tap_ms > 0 and Time.get_ticks_msec() - last_tap_ms <= COUNTRY_DOUBLE_DETECTION_MS and screen_position.distance_to(last_tap_pos) <= 38.0:
        _cancel_pending_province_click()
        selected_province = -1
        inspected_division_id = -1
        _show_diplomacy(foreign_country)
        _refresh()
        last_tap_ms = -100000
        _profile_finish("Ввод: выбор карты", _perf_start_us)
        return
    if player > 0 and not route_order_mode and pending_train < 0:
        var clicked_map: Vector2 = (screen_position-offset)/zoom
        for marker_id in battle_reports.keys():
            var marker_pos: Vector2 = provinces[int(marker_id)]["pos"]
            if absf(clicked_map.y-marker_pos.y) <= 30.0 and minf(absf(clicked_map.x-marker_pos.x),MAP_W-absf(clicked_map.x-marker_pos.x)) <= 30.0:
                _show_battle(int(marker_id))
                _profile_finish("Ввод: выбор карты", _perf_start_us)
                return
    if player > 0 and not route_order_mode and pending_train < 0 and foreign_country == player:
        var hit: int = _hit_division(screen_position)
        if hit >= 0:
            if not selected_division_ids.has(hit):
                selected_division_ids.append(hit)
            inspected_division_id = hit
            selected_province = -1
            _refresh()
            _profile_finish("Ввод: выбор карты", _perf_start_us)
            return
    var map_point: Vector2 = (screen_position - offset) / zoom
    var xx: int = int(fposmod(map_point.x, MAP_W))
    var yy: int = int(map_point.y)
    if yy < 0 or yy >= province_image.get_height():
        _profile_finish("Ввод: выбор карты", _perf_start_us)
        return
    var pid: int = _province_id_at_map(Vector2(float(xx),float(yy)))
    if not provinces.has(pid):
        _clear_map_selection()
        _profile_finish("Ввод: выбор карты", _perf_start_us)
        return
    var prov: Dictionary = provinces[pid]
    if player == 0:
        selected_country = int(prov["owner"])
        _refresh()
        _profile_finish("Ввод: выбор карты", _perf_start_us)
        return
    if route_order_mode:
        _assign_group_route(pid)
        selected_division_ids.clear()
        inspected_division_id = -1
        _refresh()
        _profile_finish("Ввод: выбор карты", _perf_start_us)
        return
    if not selected_division_ids.is_empty() and pending_train < 0 and not selection_mode and int(prov["owner"]) == player and int(prov["controller"]) == player:
        _assign_group_route(pid)
        selected_division_ids.clear()
        inspected_division_id = -1
        _refresh()
        _profile_finish("Ввод: выбор карты", _perf_start_us)
        return
    if selection_mode:
        _pick_division(screen_position)
        _profile_finish("Ввод: выбор карты", _perf_start_us)
        return
    # A single tap picks a province immediately. The second tap on the same
    # foreign country upgrades the action to diplomacy; the province is hidden.
    var clicked_country: int = int(prov["owner"])
    var current_ms: int = Time.get_ticks_msec()
    if clicked_country != player and pending_train < 0:
        if last_tap_ms > 0 and current_ms - last_tap_ms <= COUNTRY_DOUBLE_DETECTION_MS and screen_position.distance_to(last_tap_pos) <= 38.0:
            _cancel_pending_province_click()
            selected_province = -1
            inspected_division_id = -1
            _refresh()
            _show_diplomacy(clicked_country)
            last_tap_ms = -100000
            _profile_finish("Ввод: выбор карты", _perf_start_us)
            return
    _cancel_pending_province_click()
    _pick_province_immediately(pid)
    _profile_finish("Ввод: выбор карты", _perf_start_us)

func _pick_province_immediately(pid: int) -> void:
    if not provinces.has(pid):
        return
    var prov: Dictionary = provinces[pid]
    selected_province = pid
    selected_country = 0  # Display the province outline, not the whole country.
    inspected_division_id = -1
    if battle_reports.has(pid) and moving_division < 0:
        _show_battle(pid)
    if int(prov["owner"]) == player:
        _close_diplomacy()
    if pending_train >= 0 and int(prov["controller"]) == player and not editor_panel.visible:
        _deploy_pending()
        return
    _refresh()

func _cancel_pending_province_click() -> void:
    pending_province_click = -1
    pending_province_country = 0
    pending_province_timestamp = 0

func _country_under_screen(at: Vector2) -> int:
    if province_image == null:
        return -1
    var map_point: Vector2 = (at-offset)/zoom
    var yy: int = int(map_point.y)
    if yy < 0 or yy >= province_image.get_height():
        return -1
    var pid: int = _province_id_at_map(Vector2(float(int(fposmod(map_point.x,MAP_W))),float(yy)))
    if provinces.has(pid):
        return int(provinces[pid]["owner"])
    return -1

func _clear_map_selection() -> void:
    _cancel_pending_province_click()
    selected_province = -1
    selected_country = 0
    inspected_division_id = -1
    selected_division_ids.clear()
    selection_mode = false
    selecting_rectangle = false
    if diplomacy_panel != null:
        _close_diplomacy()
    if battle_panel != null:
        battle_panel.visible = false
    _refresh()

func _blocked_by_ui(at: Vector2) -> bool:
    for panel in [training_panel,editor_panel,company_picker,game_menu_panel,game_log_panel,dev_panel,government_panel,diplomacy_panel,battle_panel,province_panel,division_panel,country_choice,header,game_menu_button]:
        if panel != null and panel.visible and (panel as Control).get_global_rect().has_point(at):
            return true
    return false

func _zoom_at(factor: float, at: Vector2) -> void:
    var before: float = zoom
    zoom = clampf(zoom * factor, size.y / MAP_H, maxf(6.0, size.y / MAP_H * 8.0))
    offset = at - (at - offset) * (zoom / before)
    _limit_camera()
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    # Android may send both touchscreen and synthesized mouse events for one tap.
    # Ignoring the duplicate prevents a single tap from triggering diplomacy.
    if event is InputEventMouseButton and OS.has_feature("mobile") and Time.get_ticks_msec() - last_touch_event_ms < 220:
        _profile_finish("Ввод: события", _perf_start_us)
        return
    if event is InputEventScreenTouch:
        last_touch_event_ms = Time.get_ticks_msec()
    if event is InputEventMouseButton:
        var mb: InputEventMouseButton = event
        # UI input must never become a map click on mouse release.
        if _blocked_by_ui(mb.position):
            drag_mouse = false
            selecting_rectangle = false
            unit_drag_active = false
            unit_drag_id = -1
            _profile_finish("Ввод: события", _perf_start_us)
            return
        if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
            _zoom_at(1.15, mb.position)
        elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
            _zoom_at(1.0 / 1.15, mb.position)
        elif mb.button_index == MOUSE_BUTTON_LEFT:
            if mb.pressed:
                if _blocked_by_ui(mb.position):
                    _profile_finish("Ввод: события", _perf_start_us)
                    return
                drag_mouse = true
                unit_drag_id = _hit_division(mb.position) if not selection_mode and player > 0 else -1
                unit_drag_start = mb.position
                unit_drag_pos = mb.position
                unit_drag_active = false
                mouse_last = mb.position
                drag_length = 0.0
                var now_ms: int = Time.get_ticks_msec()
                if selection_mode and (mb.double_click or (now_ms - last_tap_ms < 350 and mb.position.distance_to(last_tap_pos) < 28.0)) and _country_under_screen(mb.position) == player:
                    selection_mode = true
                    unit_drag_id = -1
                    selection_start = mb.position
                    selection_end = mb.position
                    selecting_rectangle = true
            else:
                if unit_drag_active and unit_drag_id >= 0:
                    _finish_unit_drag(mb.position)
                elif selecting_rectangle and selection_mode:
                    selection_end = mb.position
                    _select_divisions_in_rectangle(Rect2(selection_start,selection_end - selection_start).abs())
                    selecting_rectangle = false
                elif drag_mouse and drag_length < 12.0:
                    _pick_at(mb.position)
                last_tap_ms = Time.get_ticks_msec()
                last_tap_pos = mb.position
                selection_mode = false
                drag_mouse = false
                unit_drag_id = -1
                unit_drag_active = false
    elif event is InputEventMouseMotion and drag_mouse:
        var mm: InputEventMouseMotion = event
        drag_length += mouse_last.distance_to(mm.position)
        if selection_mode:
            selection_end = mm.position
        elif unit_drag_id >= 0:
            unit_drag_pos = mm.position
            unit_drag_active = unit_drag_active or unit_drag_start.distance_to(mm.position) > 18.0
            unit_drag_destination = _province_at_screen(mm.position)
        else:
            offset += mm.position - mouse_last
        mouse_last = mm.position
        _limit_camera()
        queue_redraw()
    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            if _blocked_by_ui(touch.position):
                _profile_finish("Ввод: события", _perf_start_us)
                return
            touch_points[touch.index] = touch.position
            drag_length = 0.0
            if touch_points.size() == 1:
                unit_drag_id = _hit_division(touch.position) if player > 0 else -1
                unit_drag_start = touch.position
                unit_drag_pos = touch.position
                unit_drag_active = false
            var now_ms: int = Time.get_ticks_msec()
            if selection_mode and touch_points.size() == 1 and now_ms - last_tap_ms < 350 and touch.position.distance_to(last_tap_pos) < 28.0:
                selection_mode = true
                unit_drag_id = -1
                selecting_rectangle = true
                selection_start = touch.position
                selection_end = touch.position
        else:
            if _blocked_by_ui(touch.position):
                touch_points.erase(touch.index)
                unit_drag_id = -1
                unit_drag_active = false
                selection_mode = false
                selecting_rectangle = false
                _profile_finish("Ввод: события", _perf_start_us)
                return
            if unit_drag_active and unit_drag_id >= 0 and touch_points.size() == 1:
                _finish_unit_drag(touch.position)
            elif selection_mode and selecting_rectangle and touch_points.size() == 1:
                selection_end = touch.position
                _select_divisions_in_rectangle(Rect2(selection_start,selection_end - selection_start).abs())
                selecting_rectangle = false
            elif touch_points.has(touch.index) and touch_points.size() == 1 and drag_length < 15.0:
                _pick_at(touch.position)
            if touch_points.size() == 1:
                last_tap_ms = Time.get_ticks_msec()
                last_tap_pos = touch.position
            selection_mode = false
            unit_drag_id = -1
            unit_drag_active = false
            touch_points.erase(touch.index)
            pinch_dist = 0.0
    elif event is InputEventScreenDrag:
        var drag: InputEventScreenDrag = event
        if not touch_points.has(drag.index):
            _profile_finish("Ввод: события", _perf_start_us)
            return
        var previous: Vector2 = touch_points[drag.index]
        touch_points[drag.index] = drag.position
        if touch_points.size() == 1:
            drag_length += previous.distance_to(drag.position)
            if selection_mode:
                selection_end = drag.position
            elif unit_drag_id >= 0:
                unit_drag_pos = drag.position
                unit_drag_active = unit_drag_active or unit_drag_start.distance_to(drag.position) > 18.0
                unit_drag_destination = _province_at_screen(drag.position)
            else:
                offset += drag.position - previous
            _limit_camera()
            queue_redraw()
        elif touch_points.size() == 2:
            var points: Array = touch_points.values()
            var d: float = (points[0] as Vector2).distance_to(points[1] as Vector2)
            if pinch_dist > 1.0:
                _zoom_at(d / pinch_dist, ((points[0] as Vector2) + (points[1] as Vector2)) * 0.5)
            pinch_dist = d
            drag_length = 100.0
            selecting_rectangle = false
            unit_drag_id = -1
            unit_drag_active = false
    _profile_finish("Ввод: события", _perf_start_us)

func _province_at_screen(screen_pos: Vector2) -> int:
    var map_pos: Vector2 = (screen_pos - offset) / zoom
    if map_pos.y < 0.0 or map_pos.y >= MAP_H:
        return -1
    return _province_id_at_map(Vector2(fposmod(map_pos.x, MAP_W),map_pos.y))

func _finish_unit_drag(screen_pos: Vector2) -> void:
    var destination: int = _province_at_screen(screen_pos)
    if not provinces.has(destination):
        return
    selected_division_ids = [unit_drag_id]
    inspected_division_id = unit_drag_id
    _assign_group_route(destination)
    selected_division_ids.clear()
    inspected_division_id = -1
    _log_event("Перетаскивание дивизии %d к провинции %d" % [unit_drag_id,destination])
    _refresh()

func _log_event(message: String) -> void:
    debug_messages.append("%02d.%02d.%04d | %s" % [day,month,year,message])
    while debug_messages.size() > 80:
        debug_messages.pop_front()

func _build_game_menu() -> void:
    var menu_button: Button = _ui_button("☰", _toggle_game_menu, 46)
    game_menu_button = menu_button
    menu_button.anchor_left = 1.0
    menu_button.anchor_right = 1.0
    menu_button.offset_left = -412
    menu_button.offset_right = -365
    menu_button.offset_top = 5
    menu_button.offset_bottom = 55
    add_child(menu_button)
    menu_button.move_to_front()
    game_menu_panel = _plain_panel(Color("#1c3040fc"))
    game_menu_panel.anchor_left = 1.0
    game_menu_panel.anchor_right = 1.0
    game_menu_panel.offset_left = -415
    game_menu_panel.offset_right = -6
    game_menu_panel.offset_top = 68
    game_menu_panel.offset_bottom = 333
    add_child(game_menu_panel)
    var menu_box: VBoxContainer = VBoxContainer.new()
    game_menu_panel.add_child(menu_box)
    menu_box.add_child(_government_label("МЕНЮ ИГРЫ", 22))
    menu_box.add_child(_ui_button("Журнал событий и ошибок", _show_game_log))
    menu_box.add_child(_ui_button("Скопировать отчёт", _copy_debug_report))
    menu_box.add_child(_ui_button("Сбросить замеры", _profile_reset))
    menu_box.add_child(_ui_button("Режим разработчика", _toggle_developer_mode))
    menu_box.add_child(_ui_button("Новая игра", _restart_campaign))
    menu_box.add_child(_ui_button("Закрыть", _toggle_game_menu))
    game_menu_panel.visible = false
    dev_panel = _plain_panel(Color("#263b48f8"))
    dev_panel.anchor_left = 1.0
    dev_panel.anchor_right = 1.0
    dev_panel.offset_left = -415
    dev_panel.offset_right = -6
    dev_panel.offset_top = 339
    dev_panel.offset_bottom = 485
    add_child(dev_panel)
    var dev_box: VBoxContainer = VBoxContainer.new()
    dev_panel.add_child(dev_box)
    dev_box.add_child(_government_label("ИНСТРУМЕНТЫ ТЕСТИРОВАНИЯ", 19))
    dev_box.add_child(_ui_button("Время: 100 дней/с · вкл/выкл", _toggle_fast_time))
    dev_box.add_child(_ui_button("Мгновенно завершить всю подготовку", _instant_training))
    dev_panel.visible = false
    game_log_panel = _plain_panel(Color("#1d303ffa"))
    game_log_panel.anchor_left = 0.2
    game_log_panel.anchor_right = 0.8
    game_log_panel.anchor_top = 0.1
    game_log_panel.anchor_bottom = 0.9
    add_child(game_log_panel)
    var logs: VBoxContainer = VBoxContainer.new()
    game_log_panel.add_child(logs)
    var logrow: HBoxContainer = HBoxContainer.new()
    logs.add_child(logrow)
    var logtitle: Label = _government_label("ЖУРНАЛ СОБЫТИЙ", 22)
    logtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    logrow.add_child(logtitle)
    logrow.add_child(_ui_button("Копировать", _copy_debug_report))
    logrow.add_child(_ui_button("×", func() -> void: game_log_panel.visible = false, 48))
    game_log_text = TextEdit.new()
    game_log_text.editable = false
    game_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
    game_log_text.add_theme_font_size_override("font_size", 17)
    logs.add_child(game_log_text)
    game_log_panel.visible = false

func _toggle_game_menu() -> void:
    game_menu_panel.visible = not game_menu_panel.visible
    if game_menu_panel.visible:
        game_menu_panel.move_to_front()
    game_menu_button.move_to_front()

func _show_game_log() -> void:
    game_log_text.text = "\n".join(PackedStringArray(debug_messages))
    game_log_panel.visible = true
    game_log_panel.move_to_front()
    game_menu_panel.visible = false

func _toggle_developer_mode() -> void:
    developer_mode = not developer_mode
    dev_panel.visible = developer_mode
    if developer_mode:
        dev_panel.move_to_front()
    else:
        developer_speed = false
    _log_event("Режим разработчика: %s" % ("включён" if developer_mode else "выключен"))

func _toggle_fast_time() -> void:
    developer_speed = not developer_speed
    if developer_speed:
        speed = 3
    _log_event("Ускорение 100 дней/с: %s" % ("включено" if developer_speed else "выключено"))

func _instant_training() -> void:
    if not developer_mode:
        return
    var pending: Array[int] = []
    for item in training_queue:
        pending.append(int(item["id"]))
    for record_id in pending:
        _finish_training(record_id)
    _log_event("Вся подготовка завершена разработчиком")

func _restart_campaign() -> void:
    get_tree().reload_current_scene()

func _copy_debug_report() -> void:
    var fps: float = Performance.get_monitor(Performance.TIME_FPS)
    var frame_time: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
    var physics_time: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
    var ram_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)
    var moving_count: int = 0
    var low_supply: int = 0
    for d in divisions:
        if not (d.get("route",[]) as Array).is_empty():
            moving_count += 1
        if int(d.get("supply",100)) < 75:
            low_supply += 1
    var report: String = "PoliticalEarth v0.1.33 | Godot %s | %s\n" % [Engine.get_version_info().get("string","4.x"),OS.get_name()]
    report += "FPS %.1f | Кадр логики %.2f мс | Физика %.2f мс | RAM %.1f МБ\n" % [fps,frame_time,physics_time,ram_mb]
    report += "Самый долгий кадр %.1f мс | Кадров более 50 мс: %d | Последний всплеск: %.1f мс\n" % [max_frame_ms,slow_frames,last_slow_frame_ms]
    report += "Карта: %d провинций | Режим: %d | Камера: %.2f | Дата: %02d.%02d.%04d\n" % [provinces.size(),mode,zoom,day,month,year]
    report += "Армии: %d дивизий, движутся %d, низкое снабжение %d, активные бои %d\n" % [divisions.size(),moving_count,low_supply,battle_reports.size()]
    report += "Игрок %d | Скорость %d | Очередь обучения %d\n" % [player,speed,training_queue.size()]
    report += "Интерфейс: редактор=%s дипломатия=%s провинция=%d выделено=%d\n" % [str(editor_panel.visible),str(diplomacy_panel.visible),selected_province,selected_division_ids.size()]
    if provinces.has(selected_province):
        var province_data: Dictionary = provinces[selected_province]
        report += "Провинция #%d: снабжение %d, потребность %d, население %d, контролёр %d\n" % [selected_province,int(province_data["supply"]),_province_demand(selected_province),int(province_data["population"]),int(province_data["controller"])]
    report += "\n" + _profile_report() + "\n\n"
    report += "Последние события:\n" + "\n".join(PackedStringArray(debug_messages.slice(maxi(0,debug_messages.size()-12))))
    DisplayServer.clipboard_set(report)
    _log_event("Диагностический отчёт скопирован")

func _save_game() -> void:
    # No autosave: each application launch starts from the initial state.
    pass

func _load_game() -> void:
    var path_to_load: String = SAVE_PATH
    if not FileAccess.file_exists(path_to_load):
        if FileAccess.file_exists("user://PoliticalEarth_v09.json"):
            path_to_load = "user://PoliticalEarth_v09.json"
        elif FileAccess.file_exists("user://PoliticalEarth_v07.json"):
            path_to_load = "user://PoliticalEarth_v07.json"
        elif FileAccess.file_exists("user://PoliticalEarth_v06.json"):
            path_to_load = "user://PoliticalEarth_v06.json"
        else:
            return
    var save: Variant = JSON.parse_string(FileAccess.get_file_as_string(path_to_load))
    if not (save is Dictionary):
        return
    player = clampi(int(save.get("player", 0)), 0, 5)
    selected_country = player
    day = clampi(int(save.get("day", 1)), 1, 30)
    month = clampi(int(save.get("month", 1)), 1, 12)
    year = int(save.get("year", 2000))
    if save.has("countries") and save["countries"] is Dictionary:
        for key in save["countries"].keys():
            var number: int = int(key)
            if countries.has(number):
                countries[number] = save["countries"][key]
    if save.has("province_changes") and save["province_changes"] is Dictionary:
        for key in save["province_changes"].keys():
            var id: int = int(key)
            if not provinces.has(id):
                continue
            var change: Dictionary = save["province_changes"][key]
            provinces[id]["farms"] = int(change.get("farms", 0))
            provinces[id]["depot"] = bool(change.get("depot", false))
            provinces[id]["port"] = bool(change.get("port", false))
            provinces[id]["controller"] = int(change.get("controller", provinces[id]["owner"]))
            provinces[id]["population"] = int(change.get("population",provinces[id]["population"]))
            provinces[id]["recruited"] = int(change.get("recruited",0))
    if save.has("divisions") and save["divisions"] is Array:
        divisions.clear()
        for item in save["divisions"]:
            if item is Dictionary and provinces.has(int(item.get("province", -1))):
                if not item.has("route"):
                    item["route"] = []
                if not item.has("travel_from"):
                    item["travel_from"] = int(item["province"])
                if not item.has("companies"):
                    item["companies"] = _division_cells(item)
                if not item.has("max_men"):
                    item["max_men"] = _division_stat(item,"men")
                if not item.has("experience"):
                    item["experience"] = 0.0
                divisions.append(item)
    if save.has("armies") and save["armies"] is Array:
        armies.clear()
        for item in save["armies"]:
            if item is Dictionary:
                armies.append(item)
    if save.has("country_government") and save["country_government"] is Dictionary:
        for raw_country in save["country_government"].keys():
            var country_id: int = int(raw_country)
            if country_government.has(country_id) and save["country_government"][raw_country] is Dictionary:
                var persisted: Dictionary = save["country_government"][raw_country]
                for prop in ["law","pending_law","law_days","mobilization_ready","parties","war_days"]:
                    if persisted.has(prop):
                        country_government[country_id][prop] = persisted[prop]
    if save.has("wars") and save["wars"] is Dictionary:
        wars = save["wars"]
    if save.has("capitulated") and save["capitulated"] is Dictionary:
        capitulated = save["capitulated"]
    if save.has("battle_progress") and save["battle_progress"] is Dictionary:
        for key in save["battle_progress"].keys():
            battle_progress[int(key)] = float(save["battle_progress"][key])
    division_number = maxi(int(save.get("division_number", division_number)), 1)
    army_counter = maxi(int(save.get("army_counter", 1)), 1)
    template_infantry = maxi(int(save.get("template_infantry", 3)), 0)
    template_artillery = maxi(int(save.get("template_artillery", 1)), 0)
    # loaded after _init_templates, retain the defaults when old save lacks templates
    if save.has("division_templates") and save["division_templates"] is Array:
        division_templates.clear()
        for data in save["division_templates"]:
            if data is Dictionary and data.has("cells"):
                var normalized: Array = data.get("cells", [])
                while normalized.size() < 20:
                    normalized.append("")
                while normalized.size() > 20:
                    normalized.pop_back()
                data["cells"] = normalized
                division_templates.append(data)


func _rebuild_supply_texture() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    var img: Image = SEA.get_image()
    img.convert(Image.FORMAT_RGBA8)
    for yy in range(int(MAP_H)):
        for xx in range(int(MAP_W)):
            var pid: int = _province_id_at_map(Vector2(float(xx),float(yy)))
            if not provinces.has(pid):
                continue
            var ratio: float = clampf(float(provinces[pid]["supply"]) / 90.0,0.0,1.0)
            img.set_pixel(xx,yy,Color("#c15a50").lerp(Color("#4ca66f"),ratio))
    supply_texture = ImageTexture.create_from_image(img)
    _profile_finish("Текстура: снабжение", _perf_start_us)

func _at_war(a: int, b: int) -> bool:
    return bool(wars.get("%d_%d" % [mini(a,b),maxi(a,b)], false))

func _set_diplomacy_tab(which: int) -> void:
    diplomacy_tab = which
    for i in range(diplomacy_tab_buttons.size()):
        diplomacy_tab_buttons[i].modulate = Color("#f5cd83") if i == which else Color("#a1adba")
    if diplomacy_actions_container != null:
        diplomacy_actions_container.visible = which == 0
    if diplomacy_overview_container != null:
        diplomacy_overview_container.visible = which == 1

func _show_diplomacy(country_id: int) -> void:
    if player <= 0 or country_id == player:
        return
    selected_country = country_id
    diplomacy_flag.texture = FLAGS[country_id - 1]
    diplomacy_name.text = NAMES[country_id]
    diplomacy_details.text = "Население: %s\nСтатус: %s" % [_short_number(int(countries[country_id]["population"])), "Капитулировала" if bool(capitulated.get(str(country_id),false)) else "Независима"]
    for widget in diplomacy_relations_list.get_children():
        diplomacy_relations_list.remove_child(widget)
        widget.queue_free()
    for rival in range(1,6):
        if rival == country_id or not _at_war(rival,country_id):
            continue
        var relation_row: HBoxContainer = HBoxContainer.new()
        relation_row.add_theme_constant_override("separation",13)
        diplomacy_relations_list.add_child(relation_row)
        relation_row.add_child(_diplomacy_small_flag(country_id))
        var war_symbol: Label = _government_label("⚔",19)
        war_symbol.custom_minimum_size.x = 28
        war_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        relation_row.add_child(war_symbol)
        relation_row.add_child(_diplomacy_small_flag(rival))
    diplomacy_war.disabled = _at_war(player,country_id)
    diplomacy_war.text = "⚔  Идёт война" if diplomacy_war.disabled else "⚔  Объявить войну"
    _set_diplomacy_tab(diplomacy_tab)
    var already_open: bool = diplomacy_panel.visible
    diplomacy_panel.visible = true
    diplomacy_shown = true
    diplomacy_panel.move_to_front()
    if not already_open:
        # Start completely outside the left edge, slide into anchored position.
        var target_pos: Vector2 = diplomacy_panel.position
        diplomacy_panel.position = Vector2(-maxf(440.0,diplomacy_panel.size.x + 8.0), target_pos.y)
        var slide: Tween = create_tween()
        slide.set_trans(Tween.TRANS_CUBIC)
        slide.set_ease(Tween.EASE_OUT)
        slide.tween_property(diplomacy_panel,"position",target_pos,0.22)
    queue_redraw()

func _diplomacy_small_flag(nation: int) -> TextureRect:
    var texture: TextureRect = TextureRect.new()
    texture.texture = FLAGS[nation - 1]
    texture.custom_minimum_size = Vector2(35,21)
    texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    return texture

func _play_as_diplomatic_country() -> void:
    if selected_country <= 0 or selected_country == player:
        return
    player = selected_country
    selected_country = 0
    selected_division_ids.clear()
    selected_province = -1
    route_order_mode = false
    moving_division = -1
    _close_diplomacy()
    _center_on_capital(player)
    _refresh()

func _close_diplomacy() -> void:
    if diplomacy_panel == null:
        return
    diplomacy_shown = false
    diplomacy_panel.visible = false
    selected_country = 0
    queue_redraw()

func _switch_diplomacy(direction: int) -> void:
    var next_country: int = selected_country
    for i in range(5):
        next_country = ((next_country - 1 + direction + 5) % 5) + 1
        if next_country != player:
            _show_diplomacy(next_country)
            return

func _declare_war() -> void:
    if player <= 0 or selected_country <= 0 or selected_country == player or bool(capitulated.get(str(player),false)) or bool(capitulated.get(str(selected_country),false)):
        return
    var key: String = "%d_%d" % [mini(player,selected_country),maxi(player,selected_country)]
    wars[key] = true
    feedback.text = "Война с государством %s" % NAMES[selected_country]
    _show_diplomacy(selected_country)
    _save_game()

func _build_government_ui() -> void:
    government_panel = _plain_panel(Color("#202e3cfb"))
    government_panel.anchor_left = 0.10
    government_panel.anchor_right = 0.90
    government_panel.anchor_top = 0.035
    government_panel.anchor_bottom = 0.90
    add_child(government_panel)
    var root: VBoxContainer = VBoxContainer.new()
    root.add_theme_constant_override("separation", 9)
    government_panel.add_child(root)
    var top_bar: HBoxContainer = HBoxContainer.new()
    root.add_child(top_bar)
    for tab_index in range(2):
        var captured_tab: int = tab_index
        var tab_button: Button = _ui_button(["♜ Правительство", "⚖ Законы"][tab_index], func() -> void: _set_government_tab(captured_tab), 225)
        top_bar.add_child(tab_button)
        government_tab_buttons.append(tab_button)
    var filler: Control = Control.new()
    filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top_bar.add_child(filler)
    top_bar.add_child(_ui_button("×", _close_government, 56))
    gov_scroll = ScrollContainer.new()
    gov_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    gov_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(gov_scroll)
    government_body = VBoxContainer.new()
    government_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    government_body.add_theme_constant_override("separation", 12)
    gov_scroll.add_child(government_body)
    government_panel.visible = false

func _open_government() -> void:
    if player <= 0:
        return
    if diplomacy_shown:
        _close_diplomacy()
    government_panel.visible = true
    government_panel.move_to_front()
    government_tab = 0
    law_detail_open = false
    _refresh_government()

func _close_government() -> void:
    government_panel.visible = false

func _set_government_tab(tab_id: int) -> void:
    government_tab = tab_id
    law_detail_open = false
    _refresh_government()

func _open_mobilization_law() -> void:
    law_detail_open = true
    _refresh_government()

func _close_mobilization_law() -> void:
    law_detail_open = false
    _refresh_government()

func _government_label(content: String, font: int = 20) -> Label:
    var result_label: Label = Label.new()
    result_label.text = content
    result_label.add_theme_font_size_override("font_size",font)
    result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return result_label

func _update_government_live() -> void:
    if government_panel == null or not government_panel.visible or player <= 0:
        return
    var gov: Dictionary = country_government[player]
    # Rebuild only when tab-relevant structural data changed, not each game day.
    if government_rendered_player != player or government_rendered_law != int(gov["law"]) or government_rendered_pending != int(gov["pending_law"]) or (government_tab == 0 and government_rendered_month != month):
        _refresh_government()
        return
    if government_countdown_label != null and is_instance_valid(government_countdown_label):
        var pending: int = int(gov["pending_law"])
        if pending >= 0:
            government_countdown_label.text = "Принятие: %s · осталось %d дней" % [LAW_NAMES[pending], int(gov["law_days"])]

func _refresh_government() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    if government_panel == null or not government_panel.visible or player <= 0:
        _profile_finish("Интерфейс: правительство", _perf_start_us)
        return
    government_countdown_label = null
    government_rendered_law = int(country_government[player]["law"])
    government_rendered_pending = int(country_government[player]["pending_law"])
    government_rendered_player = player
    government_rendered_month = month
    for node in government_body.get_children():
        government_body.remove_child(node)
        node.queue_free()
    for i in range(government_tab_buttons.size()):
        government_tab_buttons[i].modulate = Color("#fff0bd") if i == government_tab else Color("#abb9c4")
    var gov: Dictionary = country_government[player]
    if government_tab == 0:
        var main_row: HBoxContainer = HBoxContainer.new()
        main_row.add_theme_constant_override("separation", 28)
        government_body.add_child(main_row)
        var leader_column: VBoxContainer = VBoxContainer.new()
        leader_column.custom_minimum_size.x = 240
        leader_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        leader_column.add_theme_constant_override("separation", 9)
        main_row.add_child(leader_column)
        var portrait: TextureRect = TextureRect.new()
        portrait.texture = load("res://assets/leader_%d.png" % player)
        portrait.custom_minimum_size = Vector2(222, 224)
        portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        leader_column.add_child(portrait)
        var person: Label = _government_label(LEADER_NAMES[player], 22)
        person.add_theme_color_override("font_color", Color("#f4d79b"))
        leader_column.add_child(person)
        leader_column.add_child(_government_label("♜  %s" % GOVERNMENTS[player], 18))
        var party_panel: VBoxContainer = VBoxContainer.new()
        party_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        party_panel.add_theme_constant_override("separation", 8)
        main_row.add_child(party_panel)
        party_panel.add_child(_government_label("ПОДДЕРЖКА ПАРТИЙ", 22))
        var support_values: Array = gov["parties"]
        var chart_script: Script = load("res://party_chart.gd") as Script
        var chart: Control = chart_script.new()
        chart.custom_minimum_size = Vector2(200, 200)
        chart.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        party_panel.add_child(chart)
        chart.set("segments", support_values)
        chart.queue_redraw()
        for k in range(4):
            var line: HBoxContainer = HBoxContainer.new()
            line.custom_minimum_size = Vector2(430,35)
            line.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
            line.add_theme_constant_override("separation",10)
            party_panel.add_child(line)
            var square: ColorRect = ColorRect.new()
            square.color = PARTY_COLORS[k]
            square.custom_minimum_size = Vector2(20,20)
            square.mouse_filter = Control.MOUSE_FILTER_IGNORE
            line.add_child(square)
            var party_label: Label = _government_label(PARTY_LABELS[k], 19)
            party_label.custom_minimum_size.x = 265
            line.add_child(party_label)
            var percent: Label = _government_label("%d%%" % int(support_values[k]), 19)
            percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
            percent.custom_minimum_size.x = 60
            line.add_child(percent)
    elif not law_detail_open:
        government_body.add_child(_government_label("ГОСУДАРСТВЕННЫЕ ЗАКОНЫ", 23))
        var law_area: Control = Control.new()
        law_area.custom_minimum_size.y = 180
        government_body.add_child(law_area)
        var law_tile: Button = _ui_button("⚔  Воинская обязанность     ·     %s" % LAW_NAMES[int(gov["law"])], _open_mobilization_law)
        law_tile.custom_minimum_size = Vector2(490, 92)
        law_tile.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
        government_body.add_child(law_tile)
    else:
        var law_top: HBoxContainer = HBoxContainer.new()
        government_body.add_child(law_top)
        law_top.add_child(_ui_button("← Законы", _close_mobilization_law, 170))
        var law_heading: Label = _government_label("ВОИНСКАЯ ОБЯЗАННОСТЬ", 23)
        law_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        law_top.add_child(law_heading)
        var active: int = int(gov["law"])
        var pending: int = int(gov["pending_law"])
        government_body.add_child(_government_label("Действует: %s · %.0f%% населения" % [LAW_NAMES[active], LAW_RATES[active] * 100.0], 19))
        if pending >= 0:
            government_countdown_label = _government_label("Принятие: %s · осталось %d дней" % [LAW_NAMES[pending], int(gov["law_days"])], 18)
            government_body.add_child(government_countdown_label)
        for law_idx in range(LAW_NAMES.size()):
            var index: int = law_idx
            var card: PanelContainer = _plain_panel(Color("#435542") if index == active else Color("#304557"))
            government_body.add_child(card)
            var row: HBoxContainer = HBoxContainer.new()
            row.add_theme_constant_override("separation", 12)
            card.add_child(row)
            var glyph: Label = _government_label(["✧", "♙", "♟", "⚔", "✦"][index], 30)
            glyph.custom_minimum_size.x = 54
            row.add_child(glyph)
            var texts: VBoxContainer = VBoxContainer.new()
            texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            row.add_child(texts)
            texts.add_child(_government_label(LAW_NAMES[index], 20))
            texts.add_child(_government_label("Доступно для мобилизации: %.0f%% населения" % (LAW_RATES[index] * 100.0), 16))
            var apply: Button = _ui_button("Действует" if index == active else ("Принимается" if index == pending else "Принять"), func() -> void: _propose_law(index), 138)
            apply.disabled = index == active or pending >= 0
            row.add_child(apply)
    _profile_finish("Интерфейс: правительство", _perf_start_us)

func _propose_law(index: int) -> void:
    if player <= 0 or index < 0 or index >= LAW_NAMES.size():
        return
    var gov: Dictionary = country_government[player]
    if int(gov["pending_law"]) >= 0 or int(gov["law"]) == index:
        return
    gov["pending_law"] = index
    gov["law_days"] = 15
    _refresh_government()

func _recruitment_pools(origin: int, nation: int) -> Array[int]:
    # Expand through friendly controlled provinces, in distance order.
    var pool: Array[int] = [origin]
    var visited: Dictionary = {origin: true}
    var cursor: int = 0
    while cursor < pool.size():
        var current: int = pool[cursor]
        cursor += 1
        for raw_id in provinces[current]["neighbors"]:
            var other: int = int(raw_id)
            if visited.has(other) or not provinces.has(other):
                continue
            if int(provinces[other]["owner"]) != nation or int(provinces[other]["controller"]) != nation:
                continue
            visited[other] = true
            pool.append(other)
    return pool

func _nation_recruitable(nation: int) -> int:
    var total: int = 0
    for pid in provinces.keys():
        total += _recruitable_people(int(pid),nation)
    return total

func _disband_inspected() -> void:
    for i in range(divisions.size()-1,-1,-1):
        var unit: Dictionary = divisions[i]
        if int(unit["id"]) != inspected_division_id or int(unit["owner"]) != player:
            continue
        var pid: int = int(unit["province"])
        if provinces.has(pid):
            provinces[pid]["population"] = int(provinces[pid]["population"]) + int(unit["men"])
            provinces[pid]["recruited"] = maxi(0,int(provinces[pid]["recruited"])-int(unit["men"]))
        _log_event("Расформирована дивизия %d; солдаты возвращены, оснащение на склад" % int(unit["id"]))
        divisions.remove_at(i)
        selected_division_ids.erase(inspected_division_id)
        inspected_division_id = -1
        _refresh()
        return

func _refresh_division_panel() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    if division_panel == null:
        _profile_finish("Интерфейс: дивизия", _perf_start_us)
        return
    var chosen: Dictionary = {}
    for d in divisions:
        if int(d["id"]) == inspected_division_id and int(d["owner"]) == player:
            chosen = d
            break
    division_panel.visible = not chosen.is_empty()
    if chosen.is_empty():
        _profile_finish("Интерфейс: дивизия", _perf_start_us)
        return
    division_title.text = str(chosen["name"])
    var units: Array = _division_cells(chosen)
    var template_index: int = int(chosen.get("template_id",-1))
    var template_label: String = "Состав: %d рот" % units.size()
    if template_index >= 0 and template_index < division_templates.size():
        var origin_template: Dictionary = division_templates[template_index]
        template_label = "Шаблон: %s%s" % [str(origin_template["name"])," (УСТАРЕЛ)" if bool(origin_template.get("hidden",false)) else ""]
    if int(chosen.get("refit_target",-1)) >= 0:
        var next_index: int = int(chosen["refit_target"])
        template_label += "\nПереоснащение → %s · %.0f%%" % [str(division_templates[next_index]["name"]),float(chosen.get("refit_progress",0.0))]
    division_details.text = "%s\nОрг. %d%% · Снаряжение %d%%\nHP %.1f · Укрепл. %.1f%%\nЛюди %s/%s · Оснащ. %d%%\nУровень %d/4 · Опыт %.1f\nАтака %d · Защита %d\nСкорость %d км/ч · Броня %d" % [template_label,int(chosen["org"]),int(chosen["equipment"]),float(chosen.get("hp",_division_stat(chosen,"hp"))),float(chosen.get("fortification",0.0)),_short_number(int(chosen["men"])),_short_number(int(chosen.get("max_men",chosen["men"]))),int(chosen["equipment"]),int(chosen.get("level",2)),float(chosen.get("experience",0.0)),_division_stat(chosen,"attack"),_division_stat(chosen,"defense"),_division_stat(chosen,"speed"),_division_stat(chosen,"armor")]
    _profile_finish("Интерфейс: дивизия", _perf_start_us)

func _recruitable_people(pid: int, nation: int) -> int:
    if not provinces.has(pid) or int(provinces[pid]["owner"]) != nation or int(provinces[pid]["controller"]) != nation:
        return 0
    var gov: Dictionary = country_government[nation]
    var limit: int = int(floor(float(provinces[pid]["original_population"]) * LAW_RATES[int(gov["law"])] * float(gov["mobilization_ready"])))
    return maxi(0,mini(int(provinces[pid]["population"]),limit - int(provinces[pid]["recruited"])))

func _advance_politics() -> void:
    var _perf_start_us: int = Time.get_ticks_usec()
    for nation in range(1,6):
        var gov: Dictionary = country_government[nation]
        if int(gov["pending_law"]) >= 0:
            gov["law_days"] = maxi(0,int(gov["law_days"])-1)
            if int(gov["law_days"]) == 0:
                gov["law"] = int(gov["pending_law"])
                gov["pending_law"] = -1
                gov["mobilization_ready"] = 0.10
        elif float(gov["mobilization_ready"]) < 1.0:
            gov["mobilization_ready"] = minf(1.0,float(gov["mobilization_ready"])+0.035)
        var fighting: bool = false
        for other in range(1,6):
            if other != nation and _at_war(nation,other):
                fighting = true
                break
        if fighting:
            gov["war_days"] = int(gov["war_days"]) + 1
        if day == 1:
            var points: Array = gov["parties"]
            var direction: int = 1 if fighting else -1
            var security_gain: int = direction + (1 if int(gov["law"]) >= 3 else 0)
            var take_from: int = 0 if security_gain > 0 else 3
            var give_to: int = 3 if security_gain > 0 else 0
            if int(points[take_from]) > 10 and int(points[give_to]) < 65:
                points[take_from] = int(points[take_from]) - abs(security_gain)
                points[give_to] = int(points[give_to]) + abs(security_gain)
            gov["parties"] = points
    _profile_finish("Сутки: политика", _perf_start_us)
