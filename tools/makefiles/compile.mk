# Copyright (c) 2016 Nicholas Von Huben
# Released under GPLv3 (see licenses/GPLv3.txt)

include tools/makefiles/identify_host_OS.mk

# Only use one shell
.ONESHELL:

# This should be instatiated as a new Make instance with a single target, the name of the project being built
PROJECT := $(MAKECMDGOALS)

# Include global configuration and derive project specific variables
include configuration.mk
BUILD_OUTPUT_DIRECTORY := $(BUILD_OUTPUT_BASE_DIRECTORY)/$(PROJECT)
BUILD_SUMMARY_FILE     := $(BUILD_OUTPUT_DIRECTORY)/build_summary.mk

include $(BUILD_SUMMARY_FILE)

BUILD_OUTPUT_COMPONENT_DIRECTORY := $(BUILD_OUTPUT_DIRECTORY)/components
BUILD_OUTPUT_LIBRARY_DIRECTORY   := $(BUILD_OUTPUT_DIRECTORY)/libraries

# Include toolchain component makefiles
$(foreach component,$(BUILD_TOOLCHAIN_COMPONENTS),$(eval include $($(component)_MAKEFILE)))

# Include any additional component makefiles
$(foreach component,$(BUILD_COMPONENT_NAMES),$(foreach makefile,$($(component)_ADDITIONAL_MAKEFILES),$(eval include $($(component)_DIRECTORY)$(makefile))))

###################################################################################################
# GENERATE_SOURCE_COMPILATION_RULES
# Used to generate compilation rules for all the various source file types
# $(1) is the component name ('NAME' variable in relevant makefile), $(2) is the source filename (with relative directory from component location), $(3) is the file suffix, $(4) is the file type (c,cpp,s)
define GENERATE_SOURCE_COMPILATION_RULES
-include $(BUILD_OUTPUT_COMPONENT_DIRECTORY)/$($(1)_DIRECTORY)/$(2:.$(3)=.d)
$(BUILD_OUTPUT_COMPONENT_DIRECTORY)/$($(1)_DIRECTORY)/$(2:.$(3)=.o): $($(1)_DIRECTORY)/$(2) $(BUILD_SUMMARY_FILE) $(if $(1)_$(4)_COMPILE_OPTIONS_FILE,$($(1)_$(4)_COMPILE_OPTIONS_FILE)) | $(BUILD_OUTPUT_COMPONENT_DIRECTORY)/$($(1)_DIRECTORY)/$(dir $(2))/.d
	$(QUIET)$(ECHO) Compiling $(2)
	$(QUIET)$($(4)_COMPILER) $(TOOLCHAIN_OPTION_FILE_INDICATOR)$($(1)_$(4)_COMPILE_OPTIONS_FILE) -o $$@ $$<

$(eval $(1)_LIST_OF_OBJECTS += $(BUILD_OUTPUT_COMPONENT_DIRECTORY)/$($(1)_DIRECTORY)/$(2:.$(3)=.o))
endef

###################################################################################################
# GENERATE_SOURCE_COMPILE_OPTION_RULES
# Used to generate the rules to create the dependency files
# $(1) is the component name
define GENERATE_SOURCE_COMPILE_OPTION_RULES
$(eval $(1)_c_COMPILE_OPTIONS_FILE := $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/$(1).c_options)
$(eval $(1)_cpp_COMPILE_OPTIONS_FILE := $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/$(1).cpp_options)
$(eval $(1)_s_COMPILE_OPTIONS_FILE := $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/$(1).s_options)
$($(1)_c_COMPILE_OPTIONS_FILE): $(BUILD_SUMMARY_FILE) $(BUILD_OUTPUT_DIRECTORY)/$($(1)_GENERATED_FILES) | $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/.d
	$$(call CREATE_FILE, $$@,$(TOOLCHAIN_NO_LINKING_INDICATOR) $(BUILD_GLOBAL_CFLAGS) $($(1)_CFLAGS) $(addprefix -I,$(BUILD_GLOBAL_INCLUDES) $($(1)_INCLUDES)) $(addprefix -D,$(BUILD_GLOBAL_DEFINES) $($(1)_DEFINES)))

