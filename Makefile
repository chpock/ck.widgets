# RainmeterTcl
# Copyright (C) 2018 Konstantin Kushnir <chpock@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

RAINMETER_BASE_SRC_DIRECTORY = /repositories/_Rainmeter/rainmeter

.PHONY: all add

all: add

add:
	rm -rf "$(RAINMETER_BASE_SRC_DIRECTORY)/Base/Skins/ck.widgets"
	cp -fr Skins/* "$(RAINMETER_BASE_SRC_DIRECTORY)/Build/Skins"
	rm -rf "$(RAINMETER_BASE_SRC_DIRECTORY)/Build/Skins/ck.widgets/@Resources/Settings"
	rm -rf "$(RAINMETER_BASE_SRC_DIRECTORY)/Build/Layouts/ck.widgets Default"
	mkdir -p "$(RAINMETER_BASE_SRC_DIRECTORY)/Build/Layouts/ck.widgets default"
	cp -fvr "@Vault/Layout/Rainmeter.ini" \
	    "$(RAINMETER_BASE_SRC_DIRECTORY)/Build/Layouts/ck.widgets default/Rainmeter.ini"
	cp -fv "@Vault/Plugins/ActiveNet/2.7.0.0/32bit/ActiveNet.dll" \
	    "$(RAINMETER_BASE_SRC_DIRECTORY)/x32-Release/Plugins"
	cp -fv "@Vault/Plugins/ActiveNet/2.7.0.0/64bit/ActiveNet.dll" \
	    "$(RAINMETER_BASE_SRC_DIRECTORY)/x64-Release/Plugins"
	cp -fv "@Vault/Plugins/HWiNFO/3.2.0.0/32bit/HWiNFO.dll" \
	    "$(RAINMETER_BASE_SRC_DIRECTORY)/x32-Release/Plugins"
	cp -fv "@Vault/Plugins/HWiNFO/3.2.0.0/64bit/HWiNFO.dll" \
	    "$(RAINMETER_BASE_SRC_DIRECTORY)/x64-Release/Plugins"
