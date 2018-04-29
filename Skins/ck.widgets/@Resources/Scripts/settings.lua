--[[

 ck.widgets
 Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

--]]

debug = true

function Initialize()

    dofile(SKIN:GetVariable('@') .. 'Scripts/_utilities.lua')

    sSettingsFile = SELF:GetOption('SettingsFile', 'UNKNOWN')

    if sSettingsFile == 'UNKNOWN' then
         Log('SettingsFile options is not defined', 'Error')
         return false
    end

    sSettingsFile = SKIN:GetVariable('@') .. 'Settings\\' .. sSettingsFile .. '.inc'

    Log('Using settings file: ' .. sSettingsFile);

    local fd = io.open(sSettingsFile, "r")
    if fd == nil then
        fd = io.open(sSettingsFile, "w")
        Log('Created empty settings file: ' .. sSettingsFile, 'Notice')
    else
        Log('Settings file exists: ' .. sSettingsFile)
    end
    fd:close()

end

function Update() end

function SetVariable(parameter, value, doaction)

    if doaction == nil then
        doaction = 'none'
    else
        doaction = doaction:lower()
    end

    Log(':Settings:SetVariable: ' .. parameter .. ' = ' .. value .. '; do action: ' .. doaction)

    SKIN:Bang('!SetVariable', parameter, value)

    if sSettingsFile == 'UNKNOWN' then
         Log('SettingsFile options is not defined', 'Warning')
    else
         SKIN:Bang('!WriteKeyValue', 'Variables', parameter, value, sSettingsFile)
    end

    if doaction == 'refresh' then
        SKIN:Bang('!Refresh')
    elseif doaction == 'none' then
        -- do nothing
    elseif doaction == 'update' then
        SKIN:Bang('!Update')
    else
        Log('Unknown action: ' .. doaction, 'Warning')
    end

end

function ToggleVariable(parameter, doaction)

    if doaction == nil then
        doaction = 'None'
    end

    local val = tonumber(SKIN:GetVariable(parameter, 0))

    if val == 0 then
        val = 1
    else
        val = 0
    end

    SetVariable(parameter, val, doaction)

end