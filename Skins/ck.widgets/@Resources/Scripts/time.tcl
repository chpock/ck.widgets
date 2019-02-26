# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug 0

proc Initialize {} {

    rm log -debug "Initializing the Time skin ..."

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

    rm setContextMenu "Configure skin" \
        -action [rm bang CommandMeasure [rm getMeasureName] "settingsUI"]

    if { [info exists ::debug] && [string is true -strict $::debug] } {
        rm setContextMenu "Open tkcon" \
            -action [rm bang CommandMeasure [rm getMeasureName] "rm tkcon"]
    }

    if { [catch { package require registry } errmsg] } {
        rm log -error "Could not load the registry package: $::errorInfo"
    }

    # refresh the "ampm" setting
    updateAMPM

}

proc Update {} {

    rm log -debug "Update the Time skin ..."

    set redraw 0

    # check if system TZ settings changed
    if { [catch {

        set currentTZ [rm getVariable currentTZ]
        set realCurrentTZ [registry get \
            "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Control\\TimeZoneInformation" \
            TimeZoneKeyName]

        if { $currentTZ ne "" && $currentTZ ne $realCurrentTZ } {
            rm log "System's timezone was changed. Reseting the default Tcl timezone."
            unset -nocomplain ::tcl::clock::CachedSystemTimeZone
            set currentTZ ""
        }

        if { $currentTZ eq "" } {
            rm setVariable currentTZ $realCurrentTZ
        }

    } result] } {
        rm log -warn "Could not check changes to system's TZ settings: $::errorInfo"
    }

    set timestamp [clock seconds]

    if { [set showAMPM [rm getVariable showAMPM]] eq "" } {

        rm log -debug "showAMPM doesn't exist"

        unset -nocomplain ::gHour ::gMinute ::gAMPM

        set showAMPM [updateAMPM]

        set redraw 1

    }

    if { $showAMPM } {
        lassign [split [clock format $timestamp -format "%I %M %p"] " "] hour minute ampm
    } else {
        lassign [split [clock format $timestamp -format "%H %M"] " "] hour minute
    }

    if { ![info exists ::gHour] || $::gHour ne $hour } {
        set ::gHour $hour
        rm meter set "Hours" "Text" $hour
        set redraw 1
    }

    if { ![info exists ::gMinute] || $::gMinute ne $minute } {
        set ::gMinute $minute
        rm meter set "Minutes" "Text" $minute
        set redraw 1
    }

    if { $showAMPM && (![info exists gAMPM] || $::gAMPM ne $ampm) } {
        set ::gAMPM $ampm
        rm meter set "AMPM" "Text" $ampm
        set redraw 1
    }

    if { $redraw } {
        rm meterGroup update "currentTime"
        rm skin redraw
    }

}

proc updateAMPM { } {

    set timestamp [clock seconds]

    set currentTimeFormat [rm getVariable currentTimeFormat]

    rm log -debug "currentTimeFormat: $currentTimeFormat"

    if { $currentTimeFormat eq "" } {
        if { [clock format $timestamp -format "%X"] eq [clock format $timestamp -format "%T"] } {
            set currentTimeFormat "24"
        } else {
            set currentTimeFormat "12"
        }
    }

    if { $currentTimeFormat eq "12" } {
        set showAMPM 1
    } else {
        set showAMPM 0
    }

    rm setVariable showAMPM $showAMPM

    return $showAMPM

}

proc getToolTipText { } {

    set result [list]

    set getFormattedString [list apply {{ timestamp formatTime timezone formatDate } {

        if { $formatDate eq "" } {
            set formatDate "%x,"
        }

        set format "$formatDate"

        if { $formatTime eq "" } {
            append format " %X"
        } elseif { $formatTime eq "24" } {
            append format " %H:%M:%S"
        } else {
            append format " %I:%M:%S %p"
        }

        if { $timezone eq "" } {
            set code [catch [list clock format $timestamp -format $format] result]
        } else {
            set code [catch [list clock format $timestamp -format $format -timezone $timezone] result]
        }

        if { $code } {
            set result "Error: $result"
        }

        return $result

    }}]

    set currentTimeFormat [rm getVariable currentTimeFormat]
    set currentTimezone   [rm getVariable currentTimezone]
    set tooltipDateFormat [rm getVariable tooltipDateFormat]

    set currentTime [clock seconds]

    lappend result [{*}$getFormattedString $currentTime $currentTimeFormat $currentTimezone $tooltipDateFormat]

    for { set i 0 } { $i < 4 } { incr i } {

        if { ![rm getVariable "tooltip${i}TimeEnabled" -default 0] } {
            continue
        }

        set timezone [rm getVariable "tooltip${i}Timezone"]

        set timezoneTitle [string range $timezone 1 end]
        if { $timezoneTitle eq "" } {
            set timezoneTitle "Auto (local)"
        }

        lappend result "" "Timezone #[expr { $i + 1 }]: $timezoneTitle"

        set timeFormat [rm getVariable "tooltip${i}TimeFormat"]

        lappend result [{*}$getFormattedString $currentTime $timeFormat $timezone $tooltipDateFormat]

    }

    return [join $result \n]

}

