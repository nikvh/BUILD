# Copyright (c) 2016 Nicholas Von Huben
# Released under GPLv3 (see licenses/GPLv3.txt)

include configuration.mk
include tools/makefiles/identify_host_OS.mk

# Reserved command line names
RESERVED_COMMAND_LINE_TARGETS := download debug  

# Parse initial set of arguments to identify required actions
COMPONENT_LIST := $(filter-out $(RESERVED_COMMAND_LINE_TARGETS), $(MAKECMDGOALS))

# Generate a default PROJECT name if none is provided
# To provide a project name from the command line, add PROJECT=<name>
ifeq ($(PROJECT),)
$(foreach word,$(MAKECMDGOALS),$(eval PROJECT:=$(PROJECT)$(notdir $(subst .,/,$(word)))-))
PROJECT :=$(PROJECT)project
endif

# Set the default BUILD_TYPE to release
BUILD_TYPE ?= release

BUILD_OUTPUT_DIRECTORY := $(BUILD_OUTPUT_BASE_DIRECTORY)/$(PROJECT)

$(MAKECMDGOALS): build

build: $(BUILD_OUTPUT_DIRECTORY)/build_summary.mk
	$(QUIET)$(MAKE) -f tools/makefiles/compile.mk -j 8 $(PROJECT)
	$(QUIET)$(MAKE) -f tools/makefiles/link_to_binary.mk $(PROJECT) BUILD_TYPE=$(BUILD_TYPE)
	$(QUIET)$(ECHO) Build complete

# Include the build_summary.mk build rule
include tools/makefiles/build_summary.mk


