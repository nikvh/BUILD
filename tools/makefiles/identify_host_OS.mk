# Copyright (c) 2016 Nicholas Von Huben
# Released under GPLv3 (see licenses/GPLv3.txt)

ifeq ($(OS),Windows_NT)
    ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
        HOST_OS := Win64
        include tools/makefiles/Windows_host.mk
    else
        ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
            HOST_OS := Win64
            include tools/makefiles/Windows_host.mk
        endif
        ifeq ($(PROCESSOR_ARCHITECTURE),x86)
            HOST_OS := Win32
            include tools/makefiles/Windows_host.mk
        endif
    endif
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
        HOST_OS := Linux
        include tools/makefiles/Linux_host.mk
    endif
    ifeq ($(UNAME_S),Darwin)
        HOST_OS := OSX
        include tools/makefiles/OSX_host.mk
    endif
    UNAME_P := $(shell uname -p)
    ifeq ($(UNAME_P),x86_64)
        HOST_OS :=$(HOST_OS)64
    endif
    ifneq ($(filter %86,$(UNAME_P)),)
        HOST_OS :=$(HOST_OS)32
    endif
    ifneq ($(filter arm%,$(UNAME_P)),)
        HOST_OS :=$(HOST_OS)_ARM
    endif
endif