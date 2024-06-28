local music = require("musicutil")
local mod = require 'core/mods'
local filepath = "/home/we/dust/data/nb_polyperc/"
local voices = 1

local function format_percent(val)
    return(val.."%")
end

local function read_prefs()
    local prefs = {}
    if util.file_exists(filepath.."prefs.data") then
        prefs = tab.load(filepath.."prefs.data")
        print('table >> read: ' .. filepath.."prefs.data")
        voices = prefs.voices
    else
        voices = 1 --default # of voices
    end
end

local function write_prefs()
    local prefs = {}
    if util.file_exists(filepath) == false then
        util.make_dir(filepath)
    end
    prefs.voices = voices
    tab.save(prefs, filepath .. "prefs.data")
    print("table >> write: " .. filepath.."prefs.data")
end

local function n(i, s)
    return "polyperc_" .. s .. "_" .. i
end

local function add_polyperc_params(i)
    params:add_group(n("group", i), "polyperc " .. i, 9)
    params:add_control(n(i, "decay"), "decay", controlspec.new(0.1, 3.2, 'lin', .01, 1.19, "s"))
    params:add_control(n(i, "cutoff"), "cutoff", controlspec.new(1, 20000, 'exp', 1, 841, "hz"))
    params:add_number(n(i, "tracking"), "tracking", 0, 100, 50, function(param) return format_percent(param:get()) end)
    params:add_number(n(i, "pw"), "pulse width", 1, 99, 50, function(param) return format_percent(param:get()) end) 
    params:add_number(n(i, "amp"), "amp", 0, 100, 50, function(param) return format_percent(param:get()) end)
    params:add_control(n(i, "gain"), "gain", controlspec.new(0, 4, "lin", 0.1, 1))
    params:add_control(n(i, "pan"), "pan", controlspec.new(-1, 1, "lin", 0.1, 0))
    params:add_control(n(i, "send_a"), "send a", controlspec.new(0, 1, "lin", 0, 0))
    params:add_control(n(i, "send_b"), "send b", controlspec.new(0, 1, "lin", 0, 0))
    params:hide(n("group", i))
end

function add_polyperc_player(i)
    local player = {
    }

    function player:active()
        if self.name ~= nil then
            params:show(n("group", i))
            _menu.rebuild_params()
        end
    end

    function player:inactive()
        if self.name ~= nil then
            params:hide(n("group", i))
            _menu.rebuild_params()
        end
    end

    function player:stop_all()
    end

    function player:modulate(val)
    end

    function player:set_slew(s)
    end

    function player:describe()
        return {
            name = "polyperc " .. i,
            supports_bend = false,
            supports_slew = false
        }
    end

    function player:pitch_bend(note, amount)
    end

    function player:modulate_note(note, key, value)
    end

    function player:note_on(note, vel, properties)
        local hz = math.min(music.note_num_to_freq(note), 24000) --limit so SC doesn't crash
        osc.send({ "localhost", 57120 }, "/polyperc/perc", {
            hz, --pitch
            params:get(n(i, "decay")), --decay
            params:get(n(i, "pw")) * .01, --pw
            (params:get(n(i, "amp")) * .01) * vel * vel, --mul with a nice little exp curve
            hz * (params:get(n(i, "tracking"))*.01) + params:get(n(i, "cutoff")), -- cutoff
            params:get(n(i, "gain")), -- gain (filter Q?)
            params:get(n(i, "pan")), -- pan
            params:get(n(i, "send_a")),
            params:get(n(i, "send_b")),
        })
    end

    function player:note_off(note)
        -- pass, for perc.
    end

    function player:add_params()
        add_polyperc_params(i)
    end

    if note_players == nil then
        note_players = {}
    end
    note_players["polyperc " .. i] = player
end

function pre_init()
    read_prefs()
    for v = 1, voices do
    add_polyperc_player(v)
    end
end

mod.hook.register("script_pre_init", "polyperc pre init", pre_init)


-- system mod menu for setting # of voices
local m = {}

function m.key(n, z)
    if n == 2 and z == 1 then
        mod.menu.exit()
    end
end

function m.enc(n, d)
    if n == 3
        then voices = util.clamp(voices + d, 1, 6)
    end
    mod.menu.redraw()
end

function m.redraw()
    screen.clear()
    screen.level(4)
    screen.move(0, 10)
    screen.text("MODS / NB_POLYPERC")
    screen.level(15)
    screen.move(0, 30)
    screen.text("voices")
    screen.move(127, 30)
    screen.text_right(voices)
    screen.update()
end

function m.init() 
    read_prefs()
end -- on menu entry

function m.deinit()
    write_prefs()
end -- on menu exit

mod.menu.register(mod.this_name, m)