set(sources
  module.map
  )
set(output_dir "${SWIFTLIB_DIR}/bionic")

set(commands
    COMMAND ${CMAKE_COMMAND} "-E" "make_directory" "${output_dir}")
set(outputs)
foreach(input ${sources})
  #list(APPEND commands
  #    COMMAND
  #      "${CMAKE_COMMAND}" "-E" "copy_if_different"
  #      "${CMAKE_CURRENT_SOURCE_DIR}/${input}"
  #      "${output_dir}/${input}")
  list(APPEND commands
      COMMAND
        "sed" "-e" "s@SYSROOT@${SWIFT_ANDROID_NDK_PATH}/platforms/android-16/arch-arm@g"
        "${CMAKE_CURRENT_SOURCE_DIR}/${input}"
        ">"
        "${output_dir}/${input}")
  list(APPEND outputs "${output_dir}/${input}")
endforeach()
# Put the output dir itself last so that it isn't considered the primary output.
list(APPEND outputs "${output_dir}")
add_custom_command_target(unused_var
    ${commands}
    CUSTOM_TARGET_NAME "copy_bionic_module"
    OUTPUT "${outputs}"
    DEPENDS "${sources}"
    COMMENT "Copying Bionic module to ${output_dir}")

swift_install_in_component(stdlib
    FILES ${sources}
    DESTINATION "lib/swift/bionic")

add_swift_library(swiftGlibc IS_SDK_OVERLAY
  Glibc.swift
  FILE_DEPENDS copy_bionic_module "${SWIFTLIB_DIR}/bionic"
  TARGET_SDKS ANDROID
  INSTALL_IN_COMPONENT stdlib-experimental)

# FIXME: Android: find where this belongs
set(iculibs
    "${CMAKE_SOURCE_DIR}/../libiconv-libicu-android/armeabi-v7a/libicudata.so"
    "${CMAKE_SOURCE_DIR}/../libiconv-libicu-android/armeabi-v7a/libicuuc.so"
    "${CMAKE_SOURCE_DIR}/../libiconv-libicu-android/armeabi-v7a/libicui18n.so"
)

# TODO: Android: copy this during build as well

swift_install_in_component(stdlib
    FILES ${iculibs}
    DESTINATION "lib/swift/android/armv7")
