; ck.widgets
; Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; Based on the win10widgets (https://github.com/tjmarkham/win10widgets) by TJ Markham (http://tjmarkham.com)

[MeasureAutoBorder]
; Shows/hides left, right, top, and bottom borders depending on widget location.
Measure=Calc
; Make skin aware of "current" screen coordinates.
IfCondition=(#AutoBorder# = 1)
IfTrueAction=[!WriteKeyValue "#CURRENTCONFIG#" AutoSelectScreen 1 "#SETTINGSPATH#Rainmeter.ini"]
; Check if widget is on left edge of screen.
IfCondition2=(#AutoBorder# = 1) && ((#CURRENTCONFIGX# = #SCREENAREAX#) || (#CURRENTCONFIGX# = #WORKAREAX#))
IfTrueAction2=[!HideMeter LeftBorder][!ShowMeter BackgroundBoxLeft][!SetOption BackgroundBoxTopLeft SolidColor #BackgroundColor#][!UpdateMeter BackgroundBoxTopLeft][!SetOption BackgroundBoxBottomLeft SolidColor #BackgroundColor#][!UpdateMeter BackgroundBoxBottomLeft]
IfFalseAction2=[!ShowMeter LeftBorder][!HideMeter BackgroundBoxLeft][!SetOption BackgroundBoxTopLeft SolidColor #BorderColor#][!UpdateMeter BackgroundBoxTopLeft][!SetOption BackgroundBoxBottomLeft SolidColor #BorderColor#][!UpdateMeter BackgroundBoxBottomLeft]
; Check if widget is on right edge of screen.
IfCondition3=(#AutoBorder# = 1) && ((#CURRENTCONFIGX# = (#SCREENAREAWIDTH#+#SCREENAREAX#-#BackgroundWidth#)) || (#CURRENTCONFIGX# = (#WORKAREAWIDTH#+#WORKAREAX#-#BackgroundWidth#)))
IfTrueAction3=[!HideMeter RightBorder][!ShowMeter BackgroundBoxRight][!SetOption BackgroundBoxTopRight SolidColor #BackgroundColor#][!UpdateMeter BackgroundBoxTopRight][!SetOption BackgroundBoxBottomRight SolidColor #BackgroundColor#][!UpdateMeter BackgroundBoxBottomRight]
IfFalseAction3=[!ShowMeter RightBorder][!HideMeter BackgroundBoxRight][!SetOption BackgroundBoxTopRight SolidColor #BorderColor#][!UpdateMeter BackgroundBoxTopRight][!SetOption BackgroundBoxBottomRight SolidColor #BorderColor#][!UpdateMeter BackgroundBoxBottomRight]
; Check if widget is on top edge of screen.
IfCondition4=(#AutoBorder# = 1) && ((#CURRENTCONFIGY# = #SCREENAREAY#) || (#CURRENTCONFIGY# = #WORKAREAY#))
IfTrueAction4=[!HideMeter TopBorder][!ShowMeterGroup BackgroundBoxTop]
IfFalseAction4=[!ShowMeter TopBorder][!HideMeterGroup BackgroundBoxTop]
; Check if widget is on bottom edge of screen.
IfCondition5=(#AutoBorder# = 1) && ((#CURRENTCONFIGY# = (#SCREENAREAHEIGHT#+#SCREENAREAY#-#BackgroundHeight#)) || (#CURRENTCONFIGY# = (#WORKAREAHEIGHT#+#WORKAREAY#-#BackgroundHeight#)))
IfTrueAction5=[!HideMeter BottomBorder][!ShowMeterGroup BackgroundBoxBottom]
IfFalseAction5=[!ShowMeter BottomBorder][!HideMeterGroup BackgroundBoxBottom]
DynamicVariables=1
UpdateDivider=1

; ------------------------------------------------------------------------
; METERS
; ------------------------------------------------------------------------

[TopBorder]
; Shows top border of background.
Meter=Image
X=0
Y=0
W=#BackgroundWidth#
H=1
SolidColor=#BorderColor#
DynamicVariables=1
Group=SkinBackground

[BottomBorder]
; Shows bottom border of background.
Meter=Image
X=0
Y=(#BackgroundHeight#-1)
W=#BackgroundWidth#
H=1
SolidColor=#BorderColor#
DynamicVariables=1
Group=SkinBackground

[LeftBorder]
; Shows left border of background.
Meter=Image
X=0
Y=1
W=1
H=(#BackgroundHeight#-2)
SolidColor=#BorderColor#
DynamicVariables=1
Group=SkinBackground

[RightBorder]
; Shows right border of background.
Meter=Image
X=(#BackgroundWidth#-1)
Y=1
W=1
H=(#BackgroundHeight#-2)
SolidColor=#BorderColor#
DynamicVariables=1
Group=SkinBackground

[BackgroundBox]
; Shows background.
Meter=Image
X=1
Y=1
W=(#BackgroundWidth#-2)
H=(#BackgroundHeight#-2)
SolidColor=#BackgroundColor#
DynamicVariables=1
Group=SkinBackground

[BackgroundBoxLeft]
; Fills in left border with background color.
Meter=Image
X=0
Y=1
W=1
H=(#BackgroundHeight#-2)
SolidColor=#BackgroundColor#
DynamicVariables=1
Group=SkinBackground

[BackgroundBoxRight]
; Fills in right border with background color.
Meter=Image
X=(#BackgroundWidth#-1)
Y=1
W=1
H=(#BackgroundHeight#-2)
SolidColor=#BackgroundColor#
DynamicVariables=1
Group=SkinBackground

[BackgroundBoxTopMiddle]
; Fills in top border with background color.
Meter=Image
X=1
Y=0
W=(#BackgroundWidth#-2)
H=1
SolidColor=#BackgroundColor#
DynamicVariables=1
Group=BackgroundBoxTop | SkinBackground

[BackgroundBoxTopLeft]
; Adds left border to [BackgroundBoxTopMiddle]
Meter=Image
X=0
Y=0
W=1
H=1
SolidColor=#BorderColor#
DynamicVariables=1
Group=BackgroundBoxTop | SkinBackground

[BackgroundBoxTopRight]
; Adds right border to [BackgroundBoxTopMiddle]
Meter=Image
X=(#BackgroundWidth#-1)
Y=0
W=1
H=1
SolidColor=#BorderColor#
DynamicVariables=1
Group=BackgroundBoxTop | SkinBackground

[BackgroundBoxBottomMiddle]
; Fills in bottom border with background color.
Meter=Image
X=1
Y=(#backgroundHeight#-1)
W=(#BackgroundWidth#-2)
H=1
SolidColor=#BackgroundColor#
DynamicVariables=1
Group=BackgroundBoxBottom | SkinBackground

[BackgroundBoxBottomLeft]
; Adds left border to [BackgroundBoxBottomMiddle]
Meter=Image
X=0
Y=(#backgroundHeight#-1)
W=1
H=1
SolidColor=#BorderColor#
DynamicVariables=1
Group=BackgroundBoxBottom | SkinBackground

[BackgroundBoxBottomRight]
; Adds right border to [BackgroundBoxBottomMiddle]
Meter=Image
X=(#BackgroundWidth#-1)
Y=(#backgroundHeight#-1)
W=1
H=1
SolidColor=#BorderColor#
DynamicVariables=1
Group=BackgroundBoxBottom | SkinBackground

