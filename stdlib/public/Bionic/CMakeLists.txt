# FIXME: With a little CMake work, this Bionic directory could be combined
#        with the Glibc directory. It would require the modulemap for Android
#        to be copied to an Android-specific location, to prevent it from
#        overwriting the Linux modulemap.

set(sources
  Glibc.swift
  Misc.c
)

set(output_dir "${SWIFTLIB_DIR}/bionic")

add_custom_command_target(unused_var
    COMMAND
      "${CMAKE_COMMAND}" "-E" "make_directory" "${output_dir}"
    COMMAND
      "sed" "-e" "s@GLIBC_INCLUDE_PATH@${SWIFT_ANDROID_SDK_PATH}/usr/include@g"
      "${CMAKE_CURRENT_SOURCE_DIR}/module.map"
      ">"
      "${output_dir}/module.map"
    CUSTOM_TARGET_NAME "copy_bionic_module"
    OUTPUT "${output_dir}/module.map" "${output_dir}"
    DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/module.map"
    COMMENT "Copying Bionic module to ${output_dir}")

swift_install_in_component(stdlib
    FILES "${output_dir}/module.map"
    DESTINATION "lib/swift/bionic")

add_swift_library(swiftGlibc IS_SDK_OVERLAY
  ${sources}
  FILE_DEPENDS copy_bionic_module "${output_dir}"
  TARGET_SDKS ANDROID
  INSTALL_IN_COMPONENT stdlib-experimental)
