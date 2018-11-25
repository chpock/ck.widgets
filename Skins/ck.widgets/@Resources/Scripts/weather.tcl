# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug true

proc Initialize {} {

    source [file join [rm getPathResources] Scripts _utilities.tcl]

    rm log -debug "Initializing the Weather skin ..."

    package require http
    package require twapi_crypto

    http::register https 443 [list ::twapi::tls_socket]

    set ::gWeatherProvider yahoo

}

proc Update {} {

    rm log -debug "Update the Weather skin ..."

}

