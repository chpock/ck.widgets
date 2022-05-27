# ck.widgets
# Copyright (C) 2022 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug 1

set gSpotifyThreadCode {

    rm log -debug "\[Spotify thread\] Starting the thread ..."

    foreach tempVar [list TMPDIR TEMP TMP] {
        if { [info exists ::env($tempVar)] } {
            set tempDirectory [file join $::env($tempVar) rm-spotify-covers]
            if { [catch { file mkdir $tempDirectory } errMsg] } {
                rm log -warning "\[Spotify thread\] could not create temp directory '$tempDirectory': $errMsg"
                unset tempDirectory
            }
        }
    }

    if { [info exists tempDirectory] } {
        rm log -debug "\[Spotify thread\] Using temp directory: $tempDirectory"
        set gTempDirectory $tempDirectory
    }

    lappend ::auto_path [file join [rm getPathResources] Scripts spotify-deps]

    package require tclspotify

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

    ::spotify::callbackUserAuthState [list apply {{ } {
        rm log -debug "\[Spotify thread\] Update Spotify client state ..."
        storeVariable clientState [::spotify::getUserAuthState]
    }}]

    set gLatestDeviceId [rm getVariable latestDeviceId]
    set gIsPlaying 0
    set gLikeStateCache [dict create]

    proc updateSpotifyState { } {

        unset -nocomplain ::gSpotifyTimer

        rm log -debug "\[Spotify thread\] Update state ..."

        if { [catch { updateSpotifyStateReal } errMsg] } {
            rm log -tclerror "\[Spotify thread\] Update state ERROR: $errMsg"
        }

        set ::gSpotifyTimer [after 5000 updateSpotifyState]

    }

    proc updateSpotifyStateReal { } {

        set state [dict create lastUpdate [clock seconds]]

        dict set state current likeStatus "unknown"

        if { [catch {

            set spotifyState [::spotify::getPlaybackState]

        } errMsg] } {

            rm log -error "\[Spotify thread\] Could not update: $errMsg"

            dict set state status "error"
            dict set state errorMessage $errMsg

        } elseif { $spotifyState eq "" } {

            rm log -debug "\[Spotify thread\] state is empty"

            dict set state status "pause"

        } {

            rm log -debug "\[Spotify thread\] Spotify has been successfully updated"

            set ::gIsPlaying 0

            if { [dict exists $spotifyState "item" "id"] } {
                if { [dict exists $::gLikeStateCache [dict get $spotifyState "item" "id"]] } {
                    dict set state current likeStatus [dict get $::gLikeStateCache [dict get $spotifyState "item" "id"] status]
                }
            }

            if { ![dict exist $spotifyState "progress_ms"] } {
                rm log -debug "\[Spotify thread\] could not detect position, progress_ms doesn't exist"
            } elseif { ![dict exist $spotifyState "item" "duration_ms"] } {
                rm log -debug "\[Spotify thread\] could not detect position, item.duration_ms doesn't exist"
            } elseif { ![string is integer -strict [dict get $spotifyState "progress_ms"]] } {
                rm log -debug "\[Spotify thread\] could not detect position, progress_ms is not integer"
            } elseif { ![string is integer -strict [dict get $spotifyState "item" "duration_ms"]] } {
                rm log -debug "\[Spotify thread\] could not detect position, item.duration_ms is not integer"
            } else {
                dict set state current position   [dict get $spotifyState "progress_ms"]
                dict set state current duration   [dict get $spotifyState "item" "duration_ms"]
                dict set state current lastUpdate [clock seconds]
            }

            if { [dict exists $spotifyState "device" "id"] } {

                set device [dict get $spotifyState "device" "id"]

                if { $device ne $::gLatestDeviceId } {
                    storeVariable latestDeviceId $device
                    set ::gLatestDeviceId $device
                }

            }

            if { [dict exists $spotifyState "is_playing"] } {

                if { [string is true -strict [dict get $spotifyState "is_playing"]] } {
                    dict set state status "play"
                    set ::gIsPlaying 1
                } elseif { [string is false -strict [dict get $spotifyState "is_playing"]] } {
                    dict set state status "pause"
                } else {
                    rm log -error "\[Spotify thread\] could not detect playing state: [dict get $spotifyState "is_playing"]"
                    dict set state status "error"
                    dict set state errorMessage "ERROR: unknown 'is_playing'"
                }

            } {
                rm log -error "\[Spotify thread\] could not find 'is_playing' field: $spotifyState"
                dict set state status "error"
                dict set state errorMessage "ERROR: no is_playing"
            }

            #if { [dict exists $spotifyState "item" "album" "name"] } {
            #    dict set state current track [encoding convertfrom utf-8 [dict get $spotifyState "item" "album" "name"]]
            #} else {
            #    dict set state current track "Unknown"
            #}
            if { [dict exists $spotifyState "item" "name"] } {
                dict set state current track [encoding convertfrom utf-8 [dict get $spotifyState "item" "name"]]
            } else {
                dict set state current track "Unknown"
            }

            set artists [list]

            if { [dict exists $spotifyState "item" "artists"] } {
                if { [catch {
                    foreach rec [dict get $spotifyState "item" "artists"] {
                        if { [dict exists $rec name] } {
                            lappend artists [encoding convertfrom utf-8 [dict get $rec name]]
                        }
                    }
                } errMsg] } {
                    rm log -error "\[Spotify thread\] error while creating artist name: $errMsg"
                }
            }

            if { [llength $artists] } {
                dict set state current artist [join $artists ", "]
            } {
                dict set state current artist "Unknown"
            }

            array set images [list]

            if { [dict exists $spotifyState "item" "album" "images"] } {
                if { [catch {
                    foreach rec [dict get $spotifyState "item" "album" "images"] {
                        if { [dict exists $rec height] && [dict exists $rec url] } {
                            set images([dict get $rec height]) [dict get $rec url]
                        }
                    }
                } errMsg] } {
                    rm log -error "\[Spotify thread\] error while getting cover: $errMsg"
                }
            }

            foreach h {64 300 640} {
                if { [info exists images($h)] } {
                    set coverURL $images($h)
                    break
                }
            }

            if { ![info exists coverURL] } {
                rm log -warning "\[Spotify thread\] could not find suitable cover. Array names: [array names images]"
            } else {

                set coverFile "[binary encode hex [::twapi::md5 $coverURL]].jpg"
                set coverFile [file join $::gTempDirectory $coverFile]

                if { ![file exists $coverFile] } {

                    if { [catch {
                        set chan [open $coverFile w]
                        ::http::geturl $coverURL -channel $chan -timeout 5000
                    } errMsg] } {
                        set coverFile ""
                    } {
                        rm log -debug "\[Spotify thread\] cover was successfully downloaded: $coverFile"
                    }

                    catch { close $chan }

                    if { $coverFile eq "" } {
                        catch { file delete -force -- $coverFile }
                        unset coverFile
                    }

                }

            }

            if { [info exists coverFile] } {
                dict set state current cover $coverFile
            } {
                dict set state current cover "images/unknown.png"
            }

        }

        ::thread::send -async [rm getThreadMain] [list set ::gCurrentState $state]
        #rm sendThread [rm getThreadMain] [list set ::gCurrentState $state]

        if { [info exists spotifyState] } {

            if { [dict exists $spotifyState "item" "id"] && ![dict exists $::gLikeStateCache [dict get $spotifyState "item" "id"]] } {
                if { [catch {
                    set likeState [::spotify::checkTracksForCurrentUser -ids [dict get $spotifyState "item" "id"]]
                } errMsg] } {
                    rm log -error "\[Spotify thread\] could not detect like status for id '[dict get $spotifyState "item" "id"]': $errMsg"
                } {
                    set likeState [string trim $likeState "\[\] "]
                    if { [string is true -strict $likeState] } {
                        set updateLikeState "true"
                    } elseif { [string is false -strict $likeState] } {
                        set updateLikeState "false"
                    } else {
                        rm log -error "\[Spotify thread\] could not detect like status for id '[dict get $spotifyState "item" "id"]': $likeState"
                    }
                }
            }

            if { [info exists updateLikeState] } {
                rm log -debug "\[Spotify thread\] the like state has been updated"
                dict set ::gLikeStateCache [dict get $spotifyState "item" "id"] status $updateLikeState
                dict set state current likeStatus [dict get $::gLikeStateCache [dict get $spotifyState "item" "id"] status]
                dict set state lastUpdate [expr { [dict get $state lastUpdate] + 1 }]
                ::thread::send -async [rm getThreadMain] [list set ::gCurrentState $state]
            }

        }

    }

    proc forceUpdateSpotifyState { } {
        if { ![info exists ::gSpotifyTimer] } {
            rm log -debug "\[Spotify thread\] forceUpdateSpotifyState: Already in update"
            return
        }
        #rm log -debug "\[Spotify thread\] force update"
        #foreach id [after info] { rm log -debug "After before: $id [after info $id]" }
        after cancel $::gSpotifyTimer
        #foreach id [after info] { rm log -debug "After after: $id [after info $id]" }
        updateSpotifyState
        #foreach id [after info] { rm log -debug "After after script: $id [after info $id]" }
    }

    proc setSpotifyClientState { state } {
        ::spotify::setUserAuthState $state
        storeVariable clientState $state
        forceUpdateSpotifyState
    }

    proc controlSpotify { cmd } {
        rm log -debug "\[Spotify thread\] control: $cmd"
        if { [catch {
            switch -exact -- $cmd {
                "prev" {
                    ::spotify::skipToPrevious
                }
                "next" {
                    ::spotify::skipToNext
                }
                "play" {
                    if { $::gIsPlaying } {
                        ::spotify::pausePlayback
                    } else {
                        ::spotify::startPlayback -device_id [rm getVariable latestDeviceId]
                    }
                }
                default {
                    return -code error "unknown action: $cmd"
                }
            }
        } errMsg] } {
            rm log -error "\[Spotify thread\] Spotify control error: $errMsg"
        } else {
            forceUpdateSpotifyState
        }
    }

    ::spotify::setUserAuthState [rm getVariable clientState]
    updateSpotifyState

    rm log -debug "\[Spotify thread\] The Spotify thread is working."

}