$($(1)_cpp_COMPILE_OPTIONS_FILE): $(BUILD_SUMMARY_FILE) $(BUILD_OUTPUT_DIRECTORY)/$($(1)_GENERATED_FILES) | $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/.d
	$$(call CREATE_FILE, $$@,$(TOOLCHAIN_NO_LINKING_INDICATOR) $(BUILD_GLOBAL_CXXFLAGS) $($(1)_CXXFLAGS) $(addprefix -I,$(BUILD_GLOBAL_INCLUDES) $($(1)_INCLUDES)) $(addprefix -D,$(BUILD_GLOBAL_DEFINES) $($(1)_DEFINES)))

$($(1)_s_COMPILE_OPTIONS_FILE): $(BUILD_SUMMARY_FILE) $(BUILD_OUTPUT_DIRECTORY)/$($(1)_GENERATED_FILES) | $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/.d
	$$(call CREATE_FILE, $$@,$(TOOLCHAIN_NO_LINKING_INDICATOR) $(BUILD_GLOBAL_CFLAGS) $($(1)_CFLAGS) $(addprefix -I,$(BUILD_GLOBAL_INCLUDES) $($(1)_INCLUDES)) $(addprefix -D,$(BUILD_GLOBAL_DEFINES) $($(1)_DEFINES)))

endef


###################################################################################################
# GENERATE_COMPONENT_BUILD_RULES
# Used to generate compilation rules for a component
# $(1) is the component name
define GENERATE_COMPONENT_BUILD_RULES

# Add component library to list of compiled libraries
$(eval BUILD_LIST_OF_LIBRARIES += $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/$(1).a)

# Generate source compile option rules
$(eval $(call GENERATE_SOURCE_COMPILE_OPTION_RULES,$(1)))

# Generate library archive option rule
$(eval $(1)_ARCHIVE_OPTIONS_FILE := $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/$(1).ar_options)

# Generate source compilation rules
$(foreach source_file, $(filter %.c,  $($(1)_SOURCES)), $(eval $(call GENERATE_SOURCE_COMPILATION_RULES,$(1),$(source_file),c,c)))
$(foreach source_file, $(filter %.cpp,$($(1)_SOURCES)), $(eval $(call GENERATE_SOURCE_COMPILATION_RULES,$(1),$(source_file),cpp,cpp)))
$(foreach source_file, $(filter %.cc, $($(1)_SOURCES)), $(eval $(call GENERATE_SOURCE_COMPILATION_RULES,$(1),$(source_file),cc,cpp)))
$(foreach source_file, $(filter %.s,  $($(1)_SOURCES)), $(eval $(call GENERATE_SOURCE_COMPILATION_RULES,$(1),$(source_file),s,s)))
$(foreach source_file, $(filter %.S,  $($(1)_SOURCES)), $(eval $(call GENERATE_SOURCE_COMPILATION_RULES,$(1),$(source_file),S,s)))

# Library compile option rule
$($(1)_ARCHIVE_OPTIONS_FILE): $(BUILD_SUMMARY_FILE) | $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/.d
	$(QUIET)$$(call CREATE_FILE, $$@,$$($(1)_LIST_OF_OBJECTS))
	
# Library compilation rule
$(BUILD_OUTPUT_LIBRARY_DIRECTORY)/$(1).a: $$($(1)_LIST_OF_OBJECTS) $($(1)_ARCHIVE_OPTIONS_FILE) | $(BUILD_OUTPUT_LIBRARY_DIRECTORY)/.d
	$(QUIET)$(ECHO) Creating archive: $$@
	$(QUIET)$(ARCHIVER) $(BUILD_GLOBAL_ARFLAGS) $(TOOLCHAIN_CREATE_ARCHIVE_INDICATOR) $$@ $(TOOLCHAIN_OPTION_FILE_INDICATOR)$($(1)_ARCHIVE_OPTIONS_FILE)
endef

###################################################################################################
# Directory creation rules
%/.d:
	$(QUIET)$(call MKDIR,$(dir $@))

###################################################################################################
# Generate all the rules for this build
$(foreach component,$(BUILD_COMPONENT_NAMES),$(if $($(component)_SOURCES),$(eval $(call GENERATE_COMPONENT_BUILD_RULES,$(component))),$(info $(component) has no source files)))

	
$(PROJECT): $(BUILD_LIST_OF_LIBRARIES)



