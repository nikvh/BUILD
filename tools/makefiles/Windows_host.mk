# Copyright (c) 2016 Nicholas Von Huben
# Released under GPLv3 (see licenses/GPLv3.txt)

HOST_EXECUTABLE_SUFFIX  := .exe

SLASH_QUOTE_START :="\"
SLASH_QUOTE_END   :=\""

ESC_QUOTE :="
ESC_SPACE :=$(SPACE)

ECHO            :=echo
QUOTES_FOR_ECHO :=

MAKE     := make
CAT      :=type
TOUCH    :=$(ECHO) >
DEV_NULL :=nul
QUIET    :=@

# $(1) is the directory name
define MKDIR
mkdir -p $(1)

endef

# $(1) is the content, $(2) is the file to print to.
define PRINT
@$(ECHO) $(1)>>$(2)

endef

CREATE_FILE    =$(file >$(1),$(2))
APPEND_TO_FILE =$(file >>$(1),$(2))

