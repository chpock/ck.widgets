# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set ::debug 0

proc Initialize {} {

    rm log -debug "Initializing the '[file tail [rm getSkinName]]' skin ..."

    rm setVariable apixu_key "86db68646fdde87944e035e74336dc54"
    rm setVariable ipinfo_token "22a30e48bd5f11"

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

    rm setContextMenu "Configure skin" \
        -action [rm bang CommandMeasure [rm getMeasureName] "settingsUI"]

    if { [info exists ::debug] && [string is true -strict $::debug] } {
        rm setContextMenu "Open tkcon" \
            -action [rm bang CommandMeasure [rm getMeasureName] "rm tkcon"]
    }

    package require rl_json

    set fd [open [file join [rm getPathSkin] "conditions.json"] r]
    fconfigure $fd -encoding binary -translation binary
    set data [read $fd]
    close $fd

    # remove BOM
    if { [string range $data 0 2] eq "\xef\xbb\xbf" } {
        rm log -debug "remove BOM"
        set data [string range $data 3 end]
    }
    set data [encoding convertfrom utf-8 $data]

    set conditions_map [list]
    foreach rec [rl_json::json get $data] {
        dict set conditions_map [dict get $rec code] $rec
    }
    rm setVariable conditions_map $conditions_map

}

proc updateBackground { } {

    rm log -debug "Update background..."

    foreach var {
        TopPadding
        PadY
        PadYForecast
        PadYCurrentWeather
        HeightCurrentWeather
        HeightCurrentLocation
        HeightCurrentUpdate
        HeightForecastDay
        HeightForecastIcon
        HeightForecastTemp
    } {
        set $var [rm getVariable $var -format integer -default 0]
        if { [set $var] eq "" || [set $var] eq "0" } {
            rm log -warn "Variable '$var' is not defined"
        }
        rm log -trace "$var = '[set $var]'"
    }

    foreach var {
        showLocation
        showUpdate
        showForecast
        showForecastDay
        showForecastIcon
        showForecastTemp
    } {
        set $var [rm getVariable $var -format integer -default 1]
        if { [set $var] eq "" } {
            rm log -warn "Variable '$var' has empty value"
            set $var 1
        }
    }

    set BackgroundHeight {
        $TopPadding +
        $HeightCurrentWeather +
        ( $showLocation || $showUpdate || ($showForecast && ($showForecastDay || $showForecastIcon || $showForecastTemp)) ) * (
             $PadYCurrentWeather +
             $showLocation * ($HeightCurrentLocation + $PadY) +
             $showUpdate * ($HeightCurrentUpdate + $PadY) +
             ( $showForecast && ($showForecastDay || $showForecastIcon || $showForecastTemp) ) * (
                 ($showLocation || $showUpdate) * $PadYForecast +
                 $showForecastDay * ($HeightForecastDay + $PadY) +
                 $showForecastIcon * ($HeightForecastIcon + $PadY) +
                 $showForecastTemp * ($HeightForecastTemp + $PadY)
             )
        ) +
        $TopPadding
    }

    rm log -trace "Background height: [subst -nobackslashes -nocommands $BackgroundHeight]"

    set BackgroundHeight [expr $BackgroundHeight]

    rm log -debug "Result background height: $BackgroundHeight"

    rm setVariable "BackgroundHeight" $BackgroundHeight
    rm meterGroup update "SkinBackground"

}

