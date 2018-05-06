[Variables]
showDrives=1
driveLetter1=#PROGRAMDRIVE#

showRemovable=0
showNetwork=0
showCDRom=0
showRam=0

showReadWrite=1
showGraphActivity=1

[Settings]
Measure=Plugin
Plugin=RainmeterTcl
ScriptFile=#@#Scripts\settings.tcl
SettingsFile=harddrive
UpdateDivider=-1

;================================================
@IncludeGlobal=#@#variables.global.inc
@Include=#@#Settings\harddrive.inc