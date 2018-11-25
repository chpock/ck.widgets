# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

proc Initialize {} {

    rm log -debug "Initializing the '[file tail [rm getSkinName]]' skin ..."

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings_button.tcl]]

}

proc Update {} {

    rm log -debug "Update the '[file tail [rm getSkinName]]' skin ..."

}
