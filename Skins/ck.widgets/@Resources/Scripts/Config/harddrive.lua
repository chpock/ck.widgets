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

    Log('Initializing HardDrive skin...')

end

function Update()

    Log('Update HardDrive skin...')

    ResetContextMenu()

    SKIN:Bang('!SetVariable', 'BackgroundHeight', SKIN:ParseFormula(SKIN:ReplaceVariables(SELF:GetOption('BackgroundHeight', '20'))))
    SKIN:Bang('!UpdateMeterGroup', 'SkinBackground')

    local msCheckDisk = SKIN:GetMeasure('MeasureCheckDisk')

    local iShowDrives = tonumber(SKIN:GetVariable('showDrives', 0))
    local iMaxDrives  = tonumber(SKIN:GetVariable('MaxDrives', 0))
    local bShowReadWrite = SKIN:GetVariable('showReadWrite', '0') == '1'
    local bShowGraphActivity = SKIN:GetVariable('showGraphActivity', '0') == '1'

    Log('Number of shown drives: ' .. iShowDrives);

    local aDriveTypes = {
        [0] = {
            title   = 'Error',
            enabled = false,
            choose  = false
        },
        [1] = {
            title   = 'Removed',
            enabled = false,
            choose  = false
        },
        [2] = {
            title   = 'Unknown',
            enabled = false,
            choose  = false
        },
        [3] = {
            title   = 'Removable',
            enabled = SKIN:GetVariable('showRemovable', '0') == '1',
            choose  = true
        },
        [4] = {
            title   = 'Fixed',
            enabled = true,
            choose  = false
        },
        [5] = {
            title   = 'Network',
            enabled = SKIN:GetVariable('showNetwork', '0') == '1',
            choose  = true
        },
        [6] = {
            title   = 'CDRom',
            enabled = SKIN:GetVariable('showCDRom', '0') == '1',
            choose  = true
        },
        [7] = {
            title   = 'Ram',
            enabled = SKIN:GetVariable('showRam', '0') == '1',
            choose  = true
        }
    }

    local sDriveList = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

    local sContextTitle
    local sContextAction

    for cDriveLetter in sDriveList:gmatch"." do

        local shown   = false
        local enabled = true

        for i = 1, iShowDrives, 1 do
            if SKIN:GetVariable('driveLetter' .. i) == cDriveLetter .. ':' then
                shown = true
                break
            end
        end

        if not shown then

            SKIN:Bang('!SetOption', 'MeasureCheckDisk', 'Drive', cDriveLetter .. ':')
            SKIN:Bang('!UpdateMeasure', 'MeasureCheckDisk')
            local diskType = msCheckDisk:GetValue()

            if aDriveTypes[diskType]["enabled"] then
                Log('Drive ' .. cDriveLetter .. ': is hidden and has enabled type: ' .. diskType)
            else
                Log('Drive ' .. cDriveLetter .. ': is hidden and has disabled type: ' .. diskType)
                enabled = false
            end

        else

            Log('Drive ' .. cDriveLetter .. ': is shown')

        end

        if enabled then

            local sCallCommand

            if shown then
                sContextTitle  = 'Hide'
                sCallCommand   = 'HideDrive'
            else
                sCallCommand   = 'ShowDrive'
                sContextTitle = 'Show'
            end

            sContextTitle = sContextTitle .. ' drive ' .. cDriveLetter .. ':'

            sContextAction = '[!CommandMeasure ' .. SELF:GetName() .. ' "' .. sCallCommand .. '(\'' .. cDriveLetter .. '\')"]'

            AddContextMenu(sContextTitle, sContextAction)

        end

    end

    AddContextMenu('---')

    for k, v in pairs(aDriveTypes) do
        if v["choose"] then

            local sWriteValue

            if v["enabled"] then
                sContextTitle = 'Hide '
                sWriteValue   = '0'
            else
                sContextTitle = 'Show '
                sWriteValue   = '1'
            end

            sContextTitle = sContextTitle .. 'drive type: ' .. v["title"]

            sContextAction = '[!CommandMeasure Settings "SetVariable(' .. "'show" .. v["title"] .. "'," .. sWriteValue .. ')"][!UpdateMeasure ' .. SELF:GetName() .. ']'

            AddContextMenu(sContextTitle, sContextAction)

        end
    end

    AddContextMenu('---')

    if bShowReadWrite then
        sContextAction = '[!CommandMeasure Settings "SetVariable(' .. "'showReadWrite',0" .. ',' .. "'Refresh'" .. ')"]'
        sContextTitle  = 'Hide read/write rate'
    else
        sContextAction = '[!CommandMeasure Settings "SetVariable(' .. "'showReadWrite',1" .. ',' .. "'Refresh'" .. ')"]'
        sContextTitle  = 'Show read/write rate'
    end
    AddContextMenu(sContextTitle, sContextAction)

    if bShowGraphActivity then
        sContextAction = '[!CommandMeasure Settings "SetVariable(' .. "'showGraphActivity',0" .. ')"][!UpdateMeasure ' .. SELF:GetName() .. ']'
        sContextTitle  = 'Hide activity graph'
        SetStateGroup('GraphActivity', true)
    else
        sContextAction = '[!CommandMeasure Settings "SetVariable(' .. "'showGraphActivity',1" .. ')"][!UpdateMeasure ' .. SELF:GetName() .. ']'
        sContextTitle  = 'Show activity graph'
        SetStateGroup('GraphActivity', false)
    end
    AddContextMenu(sContextTitle, sContextAction)

end

function ShowDrive(pDriveLetter)

    Log('Show Drive: ' .. pDriveLetter)

    local iShowDrives = tonumber(SKIN:GetVariable('showDrives', 0))
    local sDriveList = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local iShowDrivesNew = 0

    local sDriveListCurrent = ''

    for i = 1, iShowDrives, 1 do
        sDriveListCurrent = sDriveListCurrent .. string.sub(SKIN:GetVariable('driveLetter' .. i), 1, 1)
    end

    Log('Current list: ' .. sDriveListCurrent)

    for cDriveLetter in sDriveList:gmatch"." do

        local shown = false

        if cDriveLetter == pDriveLetter then
            shown = true
        else
            shown = sDriveListCurrent:find(cDriveLetter) ~= nil
        end

        if shown then
            iShowDrivesNew = iShowDrivesNew + 1
            LuaSetVariable('driveLetter' .. iShowDrivesNew, cDriveLetter .. ':')
        end

    end

    LuaSetVariable('showDrives', iShowDrivesNew, 'Refresh')

end

function HideDrive(pDriveLetter)

    Log('Hide Drive: ' .. pDriveLetter)

    local iShowDrives = tonumber(SKIN:GetVariable('showDrives', 0))
    local iShowDrivesNew = 0

    for i = 1, iShowDrives, 1 do

        local sCurrentDrive = SKIN:GetVariable('driveLetter' .. i)

        if sCurrentDrive ~= pDriveLetter .. ':' then

            iShowDrivesNew = iShowDrivesNew + 1
            LuaSetVariable('driveLetter' .. iShowDrivesNew, sCurrentDrive)

        end

    end

    LuaSetVariable('showDrives', iShowDrivesNew, 'Refresh')

end
