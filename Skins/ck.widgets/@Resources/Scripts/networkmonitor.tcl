# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug true

proc Initialize {} {

    rm log -debug "Initializing the NetworkMonitor skin ..."

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

}

proc Update {} {

    rm log -debug "Update the NetworkMonitor skin ..."

    rm setVariable "BackgroundHeight" [rm getOption "BackgroundHeight" -format integer -replace variables -default 20]
    rm setMeterState "SkinBackground" update -group

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
