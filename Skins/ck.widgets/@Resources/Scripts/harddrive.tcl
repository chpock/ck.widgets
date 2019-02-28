# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug 0

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

    if { [rm getVariable "initBackground" -default 0] in {"" 0} } {
        rm log -debug "Background is not initialized"
        updateBackground
        rm setVariable "initBackground" 1
    }

    set showDrives [rm getVariable "showDrives" -default 0]
    set isShowReadWrite     [rm getVariable "showReadWrite" -default 0]
    set isShowGraphActivity [rm getVariable "showGraphActivity" -default 0]

    rm log -debug "Number of shown drives: $showDrives"

    for { set i 1 } { $i <= 15 } { incr i } {

        rm measure [expr { $i <= $showDrives ? "enable":"disable" }] [list \
            "MeasureReadBytesDisk$i"  \
            "MeasureWriteBytesDisk$i" \
            "MeasureFreeDisk$i"       \
            "MeasureTotalDisk$i"      \
            "MeasureUsedDisk$i"       \
            "MeasureTotalDiskGB$i"    \
            "MeasureFreeDiskGB$i"     \
        ]

        rm meter [expr { $i <= $showDrives ? "show":"hide" }] [list \
            "TitleDisk$i"   \
            "FreeDisk$i"    \
            "TotalDisk$i"   \
            "PercentDisk$i" \
            "BarDisk$i"     \
        ]

        rm meter [expr { ($i <= $showDrives) && $isShowReadWrite ? "show":"hide" }] [list \
            "ReadLabelDisk$i"  \
            "ReadDisk$i"       \
            "WriteLabelDisk$i" \
            "WriteDisk$i"      \
        ]


    }

    rm measureGroup [expr { $isShowGraphActivity ? {enable} : {disable} }] GraphActivity
    rm meterGroup   update GraphActivity
    rm meterGroup   [expr { $isShowGraphActivity ? {enable} : {disable} }] GraphActivity

}

