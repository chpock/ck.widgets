# ck.widgets
# Copyright (C) 2022 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug 1

proc Initialize {} {

    rm log -debug "Initializing the '[file tail [rm getSkinName]]' skin ..."

    foreach tempVar [list TMPDIR TEMP TMP] {
        if { [info exists ::env($tempVar)] } {
            set tempDirectory [file join $::env($tempVar) rm-spotify-covers]
            if { [catch { file mkdir $tempDirectory } errMsg] } {
                rm log -warning "could not create temp directory '$tempDirectory': $errMsg"
                unset tempDirectory
            }
        }
    }

    if { [info exists tempDirectory] } {
        rm log -debug "Using temp directory: $tempDirectory"
        rm setVariable tempDirectory $tempDirectory
    }

    lappend ::auto_path [file join [rm getPathResources] Scripts spotify-deps]

    package require tclspotify

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

    rm setContextMenu "Configure skin" \
        -action [rm bang CommandMeasure [rm getMeasureName] "settingsUI"]

    if { [info exists ::debug] && [string is true -strict $::debug] } {
        rm setContextMenu "Open tkcon" \
            -action [rm bang CommandMeasure [rm getMeasureName] "rm tkcon"]
    }

    ::spotify::callbackUserAuthState [list apply {{ } {
        rm log -debug "Update Spotify client state ..."
        storeVariable clientState [::spotify::getUserAuthState]
    }}]

}

proc Update {} {

    rm log -debug "Update the '[file tail [rm getSkinName]]' skin ..."

    # update spotify status only every 5 seconds
    if {
        ![info exists ::gLastSuccessfulUpdate] ||
        [expr { [clock seconds] - $::gLastSuccessfulUpdate > 5 }] ||
        [string is true -strict [rm getVariable updateForce]]
    } {

        unset -nocomplain ::gSpotifyStateIsPlaying

        updateSpotifyState

        set track ""
        set artist ""

        set coverURL ""
        set coverFile ""

        if { [info exists ::gSpotifyStateError] } {

            set status "ERROR: $::gSpotifyStateError"

        } elseif { $::gSpotifyState eq "" } {

            rm log -debug "Spotify playback state is empty"

            set status "Pause"

        } else {

            if { [dict exists $::gSpotifyState "device" "id"] } {

                set device [dict get $::gSpotifyState "device" "id"]

                if { $device ne [rm getVariable latestDeviceId] } {
                    storeVariable latestDeviceId $device
                }

            }

            if { [dict exists $::gSpotifyState "is_playing"] } {

                if { [string is true -strict [dict get $::gSpotifyState "is_playing"]] } {
                    set status "Playing..."
                    set ::gSpotifyStateIsPlaying 1
                } elseif { [string is false -strict [dict get $::gSpotifyState "is_playing"]] } {
                    set status "Pause"
                } else {
                    rm log -error "could not detect playing state: [dict get $::gSpotifyState "is_playing"]"
                    set status "ERROR: unknown 'is_playing'"
                }

            } {
                rm log -error "could not find 'is_playing' field: $::gSpotifyState"
                set status "ERROR: no is_playing"
            }

            #if { [dict exists $::gSpotifyState "item" "album" "name"] } {
            #    set track [encoding convertfrom utf-8 [dict get $::gSpotifyState "item" "album" "name"]]
            #} else {
            #    set track "Unknown"
            #}
            if { [dict exists $::gSpotifyState "item" "name"] } {
                set track [encoding convertfrom utf-8 [dict get $::gSpotifyState "item" "name"]]
            } else {
                set track "Unknown"
            }

            set artists [list]

            if { [dict exists $::gSpotifyState "item" "artists"] } {
                if { [catch {
                    foreach rec [dict get $::gSpotifyState "item" "artists"] {
                        if { [dict exists $rec name] } {
                            lappend artists [encoding convertfrom utf-8 [dict get $rec name]]
                        }
                    }
                } errMsg] } {
                    rm log -error "error while creating artist name: $errMsg"
                }
            }

            if { [llength $artists] } {
                set artist [join $artists ", "]
            } {
                set artist "Unknown"
            }

            array set images [list]

            if { [dict exists $::gSpotifyState "item" "album" "images"] } {
                if { [catch {
                    foreach rec [dict get $::gSpotifyState "item" "album" "images"] {
                        if { [dict exists $rec height] && [dict exists $rec url] } {
                            set images([dict get $rec height]) [dict get $rec url]
                        }
                    }
                } errMsg] } {
                    rm log -error "error while getting cover: $errMsg"
                }
            }

            foreach h {64 300 640} {
                if { [info exists images($h)] } {
                    set coverURL $images($h)
                    break
                }
            }

            if { $coverURL eq "" } {
                rm log -warning "could not find suitable cover. Array names: [array names images]"
            } else {

                set coverFile "[binary encode hex [::twapi::md5 $coverURL]].jpg"
                set coverFile [file join [rm getVariable tempDirectory] $coverFile]

                if { ![file exists $coverFile] } {

                    if { [catch {
                        set chan [open $coverFile w]
                        ::http::geturl $coverURL -channel $chan -timeout 5000
                    } errMsg] } {
                        set coverFile ""
                    } {
                        rm log -debug "cover was successfully downloaded: $coverFile"
                    }

                    catch { close $chan }

                    if { $coverFile eq "" } {
                        catch { file delete -force -- $coverFile }
                    }

                }

            }

        }

        if { [info exists ::gSpotifyStateIsPlaying] } {
            rm setOption "Text" ";" -section ControlPlay
        } else {
            rm setOption "Text" "4" -section ControlPlay
        }
        rm meter update "ControlPlay"

        rm setOption "Text" $status -section Status
        rm meter update "Status"

        rm setOption "Text" $track -section Track
        rm setOption "ToolTipText" "$track\n$artist" -section Track
        rm meter update "Track"

        rm setOption "Text" $artist -section Artist
        rm setOption "ToolTipText" "$track\n$artist" -section Artist
        rm meter update "Artist"

        if { $coverFile eq "" } {
            set coverFile "images/unknown.png"
        }

        rm setOption "ImageName" $coverFile -section Cover
        rm meter update "Cover"

    }

    set barCurrent 0
    set barMax 1
    set timer ""

    if { ![info exists ::gSpotifyState] || $::gSpotifyState eq "" } {
        rm log -debug "could not detect position, gSpotifyState doesn't exist or empty"
    } {

        if { ![dict exist $::gSpotifyState "progress_ms"] } {
            rm log -debug "could not detect position, progress_ms doesn't exist"
        } elseif { ![dict exist $::gSpotifyState "item" "duration_ms"] } {
            rm log -debug "could not detect position, item.duration_ms doesn't exist"
        } elseif { ![string is integer -strict [dict get $::gSpotifyState "progress_ms"]] } {
            rm log -debug "could not detect position, progress_ms is not integer"
        } elseif { ![string is integer -strict [dict get $::gSpotifyState "item" "duration_ms"]] } {
            rm log -debug "could not detect position, item.duration_ms is not integer"
        } else {

            set barMax     [dict get $::gSpotifyState "item" "duration_ms"]
            set barCurrent [dict get $::gSpotifyState "progress_ms"]

            if { [info exists ::gSpotifyStateIsPlaying] } {
                set barCurrent [expr { $barCurrent + 1000 * ([clock seconds] - $::gLastSuccessfulUpdate) }]
            }

            if { $barMax > $barCurrent } {

                set left  [expr { ($barMax - $barCurrent) / 1000 }]
                set leftM [expr { $left / 60 }]
                set leftS [expr { $left % 60 }]

            } {

                set leftM [set leftS 0]

            }

            set timer [format "\[ %0.2i:%0.2i \]" $leftM $leftS]

            if { $barCurrent > $barMax } {
                rm setVariable updateForce 1
            }

        }

    }

    rm setOption "Text" $timer -section "Timer"
    rm meter update "Timer"

    rm setOption "Formula"  $barCurrent -section MeasurePlayBar
    rm setOption "MaxValue" $barMax     -section MeasurePlayBar
    rm measure update "MeasurePlayBar"

}

