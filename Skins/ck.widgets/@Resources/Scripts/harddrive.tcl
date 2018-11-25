# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug true

proc Initialize {} {

    rm log -debug "Initializing the HardDrive skin ..."

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

}

proc Update {} {

    rm log -debug "Update the HardDrive skin ..."

    rm resetContextMenu

    rm setVariable "BackgroundHeight" [rm getOption "BackgroundHeight" -format integer -replace variables -default 20]
    rm setMeterState "SkinBackground" update -group

    set msCheckDisk "MeasureCheckDisk"

    set showDrives [rm getVariable "showDrives" -default 0]
    set maxDrives  [rm getVariable "MaxDrives" -default 0]
    set isShowReadWrite     [rm getVariable "showReadWrite" -default 0]
    set isShowGraphActivity [rm getVariable "showGraphActivity" -default 0]

    rm log -debug "Number of shown drives: $showDrives"

    set driveTypes [list \
        0 [list title "Error"     enabled false choose false] \
        1 [list title "Removed"   enabled false choose false] \
        2 [list title "Unknown"   enabled false choose false] \
        3 [list title "Removable" enabled [rm getVariable "showRemovable" -default 0] choose true] \
        4 [list title "Fixed"     enabled true choose false] \
        5 [list title "Network"   enabled [rm getVariable "showNetwork" -default 0] choose true] \
        6 [list title "CDRom"     enabled [rm getVariable "showCDRom" -default 0] choose true] \
        7 [list title "Ram"       enabled [rm getVariable "showRam" -default 0] choose true] \
    ]

    set drivesList "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    foreach driveLetter [split $drivesList {}] {

        append driveLetter ":"

        set shown   false
        set enabled true

        for { set i 1 } { $i <= $showDrives } { incr i } {
            if { [rm getVariable "driveLetter$i"] eq $driveLetter } {
                set shown true
                break
            }
        }

        if { !$shown } {

            rm setOption "Drive" $driveLetter -section $msCheckDisk
            rm setMeasureState $msCheckDisk update
            set driveType [rm getMeasureValue $msCheckDisk]

            if { [dict get $driveTypes $driveType enabled] } {
                rm log -debug "Drive $driveLetter is hidden and has the enabled type: $driveType"
            } {
                rm log -debug "Drive $driveLetter is hidden and has the disabled type: $driveType"
                set enabled false
            }

        } {

            rm log -debug "Drive $driveLetter is shown"

        }

        if { $enabled } {

            rm setContextMenu "[expr { $shown ? {Hide} : {Show} }] drive $driveLetter" \
                -action [rm bang CommandMeasure [rm getMeasureName] "[expr { $shown ? {hide} : {show} }]Drive {$driveLetter}"]

        }


    }

    rm setContextMenu "---"

    dict for { driveType v } $driveTypes {

        if { ![dict get $v choose] } continue

        set enabled [dict get $v enabled]

        rm setContextMenu "[expr { $enabled ? {Hide} : {Show} }] drive type: [dict get $v title]" \
            -action [rm bang \
                CommandMeasure Tcl "storeVariable {show[dict get $v title]} {[expr { !$enabled }]}; rm setMeasureState {[rm getMeasureName]} update" \
            ]

    }

    rm setContextMenu "---"

    rm setContextMenu "[expr { $isShowReadWrite ? {Hide} : {Show} }] read/write rate" \
        -action [rm bang \
            CommandMeasure Tcl "storeVariable showReadWrite {[expr { !$isShowReadWrite }]}; rm setSkinState refresh" \
        ]

    rm setContextMenu "[expr { $isShowGraphActivity ? {Hide} : {Show} }] activity graph" \
        -action [rm bang \
            CommandMeasure Tcl "storeVariable showGraphActivity {[expr { !$isShowGraphActivity }]}; rm setMeasureState {[rm getMeasureName]} update" \
        ]

    rm setMeasureState GraphActivity [expr { $isShowGraphActivity ? {enable} : {disable} }] -group
    rm setMeterState GraphActivity [expr { $isShowGraphActivity ? {enable} : {disable} }] -group

}

proc showDrive { driveLetterReq } {

    rm log -debug "Show drive: $driveLetterReq"

    set showDrives [rm getVariable "showDrives" -default 0]
    set showDrivesNew 0
    set drivesList "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    set drivesListCurrent [list]
    for { set i 1 } { $i <= $showDrives } { incr i } {
        lappend drivesListCurrent [rm getVariable "driveLetter$i"]
    }

    rm log -debug "Current list: $drivesListCurrent"

    foreach driveLetter [split $drivesList {}] {

        append driveLetter ":"

        if { $driveLetter eq $driveLetterReq } {
            set shown true
        } {
            set shown [expr { $driveLetter in $drivesListCurrent }]
        }

        if { $shown } {
            storeVariable "driveLetter[incr showDrivesNew]" $driveLetter
        }

    }

    storeVariable showDrives $showDrivesNew
    rm setSkinState refresh

}

proc hideDrive { driveLetterReq } {

    rm log -debug "Hide drive: $driveLetterReq"

    set showDrives [rm getVariable "showDrives" -default 0]
    set showDrivesNew 0

    for { set i 1 } { $i <= $showDrives } { incr i } {

        set driveLetter [rm getVariable "driveLetter$i"]

        if { $driveLetter ne $driveLetterReq } {
            storeVariable "driveLetter[incr showDrivesNew]" $driveLetter
        }

    }

    storeVariable showDrives $showDrivesNew
    rm setSkinState refresh

}