# Settings

set settingsUI {

    set procSaveSettings [list apply {{ } {

        set update 0

        set currentTimeFormat $::gDateTimeCurrentTimeFormat
        if { [rm getVariable currentTimeFormat] ne $currentTimeFormat } {
            storeVariable currentTimeFormat $currentTimeFormat
            set update 1
        }

        set currentTimezone $::gDateTimeCurrentTimezone
        if { [rm getVariable currentTimezone] ne $currentTimezone } {
            storeVariable currentTimezone $currentTimezone
            set update 1
        }

        storeVariable tooltipDateFormat $::gDateTimeTooltipDateFormat

        for { set i 0 } { $i < 4 } { incr i } {
            storeVariable "tooltip${i}TimeFormat"  [set "::gDateTime${i}TimeFormat"]
            storeVariable "tooltip${i}TimeEnabled" [set "::gDateTime${i}Enabled"]
            storeVariable "tooltip${i}Timezone"    [set "::gDateTime${i}Timezone"]
        }

        if { $update } {
            rm setVariable showAMPM ""
            rm measure update [rm getMeasureName]
        }

    }}]

    set procLoadSettings [list apply {{ } {

        set ::gDateTimeCurrentTimeFormat [rm getVariable currentTimeFormat]
        set ::gDateTimeCurrentTimezone   [rm getVariable currentTimezone]
        set ::gDateTimeTooltipDateFormat [rm getVariable tooltipDateFormat]

        for { set i 0 } { $i < 4 } { incr i } {
            set "::gDateTime${i}TimeFormat" [rm getVariable "tooltip${i}TimeFormat"]
            set "::gDateTime${i}Enabled"    [rm getVariable "tooltip${i}TimeEnabled" -default 0]
            set "::gDateTime${i}Timezone"   [rm getVariable "tooltip${i}Timezone"]
        }

    }}]

    set availableTooltipDateFormat {
        ""
        "%m/%d/%Y"
        "%Y/%m/%d"
        "%Y-%m-%d"
        "%d.%m.%Y"
        "%d %B %Y"
        "%d %b %Y"
        "%A, %d %B %Y"
        "%a, %d %b %Y"
    }

    tkm::packer -path .settings -newwindow -title "Settings: [file tail [rm getSkinName]]" {

        set varMapTimezone [tkm::var]

        tkm::labelframe -text "Current Date/Time" \
            -pady {10 5} -padx 10 -fill x -column 0 -columnspan 2 \
            -- {

            set varCurrentTZ [tkm::var]
            set varCurrentFormat [tkm::var]

            tkm::frame -pady {5 0} -padx 10 -fill x -- {
                tkm::label -padx {0 5} -text "Time Zone:" -side left
                set wComboboxCurrent [tkm::combobox -textvariable $varCurrentTZ \
                    -state readonly \
                    -side left -fill x -expand 1]
            }

            tkm::frame -pady 5 -padx 10 -fill x -- {
                tkm::label -padx {0 5} -text "Time format:" -side left
                tkm::radiobutton -text "Auto" -variable $varCurrentFormat -value "" \
                    -side left
                tkm::radiobutton -text "12h"  -variable $varCurrentFormat -value "12" \
                    -side left
                tkm::radiobutton -text "24h"  -variable $varCurrentFormat -value "24" \
                    -side left
            }

        }

        for { set i 0 } { $i < 4 } { incr i } {

            set "var${i}TZ" [tkm::var]
            set "var${i}Format" [tkm::var]
            set "var${i}Enabled" [tkm::var]

            set "wCheckButton$i" [tkm::checkbutton -variable [set "var${i}Enabled"] -text "Show #[expr { $i + 1 }] Tooltip Date/Time" -nopack]

            tkm::labelframe ".tooltip$i" -labelwidget [set "wCheckButton$i"] \
                -pady 5 -padx 10 -fill x -row + \
                -- {

                tkm::frame -pady {5 0} -padx 10 -fill x -- {
                    tkm::label -padx {0 5} -text "Time Zone:" -side left
                    set wCombobox$i [tkm::combobox -textvariable [set "var${i}TZ"] \
                        -state readonly \
                        -side left -fill x -expand 1]
                }

                tkm::frame -pady 5 -padx 10 -fill x -- {
                    tkm::label -padx {0 5} -text "Time format:" -side left
                    set wRadio1 [tkm::radiobutton -text "Auto" \
                        -variable [set "var${i}Format"] -value "" \
                        -side left]
                    set wRadio2 [tkm::radiobutton -text "12h" \
                        -variable [set "var${i}Format"] -value "12" \
                        -side left]
                    set wRadio3 [tkm::radiobutton -text "24h" \
                        -variable [set "var${i}Format"] -value "24" \
                        -side left]
                }

            }

            set "procTZUpdate$i" [list apply {{ var wCombobox wRadio1 wRadio2 wRadio3 } {

                if { [set $var] } {
                    $wCombobox state "!disabled"
                    $wRadio1   state "!disabled"
                    $wRadio2   state "!disabled"
                    $wRadio3   state "!disabled"
                } else {
                    $wCombobox state "disabled"
                    $wRadio1   state "disabled"
                    $wRadio2   state "disabled"
                    $wRadio3   state "disabled"
                }

            }} [set "var${i}Enabled"] [set wCombobox$i] $wRadio1 $wRadio2 $wRadio3]

            [set "wCheckButton$i"] configure -command [set "procTZUpdate$i"]

        }

        tkm::labelframe -text "Tooltip date format:" \
            -column 1 -row 1 -rowspan 4 -fill y -pady {8 5} -padx {0 10} \
            -- {

            set varTooltipDateFormat [tkm::var]

            foreach val $availableTooltipDateFormat {

                if { $val eq "" } {
                    set format "%x"
                    set formatTitle "Auto - %x"
                } else {
                    set format $val
                    set formatTitle $val
                }

                set title [clock format [clock seconds] -format $format]
                set title "$title \($formatTitle\)"

                tkm::radiobutton -text $title \
                    -variable $varTooltipDateFormat -value $val \
                    -padx 10 -pady {5 0} \
                    -anchor w

            }

        }

        tkm::separator -orient horizontal \
            -fill x -pady {10 0} -padx 15 -row 5 -column 0 -columnspan 2

        tkm::frame -padx 10 -pady 10 -row + -columnspan 2 -- {

            tkm::defaults -padx 5 -pady 3 -side left

            set wActionOk    [tkm::button -text "OK"    -image [tkm::icon tick]]
            set wActionClose [tkm::button -text "Close" -image [tkm::icon cross]]
            set wActionApply [tkm::button -text "Apply" -image [tkm::icon cog_go]]

        }

        set procAction [list apply {{
            procSaveSettings
            varMapTimezone
            varTooltipDateFormat
            varCurrentTZ varCurrentFormat
            var0TZ var0Format var0Enabled
            var1TZ var1Format var1Enabled
            var2TZ var2Format var2Enabled
            var3TZ var3Format var3Enabled
            window action
        } {

            if { $action in {ok apply} } {

                set ::gDateTimeCurrentTimezone [dict get [set $varMapTimezone] [set $varCurrentTZ]]
                set ::gDateTimeCurrentTimeFormat [set $varCurrentFormat]
                set ::gDateTimeTooltipDateFormat [set $varTooltipDateFormat]

                for { set i 0 } { $i < 4 } { incr i } {
                    set "::gDateTime${i}Timezone" \
                        [dict get [set $varMapTimezone] \
                            [set [set "var${i}TZ"]] \
                        ]
                    set "::gDateTime${i}TimeFormat" [set [set "var${i}Format"]]
                    set "::gDateTime${i}Enabled"    [set [set "var${i}Enabled"]]
                }

                if { $procSaveSettings ne "" } {
                    {*}$procSaveSettings
                }

            }

            if { $action in {ok close} } {
                destroy $window
            }

        }} \
            $procSaveSettings \
            $varMapTimezone \
            $varTooltipDateFormat \
            $varCurrentTZ $varCurrentFormat \
            $var0TZ $var0Format $var0Enabled \
            $var1TZ $var1Format $var1Enabled \
            $var2TZ $var2Format $var2Enabled \
            $var3TZ $var3Format $var3Enabled \
            [tkm::parent] \
        ]

        $wActionOk configure    -command [concat $procAction ok]
        $wActionClose configure -command [concat $procAction close]
        $wActionApply configure -command [concat $procAction apply]

    }

    {*}$procLoadSettings

    set $varCurrentFormat $::gDateTimeCurrentTimeFormat
    set $varTooltipDateFormat $::gDateTimeTooltipDateFormat

    for { set i 0 } { $i < 4 } { incr i } {
        set [set "var${i}Format"] [set "::gDateTime${i}TimeFormat"]
        set [set "var${i}Enabled"] [set "::gDateTime${i}Enabled"]
        {*}[set "procTZUpdate$i"]
    }

    if { ![info exists ::g__TimeZonesLoaded__] } {

        # Initialize the clock package if necessary
        if { ![info exists ::tcl::clock::DataDir] } {
            clock format [clock seconds]
        }

        set tzs [glob -directory $::tcl::clock::DataDir -type f -tails *]

        foreach tzDir [glob -directory $::tcl::clock::DataDir -type d -tails *] {

            if { $tzDir eq "SystemV" } {
                continue
            }

            foreach fn [glob -directory [file join $::tcl::clock::DataDir $tzDir] -type f -tails *] {
                lappend tzs [file join $tzDir $fn]
            }

        }

        foreach tzName $tzs {
            catch { ::tcl::clock::SetupTimeZone ":$tzName" }
        }

        set ::g__TimeZonesLoaded__ 1

    }

    set tzs [list]

    foreach tzName [array names ::tcl::clock::TZData] {

        set tzTitle [string range $tzName 1 end]

        if { $tzTitle eq "localtime" } {
            continue
        }

        set offset [clock format [clock seconds] -format "%Z %z" -timezone $tzName]
        set tzTitle "$tzTitle \($offset\)"

        # convert timezone offset to the form that suitable
        # for sorting:
        #   from "+0100" to "10100"
        #   from "-0100" to "-10100"
        set offset [lindex [split $offset " "] end]
        set offset "[string index $offset 0]1[string range $offset 1 end]"
        set offset [string trimleft $offset "+"]

        lappend tzs [list $offset $tzName $tzTitle]

    }

    set tzs [lsort -command [list apply {{ a b } {

        set aOffset [lindex $a 0]
        set bOffset [lindex $b 0]

        if { $aOffset < $bOffset } {
            return -1
        } elseif { $aOffset > $bOffset } {
            return 1
        }

        set aName [lindex $a 1]
        set bName [lindex $b 1]

        return [string compare $aName $bName]

    }}] $tzs]

    set tzComboboxValues [list "Auto (Current)"]
    lappend $varMapTimezone [lindex $tzComboboxValues 0] ""

    foreach tzRec $tzs {
        set tzName  [lindex $tzRec 1]
        set tzTitle [lindex $tzRec 2]
        lappend $varMapTimezone $tzTitle $tzName
        lappend tzComboboxValues $tzTitle
    }

    foreach { widget varGlobal } [list \
        $wComboboxCurrent ::gDateTimeCurrentTimezone \
        $wCombobox0 ::gDateTime0Timezone \
        $wCombobox1 ::gDateTime1Timezone \
        $wCombobox2 ::gDateTime2Timezone \
        $wCombobox3 ::gDateTime3Timezone \
    ] {

        $widget configure -values $tzComboboxValues

        unset -nocomplain tzFound
        foreach { tzTitle tzName } [set $varMapTimezone] {
            if { $tzName eq [set $varGlobal] } {
                set tzFound $tzTitle
            }
        }

        if { ![info exists tzFound] } {
            set tzFound "Auto"
        }

        $widget set $tzFound

    }

    wm resizable .settings 0 0

    tkm::centerWindow .settings

}