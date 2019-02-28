# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

set debug 0

proc Initialize {} {

    rm log -debug "Initializing the '[file tail [rm getSkinName]]' skin ..."

    uplevel #0 [list source [file join [rm getPathResources] Scripts _utilities.tcl]]
    uplevel #0 [list source [file join [rm getPathResources] Scripts _settings.tcl]]

    for { set i 1 } { $i <= 12 } { incr i } {
        lappend ::gMonthLabels [clock format [clock scan "$i/1/2000"] -format "%B"]
    }

    for { set date [clock seconds] } { [clock format $date -format "%u"] != 1 } { incr date [expr { 24*60*60 }] } {}

    for { set i 0 } { $i <= 6 } { incr i } {
        lappend ::gDayLabels [string range \
            [clock format $date -format "%a"] \
            0 1 \
        ]
        incr date [expr { 24*60*60 }]
    }

}

proc Update {} {

    if { [info exists ::gLastRedraw] && $::gLastRedraw eq [clock format [clock seconds] -format "%Y %N %e"] } {
        rm log -debug "The date is not changed, update is not necessary"
        return
    }

    rm log -debug "Update the '[file tail [rm getSkinName]]' skin ..."
    draw

}

proc draw {} {

    set ::gLastRedraw [clock format [clock seconds] -format "%Y %N %e"]

    set isLeadingZeroes [rm getVariable "LeadingZeroes" -default 0]
    set isStartOnMonday [rm getVariable "StartOnMonday" -default 1]

    set dayLabels [rm getVariable "DayLabels" -default $::gDayLabels]
    set dayLabels [split $dayLabels " "]

    set monthLabels [rm getVariable "MonthLabels" -default $::gMonthLabels]
    set monthLabels [split $monthLabels " "]

    lassign [clock format [clock seconds] -format "%Y %N %e %u"] cyear cmonth cday cweekday

    if { !$isStartOnMonday } {
        set dayLabels [linsert [lrange $dayLabels 0 end-1] 0 [lindex $dayLabels end]]
    }

    incr cweekday -1
    if { !$isStartOnMonday && $cweekday == 6 } {
        set cweekday 0
    }

    set isCurrentMonth 1

    if { ![info exists ::year] } {

        set year $cyear
        set month $cmonth

    } else {

        set year $::year
        set month $::month

        if { $year == $cyear && $month == $cmonth } {
            unset ::year ::month
        } else {

            set isCurrentMonth 0

        }

    }

    rm setOption "Text"  "[lindex $monthLabels [expr { $month - 1 }]], $year" -section Title

    for { set i 0 } { $i <= 6 } { incr i } {

        if { $isCurrentMonth && $cweekday == $i } {
            set style "StyleLabelDayCurrent"
        } else {
            set style "StyleLabelDay"
        }

        rm setOption "MeterStyle" $style -section "LabelDay$i"
        rm setOption "Text" [lindex $dayLabels $i] -section "LabelDay$i"

    }

    set column [clock format [clock scan "$month/1/$year"] -format %u]
    if { $isStartOnMonday } {
        incr column -1
    } elseif { $column == 7 } {
        set column 0
    }

    set date [clock scan "$month/1/$year -$column days"]
    # increase the base data value by 12 hours to
    # avoid glitches the summer/winter time adjustments
    incr date [expr { 60*60*12 }]

    for { set i 0 } { $i <= 41 } { incr i } {

        lassign [clock format $date -format "%Y %N %e %d %u"] y m d dd w

        if { $y != $year || $m != $month } {

            if { ($month == 1 && $m == 12) || $month < $m } {
                set style "StyleDayPreviousMonth"
            } else {
                set style "StyleDayNextMonth"
            }

        } else {

            if { $isCurrentMonth && $y == $cyear && $m == $cmonth && $d == $cday } {
                set style "StyleDayCurrent"
            } elseif { $w in {6 7} } {
                set style "StyleDayWeekend"
            } else {
                set style "StyleDay"
            }

        }

        if { $isLeadingZeroes } {
            set d $dd
        }

        rm setOption "Text" $d -section "Day$i"
        rm setOption "MeterStyle" $style -section "Day$i"

        incr date [expr { 60*60*24 }]

    }

    rm meter update "Title"

    for { set i 0 } { $i <= 6 } { incr i } {
        rm meter update "LabelDay$i"
    }

    for { set i 0 } { $i <= 41 } { incr i } {
        rm meter update "Day$i"
    }

    rm skin redraw

}

proc move { args } {

    if { ![llength $args] || [lindex $args 0] == 0 } {
        unset -nocomplain ::year ::mouth
    } else {

        if { ![info exists ::year] } {
            lassign [clock format [clock seconds] -format "%Y %N"] ::year ::month
        }

        if { [lindex $args 0] > 0 } {

            if { [incr ::month] > 12 } {
                incr ::year
                set ::month 1
            }

        } else {

            if { [incr ::month -1] < 1 } {
                incr ::year -1
                set ::month 12
            }

        }

    }

    unset -nocomplain ::gLastRedraw

    rm measure update [rm getMeasureName]

}