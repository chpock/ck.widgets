# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug 1

proc Initialize {} {

    rm log -debug "Initializing the '[file tail [rm getSkinName]]' skin ..."

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

    rm setContextMenu "Configure skin" \
        -action [rm bang CommandMeasure [rm getMeasureName] "settingsUI"]

    if { [info exists ::debug] && [string is true -strict $::debug] } {
        rm setContextMenu "Open tkcon" \
            -action [rm bang CommandMeasure [rm getMeasureName] "rm tkcon"]
    }

}

proc Update {} {

    rm log -debug "Update the '[file tail [rm getSkinName]]' skin ..."

    rm resetContextMenu

    rm setVariable "BackgroundHeight" [rm getOption "BackgroundHeight" -format integer -replace variables -default 20]
    rm setMeterState "SkinBackground" update -group

}

proc updateHwinfoState {} {

    rm log -debug "Updating HWiNFO state..."

    set state [rm getMeasureValue MeasureHwinfoDetect]

    set showCoreTemps    [rm getVariable showCoreTemps]
    set showCoreVoltages [rm getVariable showCoreVoltages]
    set showCpuFan       [rm getVariable showCpuFan]

    set showCoreTempsNow    [rm getVariable showCoreTempsNow -default 0]
    set showCoreVoltagesNow [rm getVariable showCoreVoltagesNow -default 0]
    set showCpuFan          [rm getVariable showCpuFan -default 0]

    set cpuCores         [rm getVariable cpuCores]

    if { $state == -9000 } {

        rm log -debug "HWiNFO is not running"

        if { $showCoreTempsNow } {
            rm measureGroup disable GroupCoreTemps
            rm meterGroup   disable GroupCoreTemps
            rm setVariable  showCoreTempsNow 0
            rm log -debug "Turn off core temps"
        }

        if { $showCoreVoltagesNow } {
            rm measureGroup disable GroupCoreVoltages
            rm meterGroup   disable GroupCoreVoltages
            rm setVariable showCoreVoltagesNow 0
            rm log -debug "Turn off core voltages"
        }

        if { $showCoreTemps } {
            rm log -error "Could not show CPU cores temperature. HWiNFO is not running or HWiNFO plugin is not installed."
        }

        if { $showCoreVoltages } {
            rm log -error "Could not show CPU cores voltage. HWiNFO is not running or HWiNFO plugin is not installed."
        }

    } else {

        rm log -debug "HWiNFO is running"

        package require twapi
        [[twapi::wmi_root] ExecQuery "Select * from Win32_Processor"] -iterate obj { break }
        set maxRealCores [$obj NumberOfCores]
        set threadsPerCore [expr { int(ceil(1.0 * $cpuCores / $maxRealCores)) }]

        rm log -debug "Real cores: $maxRealCores"
        rm log -debug "Threads per core: $threadsPerCore"

        if { !$showCoreTempsNow && $showCoreTemps } {

            rm setVariable showCoreTempsNow 1
            rm log -debug "Turn on core temps"

            for { set i 1 } { $i <= $maxRealCores } { incr i } {

                set bangs [list]
                for { set j 1 } { $j <= $threadsPerCore } { incr j } {
                    lappend bangs [list UpdateMeter CPUTempCore[expr { ($i - 1) * $threadsPerCore + $j }]]
                }
                set bangs [rm lbang {*}$bangs]

                rm log -debug "Enable measure MeasureCoreTemp$i with: $bangs"

                rm setOption OnChangeAction $bangs -section MeasureCoreTemp$i
                rm measure enable MeasureCoreTemp$i

            }

            for { set i 1 } { $i <= $cpuCores } { incr i } {

                set realCore [expr { int(ceil(1.0 * $i / $threadsPerCore)) }]

                rm log -debug "Enable meter CPUTempCore$i on MeasureCoreTemp$realCore"

                rm setOption MeasureName MeasureCoreTemp$realCore -section CPUTempCore$i
                rm meter enable CPUTempCore$i

            }

        }

        if { !$showCoreVoltagesNow && $showCoreVoltages } {

            rm setVariable showCoreVoltagesNow 1
            rm log -debug "Turn on core voltages"

            for { set i 1 } { $i <= $maxRealCores } { incr i } {

                set bangs [list]
                for { set j 1 } { $j <= $threadsPerCore } { incr j } {
                    lappend bangs [list UpdateMeter CPUVoltageCore[expr { ($i - 1) * $threadsPerCore + $j }]]
                }
                set bangs [rm lbang {*}$bangs]

                rm log -debug "Enable measure MeasureCoreVoltage$i with: $bangs"

                rm setOption OnChangeAction $bangs -section MeasureCoreVoltage$i
                rm measure enable MeasureCoreVoltage$i

            }

            for { set i 1 } { $i <= $cpuCores } { incr i } {

                set realCore [expr { int(ceil(1.0 * $i / $threadsPerCore)) }]

                rm log -debug "Enable meter CPUVoltageCore$i on MeasureCoreVoltage$realCore"

                rm setOption MeasureName MeasureCoreVoltage$realCore -section CPUVoltageCore$i
                rm meter enable CPUVoltageCore$i

            }

        }


    }

    rm log -debug "HWiNFO state: $state"

}