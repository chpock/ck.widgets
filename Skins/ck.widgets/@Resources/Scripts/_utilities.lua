--[[

 ck.widgets
 Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

--]]

function Log(message, type)

    if type == nil then
        type = 'Debug'
    end

    if debug == true then
        SKIN:Bang("!Log", message, type)
    elseif type ~= 'Debug' then
        SKIN:Bang("!Log", message, type)
    end

end

function SmartFormatBytes(sInputValue)

    local nValue

    if sInputValue == nil then
        nValue = 0
    else
        nValue = tonumber(sInputValue)
    end

    if nValue < 1024 then
        return "- k"
    elseif nValue < 1024*1024 then
        return math.floor(nValue/1024 + 0.5) .. " k"
    elseif nValue < 1024*1024*1024 then
        return math.floor(nValue*100/1024/1024 + 0.5)/100 .. " M"
    else
        return math.floor(nValue*100/1024/1024/1024 + 0.5)/100 .. " G"
    end

end

function LuaSetVariable(parameter, value, doaction)

    if doaction == nil then
        doaction = 'None'
    end

    SKIN:Bang('!CommandMeasure', 'Settings', "SetVariable('" .. parameter .. "','" .. value .. "','" .. doaction .. "')")

end

function AddContextMenu(title, doaction, index)

    local sRealIndex
    local sShownIndex

    if index == nil then
        sRealIndex = SKIN:GetVariable('_lastContextItem', '')
    else
        sRealIndex = index
    end

    if sRealIndex == '' then
        sShownIndex = '1'
    else
        sShownIndex = sRealIndex
    end

    if index == nil then
        sShownIndex = sShownIndex .. ' (auto)'
    end

    if doaction == nil then
        doaction = ''
    end

    Log('AddContextAction N' .. sShownIndex .. ': "' .. title .. '" = ' .. doaction)

    SKIN:Bang('!SetOption', 'Rainmeter', 'ContextTitle' .. sRealIndex, title)
    SKIN:Bang('!SetOption', 'Rainmeter', 'ContextAction' .. sRealIndex, doaction)

    if index == nil then
        if sRealIndex == '' then
            SKIN:Bang('!SetVariable', '_lastContextItem', '2')
        else
            SKIN:Bang('!SetVariable', '_lastContextItem', tonumber(sRealIndex) + 1)
        end
    end

end

function ResetContextMenu()

    SKIN:Bang('!SetVariable', '_lastContextItem', '')

end

function SetStateGroup(group, state)

    Log('SetStateGroup: ' .. group .. ' = ' .. tostring(state))

    if state == nil then
        SKIN:Bang('!ToggleMeasureGroup', group)
        SKIN:Bang('!ToggleMeterGroup', group)
--        SKIN:Bang('!UpdateMeterGroup', group)
    elseif state then
        SKIN:Bang('!EnableMeasureGroup', group)
        SKIN:Bang('!ShowMeterGroup', group)
        SKIN:Bang('!UpdateMeasureGroup', group)
        SKIN:Bang('!UpdateMeterGroup', group)
    else
        SKIN:Bang('!HideMeterGroup', group)
        SKIN:Bang('!DisableMeasureGroup', group)
    end

end