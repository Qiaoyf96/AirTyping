# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.13

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.13.3/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.13.3/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/yifan/Desktop/AirTyping/tester

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/yifan/Desktop/AirTyping/tester

# Include any dependencies generated for this target.
include CMakeFiles/xlib.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/xlib.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/xlib.dir/flags.make

CMakeFiles/xlib.dir/wrapper.cpp.o: CMakeFiles/xlib.dir/flags.make
CMakeFiles/xlib.dir/wrapper.cpp.o: wrapper.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/yifan/Desktop/AirTyping/tester/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/xlib.dir/wrapper.cpp.o"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/xlib.dir/wrapper.cpp.o -c /Users/yifan/Desktop/AirTyping/tester/wrapper.cpp

CMakeFiles/xlib.dir/wrapper.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/xlib.dir/wrapper.cpp.i"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/yifan/Desktop/AirTyping/tester/wrapper.cpp > CMakeFiles/xlib.dir/wrapper.cpp.i

CMakeFiles/xlib.dir/wrapper.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/xlib.dir/wrapper.cpp.s"
	/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/yifan/Desktop/AirTyping/tester/wrapper.cpp -o CMakeFiles/xlib.dir/wrapper.cpp.s

xlib: CMakeFiles/xlib.dir/wrapper.cpp.o
xlib: CMakeFiles/xlib.dir/build.make

.PHONY : xlib

# Rule to build all files generated by this target.
CMakeFiles/xlib.dir/build: xlib

.PHONY : CMakeFiles/xlib.dir/build

CMakeFiles/xlib.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/xlib.dir/cmake_clean.cmake
.PHONY : CMakeFiles/xlib.dir/clean

CMakeFiles/xlib.dir/depend:
	cd /Users/yifan/Desktop/AirTyping/tester && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/yifan/Desktop/AirTyping/tester /Users/yifan/Desktop/AirTyping/tester /Users/yifan/Desktop/AirTyping/tester /Users/yifan/Desktop/AirTyping/tester /Users/yifan/Desktop/AirTyping/tester/CMakeFiles/xlib.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/xlib.dir/depend