proc Update {} {

    if { [rm getVariable "initBackground" -default 0] in {"" 0} } {
        rm log -debug "Background is not initialized"
        updateBackground
        rm setVariable "initBackground" 1
    }

    # do not update more than once every 20 minutes
    if {
        [info exists ::gLastSuccessfulUpdate] &&
        [expr { [clock seconds] - $::gLastSuccessfulUpdate < ( 60*20 ) }] &&
        ![string is true -strict [rm getVariable updateForce]]
    } {

        rm log -debug "Don't need to update the '[file tail [rm getSkinName]]' skin"
        rm log -debug "The last successful update is: ${::gLastSuccessfulUpdate}; Current timestamp is: [clock seconds]; Diff: [expr { [clock seconds] - ${::gLastSuccessfulUpdate} }]; Force update: [rm getVariable updateForce]"

        set lastUpdate [howLongAgo $::gLastUpdate]
        rm meter set LastUpdate "Text" "Updated: $lastUpdate"
        rm meter update LastUpdate
        return
    }

    rm log -debug "Update the '[file tail [rm getSkinName]]' skin ..."

    set unitTemp [rm getVariable "UnitTemp" -default "F"]
    if { $unitTemp ni {F C} } {
        rm log -warn "Unknown unit temp: '$unitTemp'"
        set unitTemp "F"
    }

    set tempString [list apply {{ temp } {
        upvar unitTemp unitTemp

        if { $unitTemp eq "C" } {
            set temp [expr { round((5.0/9.0)*($temp - 32.0)) }]
        }

        return "$temp\xB0[expr { $unitTemp eq "C"?"C":"F" }]"
    }}]

    set tempStringShort [list apply {{ temp } {
        upvar unitTemp unitTemp

        if { $unitTemp eq "C" } {
            set temp [expr { round((5.0/9.0)*($temp - 32.0)) }]
        }

        return "$temp\xB0"
    }}]

    set returnError [list apply {{ logMessage { showMessage "Internal Error" } } {

        rm log -error "[file tail [rm getSkinName]]: $logMessage"
        rm setOption "Text" $showMessage -section "RefreshText1"

        rm meterGroup hide WeatherMeters
        rm meter      hide RetrievingWeather
        rm meterGroup show RefreshOverlay
        rm meterGroup update RefreshOverlay
        rm meter      hide RefreshButtonHoverEdge

        return -level 2

    }}]

    if { [catch {
        package require http
        package require twapi
        package require twapi_crypto
        package require rl_json
        http::register https 443 [list ::twapi::tls_socket]
    } errmsg] } {
        {*}$returnError $::errorInfo
    }

    if {
        [rm getVariable "locationType"] eq "auto" ||
        [set varWOID [rm getVariable "locationWOID"]] eq ""
    } {

        unset -nocomplain varWOID

        set url "http://ipinfo.io/geo"

        rm log -notice "Request location: $url ..."

        append url ?[http::formatQuery \
            "token"  [rm getVariable ipinfo_token] \
        ]

        if { [catch {
            set token [http::geturl $url  -timeout 2000]
        } errmsg] } {
            {*}$returnError $errmsg "Connection Error"
        }

        set status [http::status $token]
        if { $status ne "ok" } {
            http::cleanup $token
            {*}$returnError "connection status: $status" "Connection [string totitle $status]"
        }

        set ncode [http::ncode $token]
        if { $ncode != "200" } {
            http::cleanup $token
            {*}$returnError "connection error code: $ncode" "Connection Error: $ncode"
        }

        set data [http::data $token]
        http::cleanup $token
        if { [catch {
            rl_json::json get $data
        } errmsg] } {
            rm log -error "Data: $data"
            {*}$returnError "Unable to parse json: $errmsg"
        }
        set data $errmsg

        if { [catch {
            set location [join [list \
                [dict get $data city] \
                [dict get $data region] \
                [dict get $data country]] {,} \
            ]
        } errmsg] } {
            {*}$returnError "JSON has no required values: $::errorInfo"
        }

        rm log -notice "Retrieved location: $location"

    }

    set url "http://api.weatherstack.com/current"

    if { [info exists varWOID] } {

        append url ?[http::formatQuery \
            query $varWOID \
        ]

    } else {

        append url ?[http::formatQuery \
            query $location
        ]

    }

    append url &[http::formatQuery \
        "access_key"  [rm getVariable apixu_key] \
    ]

    rm log -notice "Request weather: $url"

    if { [catch {
        set token [http::geturl $url -timeout 2000]
    } errmsg] } {
        {*}$returnError $errmsg "Connection Error"
    }

    set status [http::status $token]
    if { $status ne "ok" } {
        http::cleanup $token
        {*}$returnError "connection status: $status" "Connection [string totitle $status]"
    }

    set ncode [http::ncode $token]
    if { $ncode != "200" } {
        http::cleanup $token
        {*}$returnError "connection error code: $ncode" "Connection Error: $ncode"
    }

    set data [http::data $token]
    http::cleanup $token

    if { [catch {
        rl_json::json get $data
    } errmsg] } {
        rm log -error "Data: $data"
        {*}$returnError "Unable to parse json: $errmsg"
    }

    set data $errmsg

    set cond_map [rm getVariable conditions_map]
    set hour [clock format [clock seconds] -format "%k"]
    if { $hour > 6 && $hour < 21 } {
        set mode "day"
    } else {
        set mode "night"
    }

    if { [catch {

        set location "[dict get $data location name], [dict get $data location region], [dict get $data location country]"

        set conditionCode [dict get $data current condition code]
        set conditionDate [dict get $data current last_updated_epoch]
        set conditionTemp [dict get $data current temp_f]
        set conditionText [dict get $cond_map [dict get $data current condition code] $mode]

        rm log -debug "lastUpdate: $conditionDate"
        set ::gLastUpdate $conditionDate
        set lastUpdate [howLongAgo $conditionDate]

        set forecastData [dict get $data forecast forecastday]

        set fcCount 0
        foreach forecastDataItem $forecastData {
            set forecastCode$fcCount [dict get $forecastDataItem day condition code]
            set forecastDate$fcCount [dict get $forecastDataItem date_epoch]
            set forecastDay$fcCount  [lindex "Sun Mon Tue Wed Thu Fri Sat Sun" \
                                         [clock format \
                                             [dict get $forecastDataItem date_epoch] \
                                             -format "%w" \
                                         ] \
                                     ]
            set forecastHi$fcCount   [dict get $forecastDataItem day maxtemp_f]
            set forecastLo$fcCount   [dict get $forecastDataItem day mintemp_f]
            set forecastText$fcCount [dict get $cond_map [dict get $forecastDataItem day condition code] $mode]
            incr fcCount
        }

    } errmsg] } {
        rm log -error "Data: $data"
        {*}$returnError "Unable to parse data: $::errorInfo"
    }

    if { $fcCount < 4 } {
        {*}$returnError "Forecast count less then 4: $fcCount"
    }

    rm meterGroup hide   RefreshOverlay
    rm meter      hide   RetrievingWeather
    rm meterGroup show   WeatherMeters

    rm meter set CurrentLocation "Text"      "Location: $location"
    rm meter set LastUpdate      "Text"      "Updated: $lastUpdate"
    rm meter set CurrentImage    "ImageName" "images/$mode/[dict get $cond_map $conditionCode icon].png"
    rm meter set CurrentText     "Text"      $conditionText
    rm meter set CurrentTemp     "Text"      [{*}$tempString $conditionTemp]

    for { set i 0 } { $i < $fcCount } { incr i } {
        if { ![rm meter exists ForecastDay$i] } {
            rm log -debug "Forecast #$i doesn't exist"
        } else {
            rm meter set ForecastDay$i  "Text" [set "forecastDay$i"]
            rm meter set ForecastIcon$i "ImageName" "images/day/[dict get $cond_map [set forecastCode$i] icon].png"
            rm meter set ForecastHi$i   "Text" [{*}$tempStringShort [set forecastHi$i]]
            rm meter set ForecastLo$i   "Text" [{*}$tempStringShort [set forecastLo$i]]
        }
    }

    rm log -debug "set the last successful update timestamp: [clock format [clock seconds]]"

    rm setVariable "updateForce" 0
    set ::gLastSuccessfulUpdate [clock seconds]

    foreach var {
        showLocation
        showUpdate
        showForecast
        showForecastDay
        showForecastIcon
        showForecastTemp
    } {
        set $var [rm getVariable $var -format integer -default 1]
        if { [set $var] eq "" } {
            rm log -warn "Variable '$var' has empty value"
            set $var 1
        }
    }

    if { !$showLocation } {
        rm meter hide "CurrentLocation"
    }

    if { !$showUpdate } {
        rm meter hide "LastUpdate"
    }

    if { !$showForecast } {
        set showForecastDay  0
        set showForecastIcon 0
        set showForecastTemp 0
    }

    if { !$showForecastDay } {
        rm meterGroup hide "ForecastDay"
    }

    if { !$showForecastIcon } {
        rm meterGroup hide "ForecastIcon"
    }

    if { !$showForecastTemp } {
        rm meterGroup hide "ForecastTemp"
    }

    rm meterGroup update WeatherMeters

    rm skin update

}


