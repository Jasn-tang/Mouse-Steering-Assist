local cfg = ac.INIConfig.scriptSettings():mapSection('SETTINGS', {
    SMOOTHNESS = 0.25,
    DOFFB = false,
    FFBSENS = 0.25,
    SCROLL = 0.1,
    THROTTLE = 'W',
    BRAKE = 'S',
    ALTTHROTTLE = '',
    ALTBRAKE = '',
    FORCEDAMOUNT = 1,
    ONPRESS = 0.33
})

if not ac.isControllerBrakePressed() then function ac.isControllerBrakePressed() end end --To tell AC shut up bc this function doesn't exist in CSP 0.2.11 or below version.

local isFirstGas, isFirstBrake = true, true
local gasFinal, brakeFinal = 0, 0
local steerFinal = 0
local wheel, lastFrameScrolled = 0, 0


function script.update(dt, deltaX)
    wheel = 0
    if ac.getUI().mouseWheel ~= 0 and lastFrameScrolled + 1 < ac.getSim().frame then lastFrameScrolled, wheel = ac.getSim().frame, ac.getUI().mouseWheel end

    --Mouse Steering--
    steerFinal = math.clamp(steerFinal + deltaX, -1, 1)
    if cfg.DOFFB then steerFinal = math.clamp(steerFinal - ac.getJoypadState().ffb * cfg.FFBSENS / 100, -1, 1) end

    --Throttle Part--
    if ac.isControllerGasPressed() or ac.isKeyDown(ac.KeyIndex[cfg.THROTTLE]) or ac.isKeyDown(ac.KeyIndex[cfg.ALTTHROTTLE]) then
        if isFirstGas then gasFinal, isFirstGas = cfg.ONPRESS, false end
        if ac.isKeyDown(ac.KeyIndex.Shift) and cfg.FORCEDAMOUNT ~= 0 then gasFinal = cfg.FORCEDAMOUNT end
        gasFinal = math.clamp(gasFinal + wheel * cfg.SCROLL, 0, 1)
    else gasFinal, isFirstGas = 0, true end

    --Brake Part--
    if ac.isControllerBrakePressed() or ac.isKeyDown(ac.KeyIndex[cfg.BRAKE]) or ac.isKeyDown(ac.KeyIndex[cfg.ALTBRAKE]) then
        if isFirstBrake then brakeFinal, isFirstBrake = cfg.ONPRESS, false end
        if ac.isKeyDown(ac.KeyIndex.Shift) and cfg.FORCEDAMOUNT ~= 0 then brakeFinal = cfg.FORCEDAMOUNT end
        brakeFinal = math.clamp(brakeFinal + wheel * cfg.SCROLL, 0, 1)
    else brakeFinal, isFirstBrake = 0, true end

    --Output Part-
    ac.getJoypadState().steer = steerFinal
    ac.getJoypadState().gas = math.lerp(ac.getCar(0).gas, gasFinal, cfg.SMOOTHNESS)
    ac.getJoypadState().brake = math.lerp(ac.getCar(0).brake, brakeFinal, cfg.SMOOTHNESS)
end
