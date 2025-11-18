# cleanup-build-dir.cmake
# Cross-platform script to cleanup build directories and report space savings
# Expected variables: PACKAGE_NAME, BUILD_DIR (passed via -D flags)

if(NOT DEFINED PACKAGE_NAME OR NOT DEFINED BUILD_DIR)
  message(FATAL_ERROR "PACKAGE_NAME and BUILD_DIR must be defined")
endif()

# Attempt to measure directory size (Unix-like systems only)
if(UNIX)
  find_program(DU_EXECUTABLE du)
  if(DU_EXECUTABLE)
    execute_process(
      COMMAND ${DU_EXECUTABLE} -sk "${BUILD_DIR}"
      OUTPUT_VARIABLE du_output
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(du_output)
      string(REGEX REPLACE "^([0-9]+).*" "\\1" size_kb "${du_output}")
      math(EXPR size_mb "${size_kb} / 1024")
      message(STATUS "[${PACKAGE_NAME}] Reclaiming approximately ${size_mb} MB from build directory...")
      set(size_measured TRUE)
    endif()
  endif()
endif()

# Fallback message if size couldn't be measured
if(NOT size_measured)
  message(STATUS "[${PACKAGE_NAME}] Cleaning build directory to save disk space...")
endif()

# Remove the build directory using portable CMake command
execute_process(
  COMMAND ${CMAKE_COMMAND} -E rm -rf "${BUILD_DIR}"
  RESULT_VARIABLE rm_result
)

# Report result
if(rm_result EQUAL 0)
  if(size_measured)
    message(STATUS "[${PACKAGE_NAME}] Successfully reclaimed approximately ${size_mb} MB")
  else()
    message(STATUS "[${PACKAGE_NAME}] Successfully cleaned build directory")
  endif()
else()
  message(WARNING "[${PACKAGE_NAME}] Failed to remove build directory")
endif()
