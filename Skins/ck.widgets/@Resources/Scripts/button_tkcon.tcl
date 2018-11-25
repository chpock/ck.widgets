# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

proc Initialize {} {

    rm log -debug "Initializing the Button-tkcon skin ..."

}

proc Update {} {

    rm log -debug "Update the Button-tkcon skin ..."

}

proc toggle {} {

    ::thread::send [rm getThreadGUI] {
        package require tkcon

        if {
            [info exists ::tkcon::PRIV(root)] &&
            [winfo exists $::tkcon::PRIV(root)] &&
            [wm state $::tkcon::PRIV(root)] ne "withdrawn"
        } {
            tkcon hide
        } else {
            tkcon show
        }

        proc exit { args } {
            tkcon hide
        }

    }

}

