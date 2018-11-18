; ck.widgets
; Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; Code for Windows color based on the win10widgets (https://github.com/tjmarkham/win10widgets) by TJ Markham (http://tjmarkham.com)

[Variables]
; colors
BackgroundColor=24,24,24,217
BorderColor=100,100,100,100

SolidWhite=#ColorClouds#
SolidGreyText=#ColorConcrete#

; Flat UI Color Palette - https://www.webnots.com/flat-ui-color-codes/
ColorTurquoise=1abc9c
ColorEmerland=2ecc71
ColorPeterriver=3498db
ColorAmethyst=9b59b6
ColorWetasphalt=34495e
ColorGreensea=16a085
ColorNephritis=27ae60
ColorBelizehole=2980b9
ColorWisteria=8e44ad
ColorMidnightblue=2c3e50
ColorSunflower=f1c40f
ColorCarrot=e67e22
ColorAlizarin=e74c3c
ColorClouds=ecf0f1
ColorConcrete=95a5a6
ColorOrange=f39c12
ColorPumpkin=d35400
ColorPomegranate=c0392b
ColorSilver=bdc3c7
ColorAsbestos=7f8c8d

;ColorLime=a4c400
;ColorGreen=60a917
;ColorEmerald=008a00
;ColorTeal=00aba9
;ColorCyan=1ba1e2
;ColorCobalt=0050ef
;ColorIndigo=6a00ff
;ColorViolet=aa00ff
;ColorPink=f472d0
;ColorMagenta=d80073
;ColorCrimson=a20025
;ColorRed=e51400
;ColorOrange=fa6800
;ColorAmber=f0a30a
;ColorYellow=e3c800
;ColorBrown=825a2c
;ColorOlive=6d8764
;ColorSteel=647687
;ColorMauve=76608a
;ColorSienna=a0522d

WindowsColor=[MeasureWindowsColor]
WindowsColorText=[MeasureWindowsColorText]
WindowsColorDark=[MeasureWindowsColorDark]

; other
BackgroundWidth=212
BackgroundHeight=212

[StyleBigText]
H=67
AntiAlias=1
FontFace=Segoe UI Light
FontSize=35
FontColor=#SolidWhite#
StringAlign=Left
ClipString=1

[StyleMediumText]
H=35
AntiAlias=1
FontFace=Segoe UI
FontSize=18
FontColor=#SolidWhite#
StringAlign=Left
ClipString=1

[StyleSmallText]
H=21
AntiAlias=1
FontFace=Segoe UI
FontSize=11
FontColor=#SolidGreyText#
StringAlign=Left
ClipString=1

[StyleTinyText]
H=14
AntiAlias=1
FontFace=Segoe UI
FontSize=9
FontColor=#SolidGreyText#
StringAlign=Left
ClipString=1

[StyleWindowsColorText]
FontColor=[MeasureWindowsColor]
Group=WindowsColorGroup
; required for #WindowsColor# in BarColor property
DynamicVariables=1

[MeasurePaletteRegistry]
; Returns Windows accent palette.
Measure=Registry
RegHKey=HKEY_CURRENT_USER
RegKey=Software\Microsoft\Windows\CurrentVersion\Explorer\Accent
RegValue=AccentPalette
IfCondition=1
IfTrueAction=[!UpdateMeasure MeasureWindowsColor][!UpdateMeasure MeasureWindowsColorText][!UpdateMeasure MeasureWindowsColorDark]
OnChangeAction=[!UpdateMeasure MeasureWindowsColor][!UpdateMeasure MeasureWindowsColorText][!UpdateMeasure MeasureWindowsColorDark]
UpdateDivider=10

; Palette options:
; "\1\2\3"
; "\5\6\7"
; "\9\10\11"	Windows accent color for text
; "\13\14\15"	Primary Windows accent color
; "\17\18\19"
; "\21\22\23"	Taskbar color (when it's not black)
; "\25\26\27"	Text input color
; "\29\30\31"

[MeasureWindowsColorText]
; Returns Windows accent color for text.
Measure=String
String=[MeasurePaletteRegistry]
DynamicVariables=1
RegExpSubstitute=1
Substitute="([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2}).*":"\9\10\11"
OnChangeAction=[!UpdateMeterGroup WindowsTextColorGroup]

[MeasureWindowsColorDark]
; Returns dark Windows accent color.
Measure=String
String=[MeasurePaletteRegistry]
DynamicVariables=1
RegExpSubstitute=1
Substitute="([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2}).*":"\25\26\27"
OnChangeAction=[!UpdateMeterGroup WindowsDarkColorGroup]

[MeasureWindowsColor]
; Returns primary Windows accent color.
Measure=String
String=[MeasurePaletteRegistry]
DynamicVariables=1
RegExpSubstitute=1
Substitute="([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2}).*":"\13\14\15"
OnChangeAction=[!UpdateMeterGroup WindowsColorGroup]

; ---

[Template:GraphPlaceHolder]
Meter=Image
Y=0
X=0
W=0
H=0
Group=Graph#^#

[Template:GraphTop]
Meter=Image
X=0R
Y=0R
W=#BackgroundWidth#
H=1
SolidColor=0000FF
Group=Graph#^#

[Template:GraphLeft]
Meter=Image
MeterStyle=GraphTop#^#
X=[GraphTop#^#:X]
Y=[GraphTop#^#:Y]
W=1
H=20
Group=Graph#^#

[Template:GraphRight]
Meter=Image
MeterStyle=GraphTop#^#
X=([GraphTop#^#:X]+[GraphTop#^#:W])
Y=[GraphTop#^#:Y]
W=1
H=[GraphLeft#^#:H]
Group=Graph#^#

[Template:GraphBottom]
Meter=Image
MeterStyle=GraphTop#^#
X=[GraphTop#^#:X]
Y=([GraphTop#^#:Y]+[GraphLeft#^#:H]-1)
W=[GraphTop#^#:W]
H=1
Group=Graph#^#

[Template:GraphValue]
Meter=Line
AntiAlias=1
LineWidth=1
LineCount=1
X=([GraphTop#^#:X]+1)
Y=([GraphTop#^#:Y]+2)
W=([GraphTop#^#:W]-2)
H=([GraphLeft#^#:H]-2)
Group=Graph#^#
UpdateDivider=1

[Template:GraphBackground]
Meter=Histogram
AntiAlias=1
Y=([GraphValue#^#:Y]-1)
X=[GraphValue#^#:X]
W=[GraphValue#^#:W]
H=([GraphValue#^#:H]+1)
; required for values
DynamicVariables=1
Group=Graph#^#
UpdateDivider=1
