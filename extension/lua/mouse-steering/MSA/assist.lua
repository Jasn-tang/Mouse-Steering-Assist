--Change script settings here--
-------------------------------
local smoothness = 0.02 -- How smooth will a change be. (number)
local throttle = "W" --Key to press for throttle while scrolling mouse wheel. (alphabet)
local brake = "S" --Key to press for brake while scrolling mouse wheel. (alphabet)
local scroll = 0.02 --What percent will each scroll change. (number)
local ffb = false --Do force feedback or not. (true/false)
local ffbSens = 0.0003 -- How much will the "force" be. (number)
-------------------------------

local gasFinal = 0
local brakeFinal = 0
local steeringFinal = 0

function script.update(dt, deltaX)
    --Mouse Steering--
    steeringFinal = math.clamp(steeringFinal + deltaX, -1, 1)
    if ffb then
        steeringFinal = steeringFinal - ac.getCar().ffbPure * ffbSens
    end
    
    --Throttle Part--
    if ac.isKeyDown(ac.KeyIndex[throttle]) and ac.isKeyDown(ac.KeyIndex.Shift) then
        gasFinal = 1
    elseif ac.isKeyPressed(ac.KeyIndex[throttle]) then gasFinal = 1 / 3
    elseif ac.isKeyDown(ac.KeyIndex[throttle]) then
        gasFinal = math.clamp(gasFinal + ac.getUI().mouseWheel * scroll, 0, 1)
    else gasFinal = math.max(ac.getCar().gas - dt / smoothness, 0)
    end

    --Brake Part--
    if ac.isKeyDown(ac.KeyIndex[brake]) and ac.isKeyDown(ac.KeyIndex.Shift) then
        brakeFinal = 1
    elseif ac.isKeyPressed(ac.KeyIndex[brake]) then brakeFinal = 1 / 3
    elseif ac.isKeyDown(ac.KeyIndex[brake]) then
        brakeFinal = math.clamp(brakeFinal + ac.getUI().mouseWheel * scroll, 0, 1)
    else brakeFinal = math.max(ac.getCar().brake - dt / smoothness, 0)
    end

    --Output Part-
    ac.getJoypadState().steer = steeringFinal
    if ac.getCar().gas < gasFinal then
        ac.getJoypadState().gas = math.min(ac.getCar().gas + dt / smoothness, gasFinal)
    else ac.getJoypadState().gas = gasFinal end
    if ac.getCar().brake < brakeFinal then
        ac.getJoypadState().brake = math.min(ac.getCar().brake + dt / smoothness, brakeFinal)
    else ac.getJoypadState().brake = brakeFinal end
    ac.debug("gas", ac.getJoypadState().gas)
    ac.debug("brake", ac.getJoypadState().brake)
    ac.debug("steer", steeringFinal)
end
