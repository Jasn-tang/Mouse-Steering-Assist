--Change script settings here--
-------------------------------
local smoothness = 0.25 -- How smooth will a change be. (number)
local doffb = false --Do force feedback or not. (true/false)
local ffbSens = 0.25 -- How much will the "force" be. (number)
local scroll = 0.02 --What percent will each scroll change. (number)
local throttle = "W" --Key to press for throttle while scrolling mouse wheel. (alphabet)
local brake = "S" --Key to press for brake while scrolling mouse wheel. (alphabet)
local doForce = true --Force pedals to be 100% or not when shift key is pressed. (true/false)
-------------------------------

function ac.isControllerBrakePressed() end --To tell AC shut up bc this function doesn't exist in CSP 0.2.11 or below version.

local isFirstGas, isFirstBrake = true, true
local gasFinal, brakeFinal = 0, 0
local steerFinal = 0

function script.update(dt, deltaX)
    --Mouse Steering--
    steerFinal = math.clamp(steerFinal + deltaX, -1, 1)
    if doffb then steerFinal = math.clamp(steerFinal - ac.getJoypadState().ffb * ffbSens / 100, -1, 1) end

    --Throttle Part--
    if ac.isControllerGasPressed() or ac.isKeyDown(ac.KeyIndex[throttle]) then
        if isFirstGas then gasFinal, isFirstGas = 1 / 3, false end
        if ac.isKeyDown(ac.KeyIndex.Shift) and doForce then gasFinal = 1 end
        gasFinal = math.clamp(gasFinal + ac.getUI().mouseWheel * scroll, 0, 1)
    else gasFinal, isFirstGas = 0, true end

    --Brake Part--
    if ac.isControllerBrakePressed() or ac.isKeyDown(ac.KeyIndex[brake]) then
        if isFirstBrake then brakeFinal, isFirstBrake = 1 / 3, false end
        if ac.isKeyDown(ac.KeyIndex.Shift) and doForce then brakeFinal = 1 end
        brakeFinal = math.clamp(brakeFinal + ac.getUI().mouseWheel * scroll, 0, 1)
    else brakeFinal, isFirstBrake = 0, true end

    --Output Part-
    ac.getJoypadState().steer = steerFinal
    ac.getJoypadState().gas = math.lerp(ac.getCar(0).gas, gasFinal, smoothness)
    ac.getJoypadState().brake = math.lerp(ac.getCar(0).brake, brakeFinal, smoothness)
end
