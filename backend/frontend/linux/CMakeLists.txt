# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin tooling to malfunction if there
# is a project that does not support the higher version. Specifically, this can
# cause a failure when trying to run the application with `flutter run`.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "commcoach")
set(APPLICATION_ID "com.example.commcoach")

# Use the C++ standard defined by the Flutter Engine.
set(CMAKE_CXX_STANDARD 17)

# This value is used when generating builds using this file. It is
# referenced by the generated build system.
set(APPLICATION_ID "com.example.commcoach")

# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.example.commcoach")

# Explicitly opt in to modern CMake behaviors to avoid issues with
# CMake 3.14 and earlier.
cmake_policy(SET CMP0063 NEW)

# Define build configuration option.
get_property(IS_MULTICONFIG GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
if(IS_MULTICONFIG)
  set(CMAKE_CONFIGURATION_TYPES "Debug;Profile;Release"
      CACHE STRING "" FORCE)
else()
  set(CMAKE_BUILD_TYPE "${CMAKE_BUILD_TYPE}" CACHE STRING
      "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
      "Debug" "Profile" "Release")
endif()

# Define settings for the Profile build mode.
set(CMAKE_EXE_LINKER_FLAGS_PROFILE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")
set(CMAKE_SHARED_LINKER_FLAGS_PROFILE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}")
set(CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_RELEASE}")
set(CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_RELEASE}")
# LTO is not supported in Profile mode.
string(REPLACE "-flto" "" CMAKE_C_FLAGS_PROFILE "${CMAKE_C_FLAGS_PROFILE}")
string(REPLACE "-flto" "" CMAKE_CXX_FLAGS_PROFILE "${CMAKE_CXX_FLAGS_PROFILE}")

# Use Unicode for all projects.
add_definitions(-DUNICODE -D_UNICODE)

# Define the application target. To change its name, change APPLICATION_ID in
# the top-level CMakeLists.txt, not the value here, or `flutter run` will no
# longer work.
#
# Any new source files that you add to the application should be added here.
add_executable(${APPLICATION_ID}
  "main.cc"
  "my_application.cc"
  "generated_plugin_registrant.cc")

# Run the Flutter tool portions of the build. This must not be removed.
flutter_auto_plugin_registrant(${APPLICATION_ID})

# The generated plugin registrant will call a function that is in the
# application's main. This should be defined here.
target_link_libraries(${APPLICATION_ID} PRIVATE flutter flutter_wrapper_app)

# Application-specific packages.
target_link_libraries(${APPLICATION_ID} PRIVATE "gtk-3" "gdk-3" "glib-2.0" "gobject-2.0")
