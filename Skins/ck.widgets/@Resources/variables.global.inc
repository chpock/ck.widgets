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
Measure=Plugin
Plugin=RainmeterTcl
ScriptFile=#@#Scripts\settings.tcl
SettingsFile=global
UpdateDivider=-1

;================================================
@Include=#@#Settings\global.inc