proc updateBackground { } {

    rm log -debug "Update background..."

    foreach var {
        TopPadding
        PadY
        BarPadY
        BarHeight
        GraphHeight
        GraphTopPadding
    } {
        set $var [rm getVariable $var -format integer -default 0]
        if { [set $var] eq "" || [set $var] eq "0" } {
            rm log -warn "Variable '$var' is not defined"
        }
        rm log -trace "$var = '[set $var]'"
    }

    foreach var {
        showReadWrite
        showGraphActivity
        showDrives
    } {
        set $var [rm getVariable $var -format integer -default 1]
        if { [set $var] eq "" } {
            rm log -warn "Variable '$var' has empty value"
            set $var 1
        }
    }

    set BackgroundHeight {
        $TopPadding +
        $showDrives * (
            $PadY +
            21 +
            $BarPadY +
            $BarHeight +
            (14+$PadY) * $showReadWrite
        ) +
        $showGraphActivity * (
            $GraphHeight +
            $GraphTopPadding
        ) +
        $PadY +
        $TopPadding
    }

    rm log -trace "Background height: [subst -nobackslashes -nocommands $BackgroundHeight]"

    set BackgroundHeight [expr $BackgroundHeight]

    rm log -debug "Result background height: $BackgroundHeight"

    rm setVariable "BackgroundHeight" $BackgroundHeight
    rm meterGroup update "SkinBackground"

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

set settingsUI {

    set procSaveSettings [list apply {{ } {

        rm log -debug "Apply settings..."

        set update 0

        foreach { tclVar rmVar } [list \
            ::gShowReadWrite     showReadWrite \
            ::gShowGraphActivity showGraphActivity \
        ] {

            if { [set $tclVar] ne [rm getVariable $rmVar] } {
                storeVariable $rmVar [set $tclVar]
                set update 1
            }

        }

        if { $update } {
            rm log -debug "Request update..."
            rm setVariable "initBackground" 0
            rm measure update [rm getMeasureName]
        } else {
            rm log -debug "No update required"
        }

    }}]

    set procLoadSettings [list apply {{ } {

        set ::gShowReadWrite     [rm getVariable "showReadWrite" -default 0]
        set ::gShowGraphActivity [rm getVariable "showGraphActivity" -default 0]
        set ::gDrives            [list]

        set msCheckDisk "MeasureCheckDisk"

        set showDrives [rm getVariable "showDrives" -default 0]
        set maxDrives  [rm getVariable "MaxDrives" -default 0]

        rm log -debug "Number of shown drives: $showDrives"

        array set driveTypes [list \
            0 "Error"     \
            1 "Removed"   \
            2 "Unknown"   \
            3 "Removable" \
            4 "Fixed"     \
            5 "Network"   \
            6 "CDRom"     \
            7 "Ram"       \
        ]

        array set shownDrives [list]

        rm log -debug "shownDrives: $showDrives"
        for { set i 1 } { $i <= $showDrives } { incr i } {
            rm log -debug "$i - [rm getVariable "driveLetter$i"]"
            set shownDrives([rm getVariable "driveLetter$i"]) 1
        }

        set drivesList "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        foreach driveLetter [split $drivesList {}] {

            append driveLetter ":"

            rm measure set $msCheckDisk "Drive" $driveLetter
            rm measure update $msCheckDisk
            set driveType [rm measure get $msCheckDisk]

            if { ![info exists driveTypes($driveType)] } {
                rm log -error "Drive '$driveLetter' has not detected type: '$driveType'"
                continue
            } elseif { $driveType in {2 1} } {
                rm log -debug "Drive '$driveLetter' has type '$driveTypes($driveType)' - skip"
                continue
            }

            set shown [info exists shownDrives($driveLetter)]

            rm log -debug "Drive '$driveLetter' has type '$driveTypes($driveType)'; shown: $shown"

            set "::gDriveText$driveLetter" "$driveLetter ($driveTypes($driveType))"
            set "::gDriveShown$driveLetter" $shown
            lappend ::gDrives $driveLetter

        }

    }}]

    {*}$procLoadSettings

    tkm::packer -path .settings -newwindow -title "Settings: [file tail [rm getSkinName]]" {

        tkm::labelframe -text "Show drive(s)" -image [tkm::icon drive] \
            -pady {10 5} -padx 10 -fill x \
            -- {

            tkm::defaults -padx 8 -pady 2 -anchor w

            foreach drive [lsort $::gDrives] {

                tkm::checkbutton -text [set "::gDriveText$drive"] \
                    -variable "::gDriveShown$drive"

            }

        }

        tkm::labelframe -text "Visible Elements:" -image [tkm::icon eye] \
            -pady 0 -padx 10 -fill x \
            -- {

            set varShowReadWrite     [tkm::var]
            set varShowGraphActivity [tkm::var]

            tkm::defaults -padx 8 -pady 2 -anchor w

            tkm::checkbutton -text "Show read/write activity" \
                -variable $varShowReadWrite \
                -pady {5 2}

            tkm::checkbutton -text "Show read/write activity graph" \
                -variable $varShowGraphActivity \
                -pady {2 8}

        }

        tkm::separator -orient horizontal \
            -fill x -pady {10 0} -padx 15

        tkm::frame -padx 10 -pady 10 -- {

            tkm::defaults -padx 5 -pady 3 -side left

            set wActionOk    [tkm::button -text "OK"    -image [tkm::icon tick]]
            set wActionClose [tkm::button -text "Close" -image [tkm::icon cross]]
            set wActionApply [tkm::button -text "Apply" -image [tkm::icon cog_go]]

        }

        set procAction [list apply {{
            procSaveSettings
            varShowReadWrite varShowGraphActivity
            window action
        } {

            if { $action in {ok apply} } {

                set ::gShowReadWrite     [set $varShowReadWrite]
                set ::gShowGraphActivity [set $varShowGraphActivity]

                if { $procSaveSettings ne "" } {
                    {*}$procSaveSettings
                }

            }

            if { $action in {ok close} } {
                destroy $window
            }

        }} \
            $procSaveSettings \
            $varShowReadWrite $varShowGraphActivity \
            [tkm::parent] \
        ]

        $wActionOk    configure -command [concat $procAction ok]
        $wActionClose configure -command [concat $procAction close]
        $wActionApply configure -command [concat $procAction apply]

    }

    set $varShowReadWrite     $::gShowReadWrite
    set $varShowGraphActivity $::gShowGraphActivity

    wm resizable .settings 0 0

    tkm::centerWindow .settings

}