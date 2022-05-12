################################################################################
# Copyright (C) 2020-2022 GSI Helmholtzzentrum fuer Schwerionenforschung GmbH  #
#                                                                              #
#              This software is distributed under the terms of the             #
#              GNU Lesser General Public Licence (LGPL) version 3,             #
#                  copied verbatim in the file "LICENSE"                       #
################################################################################

# Defines some variables with console color escape sequences
if(NOT WIN32 AND NOT DISABLE_COLOR)
  string(ASCII 27 Esc)
  set(CR       "${Esc}[m")
  set(CB       "${Esc}[1m")
  set(Red      "${Esc}[31m")
  set(Green    "${Esc}[32m")
  set(Yellow   "${Esc}[33m")
  set(Blue     "${Esc}[34m")
  set(Magenta  "${Esc}[35m")
  set(Cyan     "${Esc}[36m")
  set(White    "${Esc}[37m")
  set(BRed     "${Esc}[1;31m")
  set(BGreen   "${Esc}[1;32m")
  set(BYellow  "${Esc}[1;33m")
  set(BBlue    "${Esc}[1;34m")
  set(BMagenta "${Esc}[1;35m")
  set(BCyan    "${Esc}[1;36m")
  set(BWhite   "${Esc}[1;37m")
endif()

function(pad str width char out)
  cmake_parse_arguments(ARGS "" "COLOR" "" ${ARGN})
  string(LENGTH ${str} length)
  if(ARGS_COLOR)
    math(EXPR padding "${width}-(${length}-10*${ARGS_COLOR})")
  else()
    math(EXPR padding "${width}-${length}")
  endif()
  if(padding GREATER 0)
    foreach(i RANGE ${padding})
      set(str "${str}${char}")
    endforeach()
  endif()
  set(${out} ${str} PARENT_SCOPE)
endfunction()

macro(set_fairsoft_defaults)
  # Configure build types
  set(CMAKE_CONFIGURATION_TYPES "Debug" "Release" "RelWithDebInfo")
  set(_warnings "-Wshadow -Wall -Wextra -Wpedantic")
  set(CMAKE_C_FLAGS_DEBUG                "-Og -g ${_warnings}")
  set(CMAKE_C_FLAGS_RELEASE              "-O2 -DNDEBUG")
  set(CMAKE_C_FLAGS_RELWITHDEBINFO       "-O2 -g ${_warnings} -DNDEBUG")
  set(CMAKE_CXX_FLAGS_DEBUG              "-Og -g ${_warnings}")
  set(CMAKE_CXX_FLAGS_RELEASE            "-O2 -DNDEBUG")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO     "-O2 -g ${_warnings} -DNDEBUG")
  set(CMAKE_Fortran_FLAGS_DEBUG          "-Og -g ${_warnings}")
  set(CMAKE_Fortran_FLAGS_RELEASE        "-O2 -DNDEBUG")
  set(CMAKE_Fortran_FLAGS_RELWITHDEBINFO "-O2 -g ${_warnings} -DNDEBUG")
  unset(_warnings)

  # Set a default build type
  if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE RelWithDebInfo)
  endif()

  # Handle C++ standard level
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD ${PROJECT_MIN_CXX_STANDARD})
  elseif(${CMAKE_CXX_STANDARD} LESS ${PROJECT_MIN_CXX_STANDARD})
    message(FATAL_ERROR "A minimum CMAKE_CXX_STANDARD of ${PROJECT_MIN_CXX_STANDARD} is required.")
  endif()
  set(CMAKE_CXX_EXTENSIONS OFF)

  if(NOT BUILD_SHARED_LIBS)
    set(BUILD_SHARED_LIBS ON CACHE BOOL "Whether to build shared libraries or static archives")
  endif()

  # Set -fPIC as default for all library types
  if(NOT CMAKE_POSITION_INDEPENDENT_CODE)
    set(CMAKE_POSITION_INDEPENDENT_CODE ON)
  endif()

  # Generate compile_commands.json file (https://clang.llvm.org/docs/JSONCompilationDatabase.html)
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

  get_NCPUS()
endmacro()

