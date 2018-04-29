[Variables]
showDrives=1
driveLetter1=#PROGRAMDRIVE#
driveLetter2=
driveLetter3=
driveLetter4=
driveLetter5=
driveLetter6=
driveLetter7=

showRemovable=0
showNetwork=0
showCDRom=0
showRam=0

showReadWrite=1
showGraphActivity=1

[Settings]
Measure=Script
ScriptFile=#@#Scripts\settings.lua
SettingsFile=harddrive
UpdateDivider=-1

;================================================
@IncludeGlobal=#@#variables.global.inc
@Include=#@#Settings\harddrive.inc