local music = require("musicutil")
local mod = require 'core/mods'

local function format_percent(val)
    return(val.."%")
end

local function n(i, s)
    return "polyperc_" .. s .. "_" .. i
end

local function add_polyperc_params(i)
    params:add_group(n("group", i), "polyperc voice " .. i, 9)
    params:add_control(n(i, "decay"), "decay", controlspec.new(0.1, 3.2, 'lin', 0, 1.2, "s"))
    params:add_control(n(i, "cutoff"), "cutoff", controlspec.new(50, 5000, 'exp', 0, 800, "hz"))
    params:add_number(n(i, "tracking"), "tracking", 0, 100, 50, function(param) return format_percent(param:get()) end)
    params:add_number(n(i, "pw"), "pulse width", 1, 99, 50, function(param) return format_percent(param:get()) end) 
    params:add_number(n(i, "amp"), "amp", 0, 100, 30, function(param) return format_percent(param:get()) end)
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
        osc.send({ "localhost", 57120 }, "/polyperc", {
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
    for v = 1, 1 do
    add_polyperc_player(v)
    end
end

mod.hook.register("script_pre_init", "polyperc pre init", pre_init)