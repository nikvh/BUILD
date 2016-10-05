# Copyright (c) 2016 Nicholas Von Huben
# Released under GPLv3 (see licenses/GPLv3.txt)

-include configuration.mk

include tools/makefiles/component_features.mk

BUILD_GLOBAL_VARIABLES := INCLUDES \
                          DEFINES \
                          CFLAGS \
                          CXXFLAGS \
                          ASMFLAGS \
                          LDFLAGS \
                          LINKER_SCRIPT


                          
# Separate target string into components
BUILD_COMPONENTS := $(subst -, ,$(MAKECMDGOALS))


###################################################################################################
# DO_COMPONENT_PROCESSING
# The entry point for component processing.
# $(1) is the list of components that will grow during the call to PROCESS_COMPONENT_LIST
define DO_COMPONENT_PROCESSING
# Do any pre-processing activity. Currently none.

# Process the component list. Note: This calls itself recursively
$(eval $(call PROCESS_COMPONENT_LIST,$(1)))

# Do post-processing activities.
$(eval $(call PROCESS_REFERENCED_COMPONENT_LIST))
$(eval $(call PROCESS_DECLARED_LISTS))

endef


###################################################################################################
# FIND_COMPONENT_MAKEFILE
# Try find a component by its dot-notation name.
# This will generate: COMPONENT_DIRECTORY, COMPONENT_NAME and COMPONENT_MAKEFILE
# $(1) is the component in dot-notation
define FIND_COMPONENT_MAKEFILE
# Convert dot notation to component directory and component name
$(eval COMPONENT_DIRECTORY =$(subst .,/,$(strip $(1))))
$(eval COMPONENT_NAME      =$(notdir $(COMPONENT_DIRECTORY)))

# Find component
$(eval COMPONENT_MAKEFILE :=$(strip $(wildcard $(foreach directory, $(BUILD_COMPONENT_DIRECTORIES), $(directory)/$(COMPONENT_DIRECTORY)/$(COMPONENT_NAME).mk))))

# Verify component exists
$(if $(COMPONENT_MAKEFILE),,$(error Cannot find component $(1) makefile))
endef 

###################################################################################################
# PROCESS_COMPONENT_LIST
# Recursively processes a list of components stored in dot notation. 
# $(1) is the list of components that can grow while processing individual components
define PROCESS_COMPONENT_LIST
$(eval CURRENT_LIST :=$(1))

# Process the first component. Note that this should create the NAME variable
$(eval FIRST_COMPONENT := $(firstword $(1)) )
$(call PROCESS_COMPONENT_MAKEFILE, $(FIRST_COMPONENT))

# Add component to processed list
$(eval BUILD_PROCESSED_COMPONENTS += $(FIRST_COMPONENT))

# Add each new dependency to the list filtering out already processed ones
$(eval CURRENT_LIST :=$(strip $(filter-out $(BUILD_PROCESSED_COMPONENTS),$(CURRENT_LIST) $($(NAME)_REQUIRED_COMPONENTS))))

# If there are more entries in the list, continue recursion otherwise process the referenced components
$(if $(CURRENT_LIST),$(eval $(call PROCESS_COMPONENT_LIST,$(CURRENT_LIST))))
endef


###################################################################################################
# PROCESS_COMPONENT_MAKEFILE
# Processes an individual component accepted as an argument in dot notation
# $(1) is component name in dot-notation
define PROCESS_COMPONENT_MAKEFILE
# Find component makefile
$(eval $(call FIND_COMPONENT_MAKEFILE,$(1)))

# Parse component makefile
# It is assumed that the component will define NAME
$(eval CURDIR := $(dir $(COMPONENT_MAKEFILE)))
$(eval include $(COMPONENT_MAKEFILE) )

# Create additional component variables
$(eval $(NAME)_DIRECTORY := $(dir $(COMPONENT_MAKEFILE)))
$(eval $(NAME)_MAKEFILE  := $(COMPONENT_MAKEFILE))
$(eval $(NAME)_INCLUDES  := $(addprefix $($(NAME)_DIRECTORY), $($(NAME)_INCLUDES)))

# Add new component GLOBAL variables to BUILD GLOBAL variables
$(eval $(NAME)_GLOBAL_INCLUDES := $(addprefix $($(NAME)_DIRECTORY),$($(NAME)_GLOBAL_INCLUDES)))
$(eval $(NAME)_GLOBAL_LINKER_SCRIPT := $(addprefix $($(NAME)_DIRECTORY),$($(NAME)_GLOBAL_LINKER_SCRIPT)))
$(foreach var,$(BUILD_GLOBAL_VARIABLES),$(eval BUILD_GLOBAL_$(var) +=$($(NAME)_GLOBAL_$(var))))

# Process special BUILD variables
$(if $(filter BUILD_TOOLCHAIN,$($(NAME)_SUPPORTED_FEATURES)),$(eval BUILD_TOOLCHAIN_COMPONENTS += $(NAME)))
$(if $($(NAME)_SOURCES),$(eval BUILD_GENERATED_LIBRARIES += $(NAME).a))
$(eval BUILD_REFERENCED_COMPONENTS += $($(NAME)_REFERENCED_COMPONENTS))
$(eval BUILD_DECLARED_LISTS += $($(NAME)_DECLARED_LISTS))

# Process component features
$(eval $(call PROCESS_COMPONENT_FEATURES,$(NAME)))

# Add component name to the list
$(eval BUILD_COMPONENT_NAMES +=$(NAME))
endef


###################################################################################################
# PROCESS_REFERENCED_COMPONENT
# Extract the GLOBAL_INCLUDES of a specific component  
# $(1) is the referenced component
define PROCESS_REFERENCED_COMPONENT
# Find component makefile
$(eval $(call FIND_COMPONENT_MAKEFILE,$(1)))

# Parse component makefile
# It is assumed that the component will define NAME
$(eval include $(COMPONENT_MAKEFILE) )

# Add new GLOBAL_INCLUDES to BUILD variable
$(eval BUILD_GLOBAL_INCLUDES += $(addprefix $(dir $(COMPONENT_MAKEFILE)),$($(NAME)_GLOBAL_INCLUDES)))
endef

###################################################################################################
# PROCESS_REFERENCED_COMPONENT_LIST
# Iterate through the list of referenced components analyzing only those not already processed as 
# required components and extract the GLOBAL_INCLUDES
# This macro doesn't take arguments
define PROCESS_REFERENCED_COMPONENT_LIST
# Filter out any components already processed and remove duplicates
$(eval BUILD_REFERENCED_COMPONENTS := $(sort $(filter-out $(BUILD_PROCESSED_COMPONENTS),$(BUILD_REFERENCED_COMPONENTS))))
$(info Referenced components: $(BUILD_REFERENCED_COMPONENTS))
# Iterate through the list and process
$(foreach component,$(BUILD_REFERENCED_COMPONENTS),$(eval $(call PROCESS_REFERENCED_COMPONENT,$(component)))) 
endef

###################################################################################################
# PROCESS_DECLARED_LISTS
# Iterate through the list of declared lists collating all the component entries into a single 
# variable for each list
# This macro doesn't take arguments
define PROCESS_DECLARED_LISTS
$(foreach list,$(BUILD_DECLARED_LISTS),$(foreach component, $(BUILD_PROCESSED_COMPONENTS),$(if $($(component)_$(list)_LIST),\
     $(eval BUILD_LIST_$(list) += $($(component)_$(list)_LIST)) \
     $(eval BUILD_LIST_DEPENDENCIES_$(list) += $($(component)_MAKEFILE)))))
endef
