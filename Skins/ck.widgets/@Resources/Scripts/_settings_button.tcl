# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Settings

set settingsUI {

    gridplus window .settings -wtitle "Settings: [file tail [rm getSkinName]]"

    gridplus radiobutton .settings.size -title "Button Size:" {
        {. "16px"  -16} {. "32px"  -32 } {. "48px"  -48}
        {. "64px"  -64} {. "128px" -128}
    }

    gridplus button .settings.action {
        {.ok    OK    :tick}
        {.close Close :cross}
        {.apply Apply :cog_go}
    }

    gridplus layout .settings.layout {
        .settings.size:n .settings.action:nw
    }

    gpset [list \
        .settings.size [rm getVariable BackgroundHeight]
    ]

    proc settings:action,ok {} {
        settings:action,apply
        settings:action,close
    }

    proc settings:action,apply {} {

        if { [rm getVariable BackgroundHeight] eq $::(.settings.size) } {
            # button size is not changed
            return
        }

        storeVariable BackgroundHeight $::(.settings.size)
        storeVariable BackgroundWidth $::(.settings.size)

        rm setMeterState Button update
        rm setMeterState SkinBackground update -group
        rm setSkinState update

    }

    proc settings:action,close {} {
        destroy .settings
    }

    pack .settings.layout -padx 5 -pady 5

}

