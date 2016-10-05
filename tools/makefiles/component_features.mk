# Copyright (c) 2016 Nicholas Von Huben
# Released under GPLv3 (see licenses/GPLv3.txt)

BUILD_FEATURE_VARIABLES := SUPPORTED_FEATURES \
                           REQUIRED_FEATURES \
                           PREFERRED_FEATURES \
                           PROVIDED_FEATURES

FEATURE_NAMED_VARIABLES := SOURCES \
                           MAKEFILE \
                           INCLUDES \
                           DEFINES \
                           GENERATED_FILES \
                           ADDITIONAL_BUILD_RULES \
                           DECLARED_LISTS \
                           FORCE_KEEP_SYMBOLS \
                           REQUIRED_COMPONENTS \
                           REFERENCED_COMPONENTS

###################################################################################################
# PROCESS_COMPONENT_FEATURES
# Processes the feature relevant variables for a given component.
# Note that this modifies the CURRENT_LIST expecting that component_processing.mk will filter out 
# unique results later
# $(1) is the component name
define PROCESS_COMPONENT_FEATURES
# Filter out features already in the global versions of each variable
$(foreach variable,$(BUILD_FEATURE_VARIABLES),$(eval NEW_$(variable) := $(filter-out $(BUILD_$(variable)),$($(1)_$(variable)))))

# Copy the settings for all of the SUPPORTED_FEATURES. We don't know which ones may be required later
$(foreach feature,$($(1)_SUPPORTED_FEATURES),$(foreach variable,$(FEATURE_NAMED_VARIABLES),$(eval BUILD_$(feature)_$(variable) += $($(1)_$(feature)_$(variable)))))

# Determine which of the new required features are already supported and add their components to the current component list 
$(eval ALREADY_SUPPORTED_NEW_FEATURES := $(filter $(BUILD_SUPPORTED_FEATURES),$(NEW_REQUIRED_FEATURES)))
$(foreach feature,$(ALREADY_SUPPORTED_NEW_FEATURES),$(eval CURRENT_LIST +=$(BUILD_$(feature)_REQUIRED_COMPONENTS)))

# Determine which of the supported features are already required and add their components to the current component list
$(eval ALREADY_REQUIRED_FEATURES := $(filter $(BUILD_REQUIRED_FEATURES),$($(1)_SUPPORTED_FEATURES)))
$(foreach feature,$(ALREADY_REQUIRED_FEATURES),$(eval CURRENT_LIST +=$($(1)_$(feature)_REQUIRED_COMPONENTS)))

# Add all the new feature variables to the global versions to prevent processing them again
$(foreach variable,$(BUILD_FEATURE_VARIABLES),$(eval BUILD_$(variable) += $(NEW_$(variable))))
endef