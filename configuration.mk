# Copyright (c) 2016 Nicholas Von Huben
# Released under the MIT License

# Add a reference to our preferred libc implementation
BUILD_REFERENCED_COMPONENTS += libc/newlib-nano-2

# Set some BUILD variables
BUILD_OUTPUT_BASE_DIRECTORY := build

BUILD_COMPONENT_DIRECTORIES := . \
                               libraries
 