macro(get_NCPUS)
  if(NOT NCPUS)
    if(DEFINED ENV{SLURM_CPUS_PER_TASK})
      set(NCPUS $ENV{SLURM_CPUS_PER_TASK})
      set(NCPUS_SOURCE "SLURM_CPUS_PER_TASK")
    elseif(DEFINED ENV{SLURM_JOB_CPUS_PER_NODE})
      set(NCPUS $ENV{SLURM_JOB_CPUS_PER_NODE})
      set(NCPUS_SOURCE "SLURM_JOB_CPUS_PER_NODE")
    else()
      include(ProcessorCount)
      ProcessorCount(NCPUS)
      if(NCPUS EQUAL 0)
        set(NCPUS 1)
      endif()
      set(NCPUS_SOURCE "ProcessorCount()")
    endif()
  else()
    set(NCPUS_SOURCE "Already-Set")
  endif()
endmacro()

macro(get_os_name_release)
  find_program(LSB_RELEASE_EXEC lsb_release)
  if(NOT LSB_RELEASE_EXEC)
    # message(WARNING "lsb_release not found")
    cmake_host_system_information(RESULT os_name QUERY OS_NAME)
    cmake_host_system_information(RESULT os_release QUERY OS_RELEASE)
  else()
    execute_process(COMMAND ${LSB_RELEASE_EXEC} -si
      OUTPUT_VARIABLE os_name
      OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(COMMAND ${LSB_RELEASE_EXEC} -sr
      OUTPUT_VARIABLE os_release
      OUTPUT_STRIP_TRAILING_WHITESPACE)
  endif()
endmacro()

macro(show_jenkins_info)
    if(DEFINED ENV{CHANGE_URL})
        message(STATUS " Pull / Merge Request .: $ENV{CHANGE_URL}")
    endif()
    if(DEFINED ENV{BRANCH_NAME})
        message(STATUS " BRANCH_NAME ..........: $ENV{BRANCH_NAME}")
    endif()
    if(DEFINED ENV{CHANGE_ID})
        message(STATUS " CHANGE_ID ............: $ENV{CHANGE_ID}")
    endif()
    if(DEFINED ENV{CHANGE_TARGET})
        message(STATUS " CHANGE_TARGET ........: $ENV{CHANGE_TARGET}")
    endif()
    if(DEFINED ENV{BUILD_TAG})
        message(STATUS " BUILD_TAG ............: $ENV{BUILD_TAG}")
    endif()
endmacro()

function(show_big_header header)
    message(STATUS " ")
    message(STATUS "       ${header}")
    string(LENGTH "${header}" length)
    set(str "       ")
    if(length GREATER 0)
        foreach(i RANGE 1 ${length})
            set(str "${str}=")
        endforeach()
    endif()
    message(STATUS "${str}")
    message(STATUS " ")
endfunction()

function(fairsoft_ctest_submit)
    cmake_parse_arguments(PARSE_ARGV 0 ARGS "FINAL" "" "")
    foreach(env_var IN ITEMS http_proxy HTTP_PROXY https_proxy HTTPS_PROXY)
        if("$ENV{${env_var}}" MATCHES ".*proxy.gsi[.]de.*")
            set(old_${env_var} "$ENV{${env_var}}")
            set(ENV{${env_var}})
            message(STATUS "safed ${env_var}: ${old_${env_var}}")
        endif()
    endforeach()
    if(ARGS_FINAL)
        ctest_submit(RETURN_VALUE _ctest_submit_ret_val
                     BUILD_ID cdash_build_id)
        set(cdash_build_id "${cdash_build_id}" PARENT_SCOPE)
    else()
        ctest_submit(RETURN_VALUE _ctest_submit_ret_val)
    endif()
    foreach(env_var IN ITEMS http_proxy HTTP_PROXY https_proxy HTTPS_PROXY)
        if(DEFINED old_${env_var})
            set(ENV{${env_var}} "${old_${env_var}}")
            message(STATUS "(restored ${env_var}: $ENV{${env_var}})")
        endif()
    endforeach()

    if(_ctest_submit_ret_val)
        message(WARNING " ctest_submit() failed. Continueing")
    endif()
endfunction()

function(cdash_summary)
    show_big_header("CDash Summary")
    if(cdash_build_id)
        message(STATUS " CDash Build Summary ..: "
                "${CTEST_DROP_METHOD}://${CTEST_DROP_SITE}/buildSummary.php?buildid=${cdash_build_id}")
        message(STATUS " CDash Test List ......: "
                "${CTEST_DROP_METHOD}://${CTEST_DROP_SITE}/viewTest.php?buildid=${cdash_build_id}")
    else()
        message(STATUS "  /!\\  CDash submit likely failed")
    endif()
    message(STATUS " ")
endfunction()