proc Initialize {} {

    rm log -debug "Initializing the '[file tail [rm getSkinName]]' skin ..."

    rm sendThread [set ::gSpotifyThread [rm newThread]] $::gSpotifyThreadCode

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

    rm setContextMenu "Configure skin" \
        -action [rm bang CommandMeasure [rm getMeasureName] "settingsUI"]

    if { [info exists ::debug] && [string is true -strict $::debug] } {
        rm setContextMenu "Open tkcon" \
            -action [rm bang CommandMeasure [rm getMeasureName] "rm tkcon"]
    }

    if { [catch {
        set ::gSpotifyExe [string trim [lindex [split [registry get {HKEY_CLASSES_ROOT\spotify\shell\open\command} ""]] 0] "\""]
    } errMsg] } {
        rm log -warning "could not find spotify exe: $errMsg"
        unset -nocomplain ::gSpotifyExe
    } {
        rm log -debug "Spotify exe: $::gSpotifyExe"
    }

}

proc Update {} {

    # get updates if any
    update idletasks

    if { ![info exists ::gCurrentState] } {
        rm log -debug "The Spotify thread is not initialized yet"
        return
    }

    #rm log -debug "Update the '[file tail [rm getSkinName]]' skin ..."

    set state $::gCurrentState

    set checkUpdate [list apply {{ state args } {

        if { ![dict exists $state {*}$args] } { return 0 }

        if { ![info exists ::gLastState] || ![dict exists $::gLastState {*}$args] || [dict get $state {*}$args] ne [dict get $::gLastState {*}$args] } {
            dict set ::gLastState {*}$args [dict get $state {*}$args]
            return 1
        } {
            return 0
        }

    }} $state]

    # If nothing changed from last time
    if { [{*}$checkUpdate lastUpdate] } {

        if { [{*}$checkUpdate status] } {

            switch -exact -- [dict get $state status] {
                play {
                    set status "Playing..."
                }
                pause {
                    set status "Pause"
                }
                error {
                    set status "ERROR: [dict get $state errorMessage]"
                }
                default {
                    set status "ERROR: unknown status: [dict get $state status]"
                }
            }

            rm setOption "Text" $status -section Status
            rm setOption "ToolTipText" $status -section Status
            rm meter update "Status"

            if { [dict get $state status] eq "play" } {
                rm setOption "Text" ";" -section ControlPlay
            } else {
                rm setOption "Text" "4" -section ControlPlay
            }
            rm meter update "ControlPlay"

        }

        if { [{*}$checkUpdate current track] } {
            rm setOption "Text" [dict get $state current track] -section Track
            set isUpdatedTrack 1
        }

        if { [{*}$checkUpdate current artist] } {
            rm setOption "Text" [dict get $state current artist] -section Artist
            set isUpdatedArtist 1
        }

        if { [info exists isUpdatedTrack] || [info exists isUpdatedArtist] } {
            if { [dict exists $state current track] && [dict exists $state current artist] } {
                set tooltip "[dict get $state current track]\n[dict get $state current artist]"
                rm setOption "ToolTipText" "$tooltip" -section Artist
                rm setOption "ToolTipText" "$tooltip" -section Track
                set isUpdatedArtist [set isUpdatedTrack 1]
            }
        }

        if { [info exists isUpdatedTrack]  } { rm meter update "Track"  }
        if { [info exists isUpdatedArtist] } { rm meter update "Artist" }

        if { [{*}$checkUpdate current cover] } {
            rm setOption "ImageName" [dict get $state current cover] -section Cover
            rm meter update "Cover"
        }

        if { [{*}$checkUpdate current likeStatus] } {
            switch -exact -- [dict get $state current likeStatus] {
                true {
                    rm setOption "FontColor" "#ColorGreensea#" -section "LikeStatus"
                    rm meter show "LikeStatus"
                }
                false {
                    rm setOption "FontColor" "#ColorConcrete#" -section "LikeStatus"
                    rm meter show "LikeStatus"
                }
                default {
                    rm meter hide "LikeStatus"
                }
            }
            rm meter update "LikeStatus"
        }

    } {

        #rm log -debug "Spotify state is the same"

    }

    {*}$checkUpdate current position
    {*}$checkUpdate current duration
    {*}$checkUpdate current lastUpdate

    if { [dict exists $::gLastState current position] && [dict exists $::gLastState current duration] } {

        if { [dict get $state status] eq "play" } {
            set virtualPosition [expr { [dict get $::gLastState current position] + 1000 * ([clock seconds] - [dict get $::gLastState current lastUpdate]) }]
        } {
            set virtualPosition [dict get $::gLastState current position]
        }
        set posBar  [list $virtualPosition [dict get $::gLastState current duration]]
        set posLeft [expr { ([dict get $::gLastState current duration] - $virtualPosition) / 1000 }]

        if { ![dict exists $::gLastState posBar] || [dict get $::gLastState posBar] ne $posBar } {
            dict set ::gLastState posBar $posBar
            rm setOption "Formula"  [lindex [dict get $::gLastState posBar] 0] -section MeasurePlayBar
            rm setOption "MaxValue" [lindex [dict get $::gLastState posBar] 1] -section MeasurePlayBar
            rm measure update "MeasurePlayBar"
        }

        if { ![dict exists $::gLastState posLeft] || [dict get $::gLastState posLeft] ne $posLeft } {
            dict set ::gLastState posLeft $posLeft
            set left [dict get $::gLastState posLeft]
            if { $left < 0 } {
                set left 0
                sendToSpotify [list "forceUpdateSpotifyState"]
            }
            set leftM [expr { $left / 60 }]
            set leftS [expr { $left % 60 }]
            rm setOption "Text" [format "\[ %0.2i:%0.2i \]" $leftM $leftS] -section "Timer"
            rm meter update "Timer"
        }

    }

}

proc sendToSpotify { code } {
    ::thread::send -async $::gSpotifyThread $code
}

proc control { cmd } {
    sendToSpotify [list controlSpotify $cmd]
}

proc showSpotify { } {
    if { ![info exists ::gSpotifyExe] } return
    exec $::gSpotifyExe
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

        if { $::gClientId ne [rm getVariable "clientId"] || $::gClientSecret ne [rm getVariable "clientSecret"] } {
            storeVariable clientId     $::gClientId
            storeVariable clientSecret $::gClientSecret
            rm sendThread [rm getThreadMain] [list sendToSpotify [list setSpotifyClientState [set $varState]]]
        } {
            rm log -debug "clientId&clientSecret are not changed"
            if { [set $varState] ne "" } {
                rm log -debug "client state has been updated"
                rm sendThread [rm getThreadMain] [list sendToSpotify [list setSpotifyClientState [set $varState]]]
            } else {
                rm log -debug "client state has NOT been updated"
            }
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
