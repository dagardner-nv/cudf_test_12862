# SPDX-FileCopyrightText: Copyright (c) 2018-2023, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


cmake_minimum_required(VERSION 3.14 FATAL_ERROR)


list(APPEND CMAKE_MESSAGE_CONTEXT "cudf_test_12862")

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_INSTALL_RPATH "$ORIGIN")
set(RAPIDS_VERSION "22.10")
set(RAPIDS_CMAKE_VERSION "22.10" CACHE STRING "Version of rapids-cmake to use")


# Prepend path and prefix updates so they take priority in this scope.
list(PREPEND CMAKE_MODULE_PATH "${CMAKE_BINARY_DIR}")
list(PREPEND CMAKE_PREFIX_PATH "${CMAKE_BINARY_DIR}")

set(Python3_FIND_VIRTUALENV "FIRST")
set(Python3_FIND_STRATEGY "LOCATION")

find_package(Python3 REQUIRED
  COMPONENTS Development Development.Module Development.Embed Interpreter NumPy
)

if(NOT EXISTS ${CMAKE_BINARY_DIR}/cudf_test_12862_RAPIDS.cmake)
   message(STATUS "Downloading RAPIDS CMake Version: ${RAPIDS_CMAKE_VERSION}")
   file(
      DOWNLOAD https://raw.githubusercontent.com/rapidsai/rapids-cmake/branch-${RAPIDS_CMAKE_VERSION}/RAPIDS.cmake
      ${CMAKE_BINARY_DIR}/cudf_test_12862_RAPIDS.cmake
   )
endif()

# Now load the file
include(${CMAKE_BINARY_DIR}/cudf_test_12862_RAPIDS.cmake)

# Load Rapids Cmake packages
include(rapids-cmake)
include(rapids-cpm)
include(rapids-cuda)
include(rapids-export)
include(rapids-find)

rapids_cmake_build_type(Debug)

set(CMAKE_CUDA_ARCHITECTURES "native")
rapids_cuda_init_architectures(cudf_test_12862)

# Project definition
project(cudf_test_12862
    VERSION 23.01.00
    LANGUAGES C CXX CUDA)

rapids_cpm_init()

set(PYBIND11_VERSION "2.8.1" CACHE STRING "Version of Pybind11 to use")

# Needs a patch to change the internal tracker to use fiber specific storage instead of TSS
rapids_cpm_find(pybind11 ${PYBIND11_VERSION}
  GLOBAL_TARGETS
    pybind11 pybind11::pybind11
  BUILD_EXPORT_SET
    ${PROJECT_NAME}-core-exports
  INSTALL_EXPORT_SET
    ${PROJECT_NAME}-core-exports
  CPM_ARGS
    GIT_REPOSITORY  https://github.com/pybind/pybind11.git
    GIT_TAG         "v${PYBIND11_VERSION}"
    GIT_SHALLOW     TRUE
    OPTIONS         "PYBIND11_INSTALL ON"
                    "PYBIND11_TEST OFF"
)

find_package(pybind11 REQUIRED)

if (NOT EXISTS ${Python3_SITELIB}/skbuild)
# In case this is messed up by `/usr/local/python/site-packages` vs `/usr/python/site-packages`, check pip itself.
execute_process(
    COMMAND bash "-c" "${Python3_EXECUTABLE} -m pip show scikit-build | sed -n -e 's/Location: //p'"
    OUTPUT_VARIABLE PYTHON_SITE_PACKAGES
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

if (NOT EXISTS ${PYTHON_SITE_PACKAGES}/skbuild)
  message(SEND_ERROR "Scikit-build is not installed. CMake may not be able to find Cython. Install scikit-build with `pip install scikit-build`")
else()
  list(APPEND CMAKE_MODULE_PATH "${PYTHON_SITE_PACKAGES}/skbuild/resources/cmake")
endif()
else ()
list(APPEND CMAKE_MODULE_PATH "${Python3_SITELIB}/skbuild/resources/cmake")
endif ()


set(CYTHON_FLAGS
"--directive binding=True,boundscheck=False,wraparound=False,embedsignature=True,always_allow_keywords=True"
CACHE STRING "The directives for Cython compilation.")

find_package(Cython REQUIRED)

message(STATUS "Python3_FOUND: " ${Python3_FOUND})
message(STATUS "Python3_EXECUTABLE: ${Python3_EXECUTABLE}")
message(STATUS "Python3_INTERPRETER_ID: " ${Python3_INTERPRETER_ID})
message(STATUS "Python3_STDLIB: " ${Python3_STDLIB})
message(STATUS "Python3_STDARCH: " ${Python3_STDARCH})
message(STATUS "Python3_SITELIB: " ${Python3_SITELIB})
message(STATUS "Python3_SITEARCH: " ${Python3_SITEARCH})
message(STATUS "Python3_SOABI: " ${Python3_SOABI})
message(STATUS "Python3_INCLUDE_DIRS: " ${Python3_INCLUDE_DIRS})
message(STATUS "Python3_LIBRARIES: " ${Python3_LIBRARIES})
message(STATUS "Python3_LIBRARY_DIRS: " ${Python3_LIBRARY_DIRS})
message(STATUS "Python3_VERSION: " ${Python3_VERSION})
message(STATUS "Python3_NumPy_FOUND: " ${Python3_NumPy_FOUND})
message(STATUS "Python3_NumPy_INCLUDE_DIRS: " ${Python3_NumPy_INCLUDE_DIRS})
message(STATUS "Python3_NumPy_VERSION: " ${Python3_NumPy_VERSION})

set(CUDF_VERSION "${RAPIDS_VERSION}" CACHE STRING "Which version of cuDF to use")

rapids_find_package(cudf ${CUDF_VERSION} REQUIRED
  GLOBAL_TARGETS
    cudf cudf::cudf
  BUILD_EXPORT_SET
    ${PROJECT_NAME}-exports
  INSTALL_EXPORT_SET
    ${PROJECT_NAME}-exports
)

add_library(test_lib
  SHARED
  test_lib.cpp
)

target_link_libraries(test_lib
  PUBLIC
    cudf::cudf
)

install(
    TARGETS
      test_lib
)

add_cython_target(cudf_helpers "cudf_helpers.pyx" CXX PY3)
add_library(cudf_helpers SHARED ${cudf_helpers})

set_target_properties(cudf_helpers PROPERTIES PREFIX "")
set_target_properties(cudf_helpers PROPERTIES OUTPUT_NAME "cudf_helpers")

target_link_libraries(cudf_helpers 
  PUBLIC 
    cudf::cudf
    pybind11::embed
)

target_include_directories(cudf_helpers 
  PUBLIC
    ${Python3_INCLUDE_DIRS}
    ${Python3_NumPy_INCLUDE_DIRS})

install(
  TARGETS 
  cudf_helpers
)

add_executable(test_cudf
  main.cpp
)

target_link_libraries(test_cudf
  PRIVATE
    test_lib
    cudf_helpers
    pybind11::embed
)

install(
    TARGETS
      test_cudf
)

list(POP_BACK CMAKE_MESSAGE_CONTEXT)
