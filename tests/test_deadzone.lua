-- Run from the repository root: luajit tests/test_deadzone.lua
local modified = MODIFIED_PATH or 'extension/lua/mouse-steering/MSA/assist.lua'
local original = ORIGINAL_PATH or 'tests/fixtures/assist-before-deadzone.lua'
local assertions = 0
local function close(actual, expected, label)
    assertions = assertions + 1
    assert(math.abs(actual - expected) < 1e-12,
        label .. ': expected ' .. tostring(expected) .. ', got ' .. tostring(actual))
end

-- CSP calls are replaced only in this test environment, never in the app.
local function loadAssist(path, overrides)
    local state = { steer = 0, gas = 0, brake = 0, clutch = 0.73, ffb = 0 }
    local car = { gas = 0, brake = 0 }
    local sim, uiState, keys = { frame = 0 }, { mouseWheel = 0 }, {}
    local acMock = {
        getPatchVersionCode = function() return (overrides or {}).TEST_PATCH_VERSION or 3465 end,
        isControllerBrakePressed = function() return keys.controllerBrake or false end,
        INIConfig = { scriptSettings = function()
            return { mapSection = function(_, section, defaults)
                assert(section == 'SETTINGS')
                for k, v in pairs(overrides or {}) do defaults[k] = v end
                return defaults
            end }
        end },
        KeyIndex = setmetatable({}, { __index = function(_, k) return k end }),
        getJoypadState = function() return state end,
        getCar = function() return car end,
        getSim = function() return sim end,
        getUI = function() return uiState end,
        isKeyDown = function(k) return keys[k] or false end,
        isControllerGasPressed = function() return keys.controllerGas or false end
    }
    local mathMock = setmetatable({
        clamp = function(x, low, high) return math.max(low, math.min(high, x)) end,
        lerp = function(a, b, t) return a + (b - a) * t end
    }, { __index = math })
    local env = setmetatable({ ac = acMock, math = mathMock, script = {} }, { __index = _G })
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    chunk()
    return {
        state = state, keys = keys,
        step = function(delta, wheel, force, dt)
            sim.frame = sim.frame + 1
            uiState.mouseWheel = wheel or 0
            state.ffb = force or 0
            env.script.update(dt or 0.003, delta)
            car.gas, car.brake = state.gas, state.brake
            return state.steer
        end
    }
end

local function single(input, deadzone)
    return loadAssist(modified, deadzone == nil and {} or { STEERING_DEADZONE = deadzone }).step(input)
end

close(single(0), 0, 'center')
for _, sign in ipairs({ -1, 1 }) do
    close(single(sign * 0.01), 0, 'inside default deadzone')
    close(single(sign * 0.02), 0, 'exact boundary')
    close(single(sign * (0.02 + 1e-8)), sign * 1e-8 / 0.98, 'immediately outside')
    close(single(sign), sign, 'full steering lock')
    close(single(sign * 2), sign, 'axis saturation')
    close(single(sign * 0.5), sign * 0.48 / 0.98, 'linear remapping')
    close(single(sign * 0.1, 0.1), 0, '10 percent boundary')
    close(single(sign * 0.100001, 0.1), sign * 0.000001 / 0.9, '10 percent transition')
end
for _, x in ipairs({ -1, -0.5, -0.02, -0.001, 0, 0.001, 0.02, 0.5, 1 }) do
    close(single(x, 0), x, 'disabled deadzone identity')
end
close(single(0.01, -1), 0.01, 'negative config clamps to zero')
close(single(0.1, 1), 0, 'excess config clamps to 10 percent')

local accumulated = loadAssist(modified)
for i = 1, 3 do close(accumulated.step(0.005), 0, 'small accumulated movement inside') end
local crossed = accumulated.step(0.006)
assert(crossed > 0, 'small movements must eventually cross the deadzone')
close(crossed, 0.001 / 0.98, 'accumulated position crosses boundary')
close(accumulated.step(-0.006), 0, 'return inside')
for i = 1, 100 do close(accumulated.step(0), 0, 'stationary center does not oscillate') end
local offCenter = loadAssist(modified)
offCenter.step(0.5)
close(offCenter.step(0.001), 0.481 / 0.98, 'tiny motion away from center is preserved')

-- Compare complete update sequences with the untouched original, including FFB,
-- scroll gating, first press/release, Shift, alternate keys and controller gas.
for _, version in ipairs({ 3465, 4000 }) do
for _, dz in ipairs({ 0, 0.02, 0.1 }) do
    for _, ffb in ipairs({ false, true }) do
        local cfg = { TEST_PATCH_VERSION = version, STEERING_DEADZONE = dz, DOFFB = ffb, ALTTHROTTLE = 'T', ALTBRAKE = 'B' }
        local before, after = loadAssist(original, cfg), loadAssist(modified, cfg)
        for i = 1, 600 do
            for _, key in ipairs({ 'W', 'S', 'Shift', 'T', 'B', 'controllerGas', 'controllerBrake' }) do
                local pressed = (i + #key * 7) % (11 + #key) < 5
                before.keys[key], after.keys[key] = pressed, pressed
            end
            local delta = math.sin(i * 0.31) * 0.003
            local wheel = i % 7 == 0 and (i % 2 == 0 and 1 or -1) or 0
            local force = math.sin(i * 0.07)
            local input = before.step(delta, wheel, force)
            local actual = after.step(delta, wheel, force)
            local expected = 0
            if math.abs(input) > dz then
                expected = (input < 0 and -1 or 1) * (math.abs(input) - dz) / (1 - dz)
            end
            close(actual, expected, 'full update steering')
            close(after.state.gas, before.state.gas, 'throttle regression')
            close(after.state.brake, before.state.brake, 'brake regression')
            close(after.state.clutch, 0.73, 'clutch stays untouched')
        end
    end
end
end
print('PASS: ' .. assertions .. ' assertions; complete Lua script with simulated CSP API.')
print('NOT VALIDATED: real CSP runtime, Content Manager UI, or driving in Assetto Corsa.')