# Settings

set settingsUI {

    tkm::packer -path .settings -newwindow -title "Settings: [file tail [rm getSkinName]]" {

        tkm::labelframe -text "Location:" -image [tkm::icon world_go] \
            -padx 10 -pady 13 -fill both -expand 1 -- {

            tkm::defaults -fill both -padx 5 -pady 3

            set varLocationType [tkm::var]

            set wSearchRadioAuto [tkm::radiobutton -text "Auto" \
                -variable $varLocationType -value "auto" \
                -column 0 -columnspan 3]

            set wSearchRadioSpecific [tkm::radiobutton -text "Specific:" \
                -variable $varLocationType -value "specific" \
                -row +]

            set varLocationCurrent [tkm::var]

            set wLocationCurrent [tkm::label \
                -font [concat [font configure TkTextFont] -weight bold] \
                -column + -columnspan 2]

            set varSearchEntry [tkm::var]

            set wSearchEntry [tkm::entry -textvariable $varSearchEntry \
                -row + -columnspan 2]

            set wSearchButton [tkm::button -text "Search" \
                -column +]

            tkm::frame -row + -columnspan 3 -- {

                tkm::defaults -fill both

                set wSearchListbox [tkm::listbox -height 5 \
                    -yscrollcommand [list "[tkm::parent].sby" set] \
                    -column 0]

                tkm::scrollbar .sby -command [list $wSearchListbox yview] -column +

                grid columnconfigure [tkm::parent] 0 -weight 1
                grid rowconfigure [tkm::parent] 0 -weight 1

            } -pady {3 10}

            grid columnconfigure [tkm::parent] 1 -weight 1

        }

        tkm::labelframe -text "Parameters:" -image [tkm::icon wrench] \
            -pady {0 13} -padx 10 -fill x -- {

            tkm::defaults -pady {4 8} -padx 5

            tkm::label -text "Temperature units:" \
                -side left -padx {8 2}

            set varParamTempUnits [tkm::var]

            tkm::radiobutton -text "Celsius" -variable $varParamTempUnits -value "C" \
                -side left
            tkm::radiobutton -text "Fahrenheit" -variable $varParamTempUnits -value "F" \
                -side left -padx {5 8}

        }

        tkm::labelframe -text "Visible Elements:" -image [tkm::icon eye] \
            -pady {0 13} -padx 10 -fill x -- {

            tkm::defaults -padx 8 -pady 2

            set varVisibleLocation [tkm::var]
            set varVisibleUpdate   [tkm::var]
            set varVisibleForecast [tkm::var]
            set varVisibleForecastDays  [tkm::var]
            set varVisibleForecastIcons [tkm::var]
            set varVisibleForecastTemp  [tkm::var]

            tkm::checkbutton -text "Current Location" -variable $varVisibleLocation \
                -anchor w -pady {5 2}
            tkm::checkbutton -text "Last Update" -variable $varVisibleUpdate \
                -anchor w
            set wVisForecast [tkm::checkbutton -text "Forecast" \
                -variable $varVisibleForecast \
                -anchor w]
            set wVisForecastDays [tkm::checkbutton -text "Forecast - Day Name" \
                -variable $varVisibleForecastDays \
                -anchor w]
            set wVisForecastIcons [tkm::checkbutton -text "Forecast - Icon" \
                -variable $varVisibleForecastIcons \
                -anchor w]
            set wVisForecastTemp [tkm::checkbutton -text "Forecast - Temperature" \
                -variable $varVisibleForecastTemp \
                -anchor w -pady {2 8}]

        }

        tkm::separator -orient horizontal -fill x -padx 15

        tkm::frame -side bottom -padx 10 -pady 10 -anchor e -- {

            tkm::defaults -padx 5 -pady 3 -side left

            set wActionOk    [tkm::button -text "OK"    -image [tkm::icon tick]]
            set wActionClose [tkm::button -text "Close" -image [tkm::icon cross]]
            set wActionApply [tkm::button -text "Apply" -image [tkm::icon cog_go]]

        }

        wm resizable [tkm::parent] 0 0

        tkm::centerWindow [tkm::parent]

        $wSearchButton configure -command [list apply {{
            wToplevel wSearchListbox wSearchButton wSearchRadioAuto varSearchEntry
        } {

            set ::gMapWOID [list]

            set returnError [list apply {{ wToplevel logMessage { showMessage "Internal Error" } } {

                set msg "[file tail [rm getSkinName]]: Search location: $logMessage"

                rm log -error $msg

                tk_messageBox -icon error -message $msg -parent $wToplevel \
                    -title "Error" -type ok

                return -level 2

            }} $wToplevel]

            if { [catch {
                package require http
                package require twapi
                package require twapi_crypto
                package require rl_json
                http::register https 443 [list ::twapi::tls_socket]
            } errmsg] } {
                {*}$returnError $::errorInfo
            }

            $wSearchButton state "disabled"
            $wSearchRadioAuto state "disabled"

            $wSearchListbox delete 0 end

            update

            set searchString [set $varSearchEntry]

            set url "http://api.apixu.com/v1/search.json"

            append url ?[http::formatQuery \
                q   $searchString \
                key [rm getVariable apixu_key] \
            ]

            rm log -notice "Request - search location: $url"

            if { [catch {
                set token [http::geturl $url -timeout 2000]
            } errmsg] } {
                {*}$returnError $errmsg "Connection Error"
            }

            set status [http::status $token]
            if { $status ne "ok" } {
                http::cleanup $token
                {*}$returnError "connection status: $status" "Connection [string totitle $status]"
            }

            set ncode [http::ncode $token]
            if { $ncode != "200" } {
                http::cleanup $token
                {*}$returnError "connection error code: $ncode" "Connection Error$ncode"
            }

            set data [http::data $token]
            http::cleanup $token

            if { [catch {
                rl_json::json get $data
            } errmsg] } {
                rm log -error "Data: $data"
                {*}$returnError "Unable to parse json: $errmsg"
            }

            set data $errmsg

            set count [llength $data]

            if { $count < 1 } {
                {*}$returnError "Could not find any locations"
            }

            foreach rec $data {

                rm log -debug "REC: $rec"

                set name  [dict get $rec name]
                set woeid [dict get $rec name]

                $wSearchListbox insert end $name

                dict set ::gMapWOID $name $woeid

            }

            $wSearchButton state "!disabled"
            $wSearchRadioAuto state "!disabled"

        }} [tkm::parent] $wSearchListbox $wSearchButton $wSearchRadioAuto $varSearchEntry]

        $wSearchEntry configure -validate all -validatecommand [list apply {{ wSearchEntry wSearchButton value } {

            if { [string trim $value] eq "" } {
                $wSearchButton state "disabled"
            } else {
                $wSearchButton state "!disabled"
            }

        return 1

        }} $wSearchEntry $wSearchButton %P]

        $wSearchRadioAuto configure -command [list apply {{ wSearchEntry wSearchButton wSearchListbox } {

            $wSearchEntry   state "disabled"
            $wSearchButton  state "disabled"
            $wSearchListbox configure -state "disabled"

        }} $wSearchEntry $wSearchButton $wSearchListbox]

        $wSearchRadioSpecific configure -command [list apply {{ wSearchEntry wSearchButton wSearchListbox } {

            $wSearchEntry   state "!disabled"
            $wSearchButton  state "!disabled"
            $wSearchListbox configure -state "normal"

            focus $wSearchEntry

        }} $wSearchEntry $wSearchButton $wSearchListbox]

        bind $wSearchEntry <Return> [list apply {{ wSearchButton } {

            $wSearchButton invoke

        }} $wSearchButton]

        set procUpdateLocationCurrent [list apply {{ varLocationCurrent wLocationCurrent } {

            set text [set textVisible [set $varLocationCurrent]]
            set font [$wLocationCurrent cget -font]
            set widthWidget [winfo width $wLocationCurrent]

            while { [font measure $font $textVisible] >= $widthWidget } {
                set textVisible [string range $textVisible 0 end-1]
            }

            if { $text ne $textVisible } {

                set widthWidget [expr { $widthWidget - [font measure $font "... "] }]
                while { [font measure $font $textVisible] >= $widthWidget } {
                    set textVisible [string range $textVisible 0 end-1]
                }

                append textVisible "..."

            }

            $wLocationCurrent configure -text $textVisible

        }} $varLocationCurrent $wLocationCurrent]

        bind $wSearchListbox <<ListboxSelect>> [list apply {{ wSearchListbox varLocationCurrent procUpdateLocationCurrent } {

            if { ![llength [set cursel [$wSearchListbox curselection]]] } {
                return
            }

            set cursel [lindex $cursel 0]
            set cursel [$wSearchListbox get $cursel]
            set $varLocationCurrent $cursel
            {*}$procUpdateLocationCurrent

        }} $wSearchListbox $varLocationCurrent $procUpdateLocationCurrent]

        set procUpdateVisForecast [list apply {{
            varVisibleForecast
            wVisForecastDays wVisForecastIcons wVisForecastTemp
        } {

            if { [set $varVisibleForecast] } {
                $wVisForecastDays  state "!disabled"
                $wVisForecastIcons state "!disabled"
                $wVisForecastTemp  state "!disabled"
            } else {
                $wVisForecastDays  state "disabled"
                $wVisForecastIcons state "disabled"
                $wVisForecastTemp  state "disabled"
            }

        }} $varVisibleForecast \
            $wVisForecastDays $wVisForecastIcons $wVisForecastTemp \
        ]

        $wVisForecast configure -command $procUpdateVisForecast

        set procAction [list apply {{
            varLocationType varLocationCurrent
            varParamTempUnits
            varVisibleLocation varVisibleUpdate varVisibleForecast
            varVisibleForecastDays varVisibleForecastIcons varVisibleForecastTemp
            window action
        } {

            if { $action in {ok apply} } {

                set update 0

                foreach { tclVar rmVar } [list \
                    $varLocationType    locationType \
                    $varLocationCurrent locationName \
                    $varParamTempUnits  unitTemp     \
                    $varVisibleLocation showLocation \
                    $varVisibleUpdate   showUpdate   \
                    $varVisibleForecast showForecast \
                    $varVisibleForecastDays  showForecastDay \
                    $varVisibleForecastIcons showForecastIcon \
                    $varVisibleForecastTemp  showForecastTemp \
                ] {

                    if { [set $tclVar] ne [rm getVariable $rmVar] } {
                        storeVariable $rmVar [set $tclVar]
                        set update 1
                    }

                }

                if {
                    [set $varLocationType] ne "auto" &&
                    [info exists ::gMapWOID] &&
                    [dict exists $::gMapWOID [set $varLocationCurrent]]
                } {

                    storeVariable locationWOID [dict get $::gMapWOID [set $varLocationCurrent]]
                    set update 1

                }

                if { $update } {
                    rm setVariable "updateForce" 1
                    rm setVariable "initBackground" 0
                    rm measure update [rm getMeasureName]
                }

            }

            if { $action in {ok close} } {
                destroy $window
            }

        }} $varLocationType $varLocationCurrent \
            $varParamTempUnits \
            $varVisibleLocation $varVisibleUpdate $varVisibleForecast \
            $varVisibleForecastDays $varVisibleForecastIcons $varVisibleForecastTemp \
            [tkm::parent] \
        ]

        $wActionOk configure    -command [concat $procAction ok]
        $wActionClose configure -command [concat $procAction close]
        $wActionApply configure -command [concat $procAction apply]

    }

    set $varParamTempUnits [rm getVariable unitTemp]

    set $varLocationCurrent [rm getVariable locationName]
    set $varVisibleLocation [rm getVariable showLocation]
    set $varVisibleUpdate   [rm getVariable showUpdate]
    set $varVisibleForecast [rm getVariable showForecast]
    set $varVisibleForecastDays  [rm getVariable showForecastDay]
    set $varVisibleForecastIcons [rm getVariable showForecastIcon]
    set $varVisibleForecastTemp  [rm getVariable showForecastTemp]

    {*}$procUpdateVisForecast

    if { [rm getVariable locationType] eq "auto" } {
        $wSearchRadioAuto invoke
    } else {
        $wSearchRadioSpecific invoke
    }

    update

    set $varLocationCurrent [rm getVariable locationName]
    {*}$procUpdateLocationCurrent

}
