cmake_minimum_required(VERSION 3.15)

if(POLICY CMP0167)
  cmake_policy(SET CMP0167 NEW)
endif()

project(HornSpec VERSION 1.0 LANGUAGES C CXX)
set(HornSpec_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(HornSpec_VERSION_MINOR ${PROJECT_VERSION_MINOR})

if (NOT PACKAGE_VERSION)
  set(PACKAGE_VERSION
    "${HornSpec_VERSION_MAJOR}.${HornSpec_VERSION_MINOR}.${HornSpec_VERSION_PATCH}")
  if (DEFINED HornSpec_VERSION_TWEAK)
    set (PACKAGE_VERSION "${PACKAGE_VERSION}-${HornSpec_VERSION_TWEAK}")
  endif()
  set (HornSpec_VERSION_INFO ${PACKAGE_VERSION})
endif()


if (CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR )
  message (FATAL_ERROR
    "In-source builds are not allowed. Please clean your source tree and try again.")
endif()

enable_testing()
include (CTest)

# Add path for custom modules
list (APPEND CMAKE_MODULE_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake")


option (HornSpec_STATIC_EXE "Static executable." OFF)

set (CUSTOM_BOOST_ROOT "" CACHE PATH "Path to custom boost installation.")
if (CUSTOM_BOOST_ROOT)
  set (BOOST_ROOT ${CUSTOM_BOOST_ROOT})
  set (Boost_NO_SYSTEM_PATHS "ON")
endif()

# put static libraries first
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a" ${CMAKE_FIND_LIBRARY_SUFFIXES})


set (Boost_USE_STATIC_LIBS ON)
# boost_system is header-only since Boost 1.69; no compiled component needed
set (BOOST_COMPONENTS "")
if (UNIT_TESTS)
  list(APPEND BOOST_COMPONENTS unit_test_framework)
endif()
if (BOOST_COMPONENTS)
  find_package(Boost 1.71 REQUIRED COMPONENTS ${BOOST_COMPONENTS})
else()
  find_package(Boost 1.71 REQUIRED)
endif()

include(ExternalProject)
set_property(DIRECTORY PROPERTY EP_STEP_TARGETS configure build test)

set (Z3_TAG "z3-4.13.3" CACHE STRING "Z3 git tag to use")
set (Z3_REPO "https://github.com/Z3Prover/z3.git" CACHE STRING "Z3 repo")
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
  set (Z3_DEBUG "-d")
else()
  set (Z3_DEBUG "")
endif()

ExternalProject_Add(z3
  GIT_REPOSITORY  ${Z3_REPO}
  GIT_TAG ${Z3_TAG}
  BUILD_IN_SOURCE 1
  INSTALL_DIR ${CMAKE_BINARY_DIR}/run
  CONFIGURE_COMMAND env CC=${CMAKE_C_COMPILER} CXX=${CMAKE_CXX_COMPILER} CXXFLAGS=-Wno-template-body
  ./configure -p <INSTALL_DIR> -b build --staticlib ${Z3_DEBUG}
  BUILD_COMMAND make -j3 -C build
  INSTALL_COMMAND make -C build install
  COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_LIST_FILE}
  LOG_CONFIGURE 1
  LOG_INSTALL 1
  LOG_BUILD 1)

find_package(Z3 4.8.1)
if (NOT Z3_FOUND)
  ExternalProject_Get_Property (z3 INSTALL_DIR)
  set(Z3_ROOT ${INSTALL_DIR} CACHE PATH "Forced location of Z3" FORCE)
  message(WARNING "No Z3 found. Run \n\tcmake --build . && cmake ${CMAKE_SOURCE_DIR}")
  return()
else()
  set_target_properties(z3 PROPERTIES EXCLUDE_FROM_ALL ON)
  message ("Found Z3 at ${Z3_EXECUTABLE}")
  # indicate that we want z3 binary to be included in the binary distribution
  install (PROGRAMS ${Z3_EXECUTABLE} DESTINATION bin)
endif()

install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/README.md DESTINATION .)
# install all the licenses
install (FILES  ${CMAKE_CURRENT_SOURCE_DIR}/license.txt
  DESTINATION share/doc/HornSpec
  RENAME HornSpec_license.txt)

if (EXISTS z3-prefix/src/z3/LICENSE.txt)
  install (
    FILES
    ${CMAKE_CURRENT_BINARY_DIR}/z3-prefix/src/z3/LICENSE.txt
    DESTINATION share/doc/HornSpec
    RENAME z3_license.txt)
endif()

if (EXISTS ${CMAKE_CURRENT_BINARY_DIR}/z3-prefix/src/z3/build)
  file(GLOB z3py
    ${CMAKE_CURRENT_BINARY_DIR}/z3-prefix/src/z3/build/*.py?
    ${CMAKE_CURRENT_BINARY_DIR}/z3-prefix/src/z3/build/*.py?
    ${CMAKE_CURRENT_BINARY_DIR}/z3-prefix/src/z3/build/*.so
    ${CMAKE_CURRENT_BINARY_DIR}/z3-prefix/src/z3/build/*.dylib
    ${CMAKE_CURRENT_BINARY_DIR}/z3-prefix/src/z3/build/*.dll
    )
  install(FILES ${z3py} DESTINATION lib/z3py)
endif()

find_package(OpenMP)

find_package(Gmp REQUIRED)
if (NOT GMP_FOUND)
  set(GMP_LIB "")
  set(GMPXX_LIB "")
endif()

install(DIRECTORY include/
  DESTINATION include
  FILES_MATCHING
  PATTERN "*.hpp"
  PATTERN "*.hh"
  PATTERN "*.h"
  PATTERN ".svn" EXCLUDE
  )

install(DIRECTORY ${CMAKE_BINARY_DIR}/include/
  DESTINATION include
  FILES_MATCHING
  PATTERN "*.hpp"
  PATTERN "*.hh"
  PATTERN "*.h"
  PATTERN "CMakeFiles" EXCLUDE
  PATTERN ".svn" EXCLUDE
  )

set(CMAKE_CXX_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(
    -Wno-redeclared-class-member
    -Wno-sometimes-uninitialized
    -Wno-covered-switch-default
    -Wno-inconsistent-missing-override
  )
elseif (CMAKE_CXX_COMPILER_ID MATCHES "GNU")
  add_compile_options(-Wno-unused-local-typedefs)
endif()

# Collect include dirs for use by targets in subdirectories
set(HORNSPEC_INCLUDE_DIRS
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${CMAKE_CURRENT_BINARY_DIR}/include
  ${Z3_INCLUDE_DIR}
  ${GMP_INCLUDE_DIR}
  ${GMPXX_INCLUDE_DIR}
)

add_subdirectory(tools)
