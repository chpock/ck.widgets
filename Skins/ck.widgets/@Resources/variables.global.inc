[Rainmeter]
DefaultUpdateDivider=-1

[Variables]
KBconversionFactor=1024
MBconversionFactor=(#KBconversionFactor#*#KBconversionFactor#)
GBconversionFactor=(#KBconversionFactor#*#KBconversionFactor#*#KBconversionFactor#)
KMtoMIconversionFactor=0.62137119224
MBtoINconversionFactor=0.029529983071

tempUnits=C
deg=[\176]

[SettingsGlobal]
Measure=Script
ScriptFile=#@#Scripts\settings.lua
SettingsFile=global
UpdateDivider=-1

;================================================
@Include=#@#Settings\global.inc