proc updateSpotifyState { } {

    rm log -debug "Update Spotify status ..."

    set ::gLastSuccessfulUpdate [clock seconds]
    rm setVariable updateForce 0

    unset -nocomplain ::gSpotifyState

    ::spotify::setUserAuthState [rm getVariable clientState]

    if { [catch {

        set ::gSpotifyState [::spotify::getPlaybackState]

    } errMsg] } {

        set ::gSpotifyStateError $errMsg
        rm log -error "Could not update spotify: $errMsg"

    } {

        rm log -debug "Spotify has been successfully updated"
        unset -nocomplain ::gSpotifyStateError

    }

}

proc control { action } {

    ::spotify::setUserAuthState [rm getVariable clientState]

    if { [catch {

        if { $action eq "prev" } {

            ::spotify::skipToPrevious

        } elseif { $action eq "next" } {

            ::spotify::skipToNext

        } elseif { $action eq "play" } {

            if { [info exists ::gSpotifyStateIsPlaying] } {
                ::spotify::pausePlayback
            } else {
                ::spotify::startPlayback -device_id [rm getVariable latestDeviceId]
            }

        } else {
            return -code error "unknown action: $action"
        }

    } errMsg] } {
        rm log -error "Spotify control error: $errMsg"
    } else {
        rm setVariable updateForce 1
        rm measure update "Tcl"
    }

}

