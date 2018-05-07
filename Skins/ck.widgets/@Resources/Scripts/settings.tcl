# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

#set debug true

proc Initialize {} {

    source [file join [rm getPathResources] Scripts _utilities.tcl]

    set settingsFile [rm getOption "SettingsFile" -default "UNKNOWN"]

    if { $settingsFile eq "UNKNOWN" } {
        rm log -error "option 'SettingsFile' is not defined"
        return
    }

    set ::settingsFile [file join [rm getPathResources] Settings "${settingsFile}.inc"]

    rm log -debug "Using settings file: $::settingsFile"

    if { ![file exists $::settingsFile] } {

        if { [catch [list open $::settingsFile w] fd] } {
            rm log -error "could not create an empty settings file: $fd"
            unset ::settingsFile
            return
        }

        close $fd
        rm log -debug "Created an empty settings file"

    } {
        rm log -debug "Settings file exists"
    }

}

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