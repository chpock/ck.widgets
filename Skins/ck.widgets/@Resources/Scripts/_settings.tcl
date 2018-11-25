# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

#set debug true

proc storeVariable { option value } {

    rm log -debug "storeVariable: $option = $value"

    rm setVariable $option $value

    if { ![info exists ::settingsFile] } {
        rm log -error "can't store the option, settings file is not defined"
        return
    }

    rm writeKeyValue -key $option -value $value -file $::settingsFile

}

proc storeVariableToggle { option } {

    rm log -debug "storeVariableToggle: $option"

    tailcall storeVariable $option [expr { ![rm getVariable $option -default 0] }]

}

set settingsFile [rm getOption "SettingsFile" -default "UNKNOWN"]

if { $settingsFile eq "UNKNOWN" } {
    rm log -error "option 'SettingsFile' is not defined"
    unset settingsFile
    return
}

set settingsFile [file join [rm getPathResources] Settings "${settingsFile}.inc"]

rm log -debug "Using settings file: $settingsFile"

if { ![file exists $settingsFile] } {

    if { [catch [list open $settingsFile w] fd] } {
        rm log -error "could not create an empty settings file: $fd"
        unset settingsFile
        return
    }

    close $fd
    rm log -debug "Created an empty settings file"

} {
    rm log -debug "Settings file exists"
}

proc settingsUI {} {

    if { ![info exists ::settingsFile] } {
        set msg "settingsUI: settingsFile is not defined"
        rm log -error $msg
        return -code error $msg
    }

    ::thread::send [rm getThreadGUI] [string map [list \
        %settingsUI% $::settingsUI \
        %settingsFile% [list $::settingsFile] \
    ] {

        if { [winfo exists .settings] } {
            wm deiconify .settings
            focus .settings
            return
        }

        proc storeVariable { option value } {
            rm log -debug "storeVariable: $option = $value"
            rm setVariable $option $value
            rm writeKeyValue -key $option -value $value -file %settingsFile%
        }

        package require gridplus

        %settingsUI%

        wm iconbitmap .settings [file join $::tcl::kitpath extra icons settings.ico]
        after idle { focus .settings }

    }]

}