set settingsUI {

    lappend ::auto_path [file join [rm getPathResources] Scripts spotify-deps]

    package require tclspotify

    set procLoadSettings [list apply {{
        varState
    } {

       set ::gClientId     [rm getVariable "clientId"]
       set ::gClientSecret [rm getVariable "clientSecret"]
       set ::gRedirect     [rm getVariable "authRedirect"]
       set ::gPort         [rm getVariable "authPort"]

       set $varState ""

    }}]

    set procSaveSettings [list apply {{
        varState
    } {

        rm log -debug "Apply settings..."

        set update 0

        if { $::gClientId ne [rm getVariable "clientId"] || $::gClientSecret ne [rm getVariable "clientSecret"] } {
            storeVariable clientId     $::gClientId
            storeVariable clientSecret $::gClientSecret
            storeVariable clientState  [set $varState]
            rm setVariable updateForce 1
            set update 1
        } {
            rm log -debug "clientId&clientSecret are not changed"
            if { [set $varState] ne "" } {
                rm log -debug "client state has been updated"
                storeVariable clientState [set $varState]
                rm setVariable updateForce 1
                set update 1
            } else {
                rm log -debug "client state has NOT been updated"
            }
        }

        if { $update } {
            rm log -debug "Request update..."
            rm measure update [rm getMeasureName]
        } else {
            rm log -debug "No update required"
        }

    }}]

    tkm::packer -path .settings -newwindow -title "Settings: [file tail [rm getSkinName]]" {

        set varState [tkm::var]

        tkm::labelframe -text "Authorization:" -image [tkm::icon key] \
            -padx 10 -pady 13 -fill both -expand 1 -- {


            tkm::frame -pady {5 0} -padx 10 -fill x -- {

                tkm::defaults -fill both

                tkm::label -padx {0 5} -text "Client ID:" -column 0 -row 0

                tkm::entry -pady {0 5} -textvariable ::gClientId -column +

                tkm::label -padx {0 5} -text "Client secret:" -column 0 -row 1

                tkm::entry -textvariable ::gClientSecret -column +

                tkm::label -pady {5 0} -text "Note: Add the following callback URL to your application:" \
                    -column 0 -row 3 -columnspan 2

                tkm::entry -pady {0 10} -state readonly -textvariable ::gRedirect -row + -columnspan 2

                tkm::frame -pady {5 10} -row + -columnspan 2 -- {

                    set wAuthButton [tkm::button -ipadx 5 -ipady 3 -padx {0 5} \
                        -text "Authorize app" -image [tkm::icon key_go] -side left]

                    set wAuthResult [tkm::label -text "" -side right -fill x -expand 1]

                }

                grid columnconfigure [tkm::parent] 1 -weight 1
                grid rowconfigure [tkm::parent] 1 -weight 1

            }

        }

        tkm::separator -orient horizontal \
            -fill x -pady {5 0} -padx 15

        tkm::frame -padx 10 -pady 10 -- {

            tkm::defaults -padx 5 -pady 3 -side left

            set wActionOk    [tkm::button -text "OK"    -image [tkm::icon tick]]
            set wActionClose [tkm::button -text "Close" -image [tkm::icon cross]]
            set wActionApply [tkm::button -text "Apply" -image [tkm::icon cog_go]]

        }

        set procAction [list apply {{
            procSaveSettings
            varState
            window action
        } {

            if { $action in {ok apply} } {

                if { $procSaveSettings ne "" } {
                    {*}$procSaveSettings $varState
                }

            }

            if { $action in {ok close} } {
                destroy $window
            }

        }} \
            $procSaveSettings \
            $varState \
            [tkm::parent] \
        ]

        $wActionOk    configure -command [concat $procAction ok]
        $wActionClose configure -command [concat $procAction close]
        $wActionApply configure -command [concat $procAction apply]

        $wAuthButton configure -command [list apply {{
            wAuthButton wAuthResult
            varState
        } {

            $wAuthResult configure -text "In progress ...."
            $wAuthButton state disabled

            update

            if { [catch {

                rm log -debug "\[Spotify auth\] Starting web server..."

                ::spotify::startUserAuthWebServer -port $::gPort

                rm log -debug "\[Spotify auth\] Starting web browser..."

                ::spotify::runUserAuthLink -client_id $::gClientId \
                    -redirect_uri $::gRedirect \
                    -scope {user-modify-playback-state user-read-recently-played user-read-playback-position playlist-read-collaborative user-read-playback-state user-read-email user-read-currently-playing}

                rm log -debug "\[Spotify auth\] Waiting for confirmation..."

                set code [::spotify::checkUserAuthWebServer -timeout 120]

                rm log -debug "\[Spotify auth\] Code: $code"

                ::spotify::stopUserAuthWebServer

                rm log -debug "\[Spotify auth\] Requesting an access token..."

                set resp [::spotify::requestAccessToken -code $code \
                    -redirect_uri $::gRedirect -client_id $::gClientId -client_secret $::gClientSecret]

                rm log -debug "\[Spotify auth\] state: $resp"

                if { ![dict exists $resp access_token] } {
                    return -code error "Failed to get access token"
                }

            } errMsg] } {
                rm log -error "Spotify authorization error: $errMsg"
                $wAuthResult configure -text "Error: $errMsg"
            } else {
                rm log -notice "Spotify successfully authorized"
                $wAuthResult configure -text "Result: successful authorization"
                set $varState [::spotify::getUserAuthState]
            }

            catch { ::spotify::stopUserAuthWebServer }

            $wAuthButton state !disabled

        }} \
            $wAuthButton $wAuthResult \
            $varState \
        ]

    }

    {*}$procLoadSettings $varState

    wm resizable .settings 0 0

    tkm::centerWindow .settings

}
