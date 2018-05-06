# ck.widgets
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

proc smartFormatBytes { val } {

    if { $val eq "" } {
        set val 0
    } elseif { ![string is double -strict $val] } {
        rm log -warning "[info level 0]: value is not number: $val"
        set val 0
    }

    if { $val < 1024 } {

        return "- k"

    } elseif { $val < 1048576 } { ;# 1024*1024

        return "[expr { round(1.0*$val/1024) }] k"

    } elseif { $val < 1073741824 } { ;# 1024*1024*1024

        return "[expr { round(100.0*$val/1048576) / 100.0 }] M"

    } {

        return "[expr { round(100.0*$val/1073741824) / 100.0 }] G"

    }

}

# fixedFormatBytes value ?-precision number? ?-factor string?
#
# based on FixedPrecisionFormat v4.0.0 by SilverAzide
# Arguments:
#     val        = value to be formatted
#     -precision = numeric scale
#     -factor    = scale factor ("0", "1", "1k", "2", "2k").
#                  Same as the Rainmeter String meter's "AutoScale"
#                  option:
#                      0:  Disabled (default).
#                      1:  Scales by 1024.
#                      1k: Scales by 1024 with kilo as the lowest unit.
#                      2:  Scales by 1000.
#                      2k: Scales by 1000 with kilo as the lowest unit.
#
# Examples:
#    fixedFormatBytes 3.141592654 -precision 7 -factor 1k = "0.003068 k"
#    fixedFormatBytes 3.141592654 -precision 7 -factor 1  = "3.141593 "
#    fixedFormatBytes 31.41592654 -precision 7 -factor 1  = "31.41593 "
#    fixedFormatBytes 314.1592654 -precision 7 -factor 1  = "314.1593 "
#    fixedFormatBytes 3141.592654 -precision 7 -factor 1  = "3.067962 k"
#    fixedFormatBytes 31415926.54 -precision 7 -factor 1  = "29.96056 M"
#    fixedFormatBytes 31415926.54 -precision 4 -factor 1  = "29.96 M"
#    fixedFormatBytes 31415926.54 -precision 3 -factor 1  = "30.0 M"
#    fixedFormatBytes 31415926.54 -precision 2 -factor 1  = "30 M"
#    fixedFormatBytes 31415926.54 -precision 1 -factor 1  = "30 M"
#    fixedFormatBytes 3.141592654 -precision 7 -factor 2k = "0.003142 k"
#    fixedFormatBytes 3.141592654 -precision 7 -factor 2  = "3.141593 "
#    fixedFormatBytes 31.41592654 -precision 7 -factor 2  = "31.41593 "
#    fixedFormatBytes 314.1592654 -precision 7 -factor 2  = "314.1593 "
#    fixedFormatBytes 3141.592654 -precision 7 -factor 2  = "3.141593 k"
#    fixedFormatBytes 31415926.54 -precision 7 -factor 2  = "31.41593 M"
#    fixedFormatBytes 31415926.54 -precision 4 -factor 2  = "31.42 M"
#    fixedFormatBytes 31415926.54 -precision 3 -factor 2  = "31.4 M"
#    fixedFormatBytes 31415926.54 -precision 2 -factor 2  = "31 M"
#    fixedFormatBytes 31415926.54 -precision 1 -factor 2  = "31 M"
#    fixedFormatBytes 3141.592654 -precision 7 -factor 0  = "3141.593 "
proc fixedFormatBytes { val {args {
    {0          double -allowempty false}
    {-precision integer -default 3 -allowempty false}
    {-factor    string -restrict {0 1 1k 2 2k} -default 0 -allowempty false}
}} } {

    if { $opts(-factor) in {1 1k} } {
        set div 1024.0
    } elseif { $opts(-factor) in {2 2k} } {
        set div 1000.0
    } {
        set div 1.0
    }

    set divcount 0

    if { $opts(-factor) in {1k 2k} } {
        set val [expr { 1.0 * $val / $div }]
        incr divcount
    }

    while { [expr { abs($val) }] > $div && $divcount < 9 && $div > 1.0 } {
        set val [expr { 1.0 * $val / $div }]
        incr divcount
    }

    set fs [expr { $opts(-precision) - [string length [expr { int(abs($val)) }]] }]
    if { $fs < 0 } {
        set fs 0
    }

    return [format "%.${fs}f[lindex {{ } { k} { M} { G} { T} { P} { E} { Z} { Y}} $divcount]" $val]

}
