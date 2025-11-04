## Makefile for C++ project using Boost
#
# @author Cedric "levif" Le Dillau
# @modified Aroli Marcellinus 
#
# Some notes:
# - Using ':=' instead of '=' assign the value at Makefile parsing time,
#   others are evaluated at usage time. This discards
# - Use ':set list' in Vi/Vim to show tabs (Ctrl-v-i force tab insertion)
#

# List to '.PHONY' all fake targets, those that are neither files nor folders.
# "all" and "clean" are good candidates.
.PHONY: all, clean

LIBCML_DIR = ../libCML/
LIBCML_INC_DIR = ../libCML/src
LIBCML_LIB_DIR = ../libCML/build
LIBCML_EXTERNAL_LIB_DIR = ../libCML/libs

# Base name
BASE_PROGNAME := smoothmusclesim

# Pre-processor flags to be used for includes (-I) and defines (-D) 
CPPFLAGS := -I./ -I$(LIBCML_INC_DIR) -I$(LIBCML_EXTERNAL_LIB_DIR)/sundials-5.7.0/include

# CXX to set the compiler
CXX := mpicxx

# CC to set the compiler
CC := mpicc

# CXXFLAGS is used for C++ compilation options.
#CXXFLAGS += -Wall -O0 -fpermissive -std=c++11
#CXXFLAGS += -Wall -O2 -fno-alias -fpermissive
CXXFLAGS += -Wall -Wunused-variable -std=c++11


# Make sure ONLY ONE MACRO IS USED!!!
# Use this if you want to use CiPAORdv1.0 cell model.
# Otherwise, comment it
#CXXFLAGS += -DCIPAORDV1_0
# Use this if you want to use ToR-ORd cell model.
# Otherwise, comment it
#CXXFLAGS += -DTOR_ORD
# Use this if you want to use ToR-ORd-dynCl cell model.
# Otherwise, comment it
#CXXFLAGS += -DTOR_ORD_DYNCL
# Use this if you want to use ORd-static-Brugada-Dongguk cell model.
# Otherwise, comment it
#CXXFLAGS += -DORD_STATIC_BRUGADA_DONGGUK


# The program name wiil depend on the set value above
# Make sure ONLY ONE MACRO IS USED!!!
ifeq ($(findstring -DCIPAORDV1_0,$(CXXFLAGS)), -DCIPAORDV1_0)
    PROGNAME := $(BASE_PROGNAME)_CiPAORdv1.0
else ifeq ($(findstring -DTOR_ORD_DYNCL,$(CXXFLAGS)), -DTOR_ORD_DYNCL)
    PROGNAME := $(BASE_PROGNAME)_ToR-ORd-dynCl
else ifeq ($(findstring -DTOR_ORD,$(CXXFLAGS)), -DTOR_ORD)
    PROGNAME := $(BASE_PROGNAME)_ToR-ORd
else ifeq ($(findstring -DORD_STATIC_BRUGADA_DONGGUK,$(CXXFLAGS)), -DORD_STATIC_BRUGADA_DONGGUK)
    PROGNAME := $(BASE_PROGNAME)_ORd-static-Brugada-Dongguk
else
    PROGNAME := $(BASE_PROGNAME)_Tong
endif



# LDFLAGS is used for linker (-g enables debug symbols)
LDFLAGS  += -g $(LIBCML_LIB_DIR)/libcml.a $(LIBCML_EXTERNAL_LIB_DIR)/sundials-5.7.0/lib64/libsundials_cvode.a $(LIBCML_EXTERNAL_LIB_DIR)/sundials-5.7.0/lib64/libsundials_nvecserial.a

# List the project' sources to compile or let the Makefile recognize
# them for you using 'wildcard' function.
#
SOURCES  = $(wildcard **/*.cpp) $(wildcard **/*.c) main.cpp

# List the project' headers or let the Makefile recognize
# them for you using 'wildcard' function.
#
HEADERS  = $(wildcard **/*.hpp) $(wildcard **/*.h)

# Construct the list of object files based on source files using
# simple extension substitution.
OBJECTS := $(SOURCES:%.cpp=%.o) 

#
# Now declare the dependencies rules and targets
#
# Starting with 'all' make it  becomes the default target when none 
# is specified on 'make' command line.
all : $(PROGNAME)

# Declare that the final program depends on all objects and the Makfile
$(PROGNAME) : $(OBJECTS) Makefile
	$(CXX) -o bin/$@ $(OBJECTS) $(LDFLAGS)

# Now the choice of using implicit rules or not (my choice)...
#
# Choice 1: use implicit rules and then we only need to add some dependencies
#           to each object.
#
## Tells make that each object file depends on all headers and this Makefile.
#$(OBJECTS) : $(HEADERS) Makefile
#
# Choice 2: don't use implicit rules and specify our will
%.o: %.cpp $(HEADERS) Makefile
	$(CXX) $(CXXFLAGS) $(CPPFLAGS) -c $(OUTPUT_OPTION) $<


# Simple clean-up target
# notes:
# - the '@' before 'echo' informs make to hide command invocation.
# - the '-' before 'rm' command to informs make to ignore errors.
clean :
	@echo "Clean."
	-rm -rf *.o **/*.o bin/$(PROGNAME)
