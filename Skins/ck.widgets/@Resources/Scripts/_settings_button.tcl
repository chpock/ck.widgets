# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Settings

set settingsUI {

    tkm::packer -path .settings -newwindow -title "Settings: [file tail [rm getSkinName]]" {

        set action [list apply {{ window action varSize } {

            if { $action in {ok apply} } {

                # button size changed
                if { [rm getVariable BackgroundHeight] ne [set $varSize] } {

                    storeVariable BackgroundHeight [set $varSize]
                    storeVariable BackgroundWidth  [set $varSize]

                    rm setMeterState Button update
                    rm setMeterState SkinBackground update -group
                    rm setSkinState update

                }

            }

            if { $action in {ok close} } {
               destroy $window
            }

        }} [tkm::parent]]

        tkm::labelframe -text "Button Size:" -image [tkm::icon arrow_out] -padx 10 -pady 13 -side left -anchor n -- {

            tkm::defaults -fill both -padx 5 -pady 3

            set varSize [tkm::var]

            tkm::radiobutton -text "16px" -variable $varSize -value "16" -column 0
            tkm::radiobutton -text "32px" -variable $varSize -value "32" -column +
            tkm::radiobutton -text "48px" -variable $varSize -value "48" -column +

            tkm::radiobutton -text "64px"  -variable $varSize -value "64"  -column 0 -row +
            tkm::radiobutton -text "128px" -variable $varSize -value "128" -column +

        }

        tkm::separator -orient vertical -side left -pady 13 -fill y

        tkm::frame -side right -padx 10 -pady 13 -- {

            tkm::defaults -pady 3

            tkm::button -text "OK"    -image [tkm::icon tick]   \
                -command [concat $action [list ok    $varSize]]
            tkm::button -text "Close" -image [tkm::icon cross]  \
                -command [concat $action [list close $varSize]]
            tkm::button -text "Apply" -image [tkm::icon cog_go] \
                -command [concat $action [list apply $varSize]]

        }

        set $varSize [rm getVariable BackgroundHeight]

        wm resizable [tkm::parent] 0 0

        tkm::centerWindow [tkm::parent]

    }

}
