# Copyright (c) 2016 Nicholas Von Huben
# Released under GPLv3 (see licenses/GPLv3.txt)

include tools/makefiles/identify_host_OS.mk
include tools/makefiles/component_processing.mk


COMPONENT_NAMED_VARIABLES := SOURCES \
                             DIRECTORY \
                             MAKEFILE \
                             INCLUDES \
                             DEFINES \
                             SUPPORTED_FEATURES \
                             REQUIRED_FEATURES \
                             GENERATED_FILES \
                             ADDITIONAL_MAKEFILES \
                             ADDITIONAL_LIBRARIES \
                             DECLARED_LISTS \
                             FORCE_KEEP_SYMBOLS \
                             REQUIRED_COMPONENTS \
                             REFERENCED_COMPONENTS

BUILD_NAMED_VARIABLES := PROCESSED_COMPONENTS \
                         COMPONENT_NAMES \
                         GLOBAL_DEFINES \
                         GLOBAL_INCLUDES \
                         GLOBAL_CFLAGS \
                         GLOBAL_CXXFLAGS \
                         GLOBAL_LINKER_SCRIPT \
                         SUPPORTED_FEATURES \
                         REQUIRED_FEATURES \
                         TOOLCHAIN_COMPONENTS \
                         GENERATED_LIBRARIES \
                         REFERENCED_COMPONENTS \
                         DECLARED_LISTS

# Process component list
$(eval $(call DO_COMPONENT_PROCESSING,$(COMPONENT_LIST)))

# Appends the component related info to the provided file name
# $(1) is the component name, $(2) is the file
define LOG_COMPONENT_INFO
$(foreach var,$(COMPONENT_NAMED_VARIABLES),$(call APPEND_TO_FILE, $(2),$(1)_$(var) := $($(1)_$(var))))
endef

# build_summary rule
$(BUILD_OUTPUT_DIRECTORY)/build_summary.mk: Makefile tools/makefiles/build_summary.mk $(foreach component,$(BUILD_COMPONENT_NAMES),$($(component)_MAKEFILE)) | $(BUILD_OUTPUT_DIRECTORY)
	$(ECHO) Updated build_summary.mk because of : $?
	$(call CREATE_FILE,$@)
	$(call APPEND_TO_FILE,$@,PROJECT :=$(PROJECT))
	$(call APPEND_TO_FILE,$@,BUILD_TYPE :=$(BUILD_TYPE))
	$(foreach var,      $(BUILD_NAMED_VARIABLES), $(call APPEND_TO_FILE,$@,BUILD_$(var) :=$(BUILD_$(var))))
	$(foreach list,     $(BUILD_DECLARED_LISTS),  $(call APPEND_TO_FILE,$@,BUILD_LIST_$(list)              :=$(BUILD_LIST_$(list))) \
	                                              $(call APPEND_TO_FILE,$@,BUILD_LIST_DEPENDENCIES_$(list) :=$(BUILD_LIST_DEPENDENCIES_$(list))))
	$(foreach component,$(BUILD_COMPONENT_NAMES), $(call LOG_COMPONENT_INFO,$(component),$@))

$(BUILD_OUTPUT_DIRECTORY):
	$(call MKDIR,$@)
