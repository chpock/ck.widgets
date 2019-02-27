# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug true

proc Initialize { } {

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

proc updateBackground { } {

    rm log -debug "Update background..."

    foreach var {
        TopPadding
        PadY
        TextRowHeight
        GraphPadY
        GraphHeight
    } {
        set $var [rm getVariable $var -format integer -default 0]
        if { [set $var] eq "" || [set $var] eq "0" } {
            rm log -warn "Variable '$var' is not defined"
        }
        rm log -trace "$var = '[set $var]'"
    }

    foreach var {
        showTotal
        showGraph
        showWifi
        showIface
    } {
        set $var [rm getVariable $var -format integer -default 1]
        if { [set $var] eq "" } {
            rm log -warn "Variable '$var' has empty value"
            set $var 1
        }
    }

    set BackgroundHeight {
        2 +
        $TopPadding +
        ($TextRowHeight + $PadY) * $showIface +
        ($TextRowHeight + $PadY) * $showWifi  +
        $TextRowHeight + $PadY +
        (
            $GraphPadY +
            $GraphHeight +
            $GraphPadY
        ) * $showGraph +
        ($TextRowHeight + $PadY) * $showTotal +
        $TopPadding
    }

    rm log -trace "Background height: [subst -nobackslashes -nocommands $BackgroundHeight]"

    set BackgroundHeight [expr $BackgroundHeight]

    rm log -debug "Result background height: $BackgroundHeight"

    rm setVariable "BackgroundHeight" $BackgroundHeight
    rm meterGroup update "SkinBackground"

}

proc Update { } {

    if { [rm getVariable "initBackground" -default 0] in {"" 0} } {
        rm log -debug "Background is not initialized"
        updateBackground
        rm setVariable "initBackground" 1
    }

    rm log -debug "Update the '[file tail [rm getSkinName]]' skin ..."

    foreach var {
        showTotal
        showGraph
        showWifi
        showIface
    } {
        set $var [rm getVariable $var -format integer -default 1]
        if { [set $var] eq "" } {
            rm log -warn "Variable '$var' has empty value"
            set $var 1
        }
    }

    if { !$showGraph } {
        rm meterGroup hide GraphInRate
        rm meterGroup hide GraphOutRate
    } else {
        rm meterGroup show GraphInRate
        rm meterGroup show GraphOutRate
    }

    rm meter update AdapterName
    rm meter update WiFiSSID
    rm meter update WiFiQuality
    rm meterGroup update GraphInRate
    rm meterGroup update GraphOutRate
    rm meterGroup update Total
    rm skin update

}

proc updateVar { var val } {

    switch -exact -- $var {

        textNetInBytes -
        textNetOutBytes {
            set val [smartFormatBytes $val]
        }

        textNetInSessionTotal -
        textNetOutSessionTotal {
            set val [fixedFormatBytes $val -precision 4 -factor 1k]
        }

    }

    rm setVariable $var $val

}

# Settings

set settingsUI {

    tkm::packer -path .settings -newwindow -title "Settings: [file tail [rm getSkinName]]" {

        tkm::labelframe -text "Visible Elements:" -image [tkm::icon eye] \
            -pady 13 -padx 10 -fill x -- {

            tkm::defaults -padx 8 -pady 2

            set varVisibleInterface [tkm::var]
            set varVisibleWifiInfo  [tkm::var]
            set varVisibleGraph     [tkm::var]
            set varVisibleTotal     [tkm::var]

            tkm::checkbutton -text "Network interface" -variable $varVisibleInterface \
                -anchor w -pady {5 2}
            tkm::checkbutton -text "WiFi information" -variable $varVisibleWifiInfo \
                -anchor w
            tkm::checkbutton -text "Traffic graphics" -variable $varVisibleGraph \
                -anchor w
            tkm::checkbutton -text "Total traffic statistics" -variable $varVisibleTotal \
                -anchor w -pady {2 8}

        }

        tkm::separator -orient horizontal -fill x -padx 15

        tkm::frame -side bottom -padx 10 -pady 10 -anchor e -- {

            tkm::defaults -padx 5 -pady 3 -side left

            set wActionOk    [tkm::button -text "OK"    -image [tkm::icon tick]]
            set wActionClose [tkm::button -text "Close" -image [tkm::icon cross]]
            set wActionApply [tkm::button -text "Apply" -image [tkm::icon cog_go]]

        }

        wm resizable [tkm::parent] 0 0

        tkm::centerWindow [tkm::parent]

        set procAction [list apply {{
            varVisibleInterface
            varVisibleWifiInfo
            varVisibleGraph
            varVisibleTotal
            window action
        } {

            if { $action in {ok apply} } {

                set update 0

                foreach { tclVar rmVar } [list \
                    $varVisibleInterface showIface \
                    $varVisibleWifiInfo  showWifi \
                    $varVisibleGraph     showGraph \
                    $varVisibleTotal     showTotal \
                ] {

                    if { [set $tclVar] ne [rm getVariable $rmVar] } {
                        storeVariable $rmVar [set $tclVar]
                        set update 1
                    }

                }

                if { $update } {
                    rm setVariable "updateForce" 1
                    rm setVariable "initBackground" 0
                    rm measure update [rm getMeasureName]
                }

            }

            if { $action in {ok close} } {
                destroy $window
            }

        }} $varVisibleInterface $varVisibleWifiInfo \
           $varVisibleGraph $varVisibleTotal \
           [tkm::parent] \
        ]

        $wActionOk    configure -command [concat $procAction ok]
        $wActionClose configure -command [concat $procAction close]
        $wActionApply configure -command [concat $procAction apply]

    }

    set $varVisibleInterface [rm getVariable showIface]
    set $varVisibleWifiInfo  [rm getVariable showWifi]
    set $varVisibleGraph     [rm getVariable showGraph]
    set $varVisibleTotal     [rm getVariable showTotal]

}