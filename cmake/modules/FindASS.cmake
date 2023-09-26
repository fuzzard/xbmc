#.rst:
# FindASS
# -------
# Finds the ASS library
#
# This will define the following target:
#
#   ASS::ASS   - The ASS library
#

# Get all propreties that cmake supports
execute_process(COMMAND cmake --help-property-list OUTPUT_VARIABLE CMAKE_PROPERTY_LIST)

# Convert command output into a CMake list
STRING(REGEX REPLACE ";" "\\\\;" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")
STRING(REGEX REPLACE "\n" ";" CMAKE_PROPERTY_LIST "${CMAKE_PROPERTY_LIST}")
# Fix https://stackoverflow.com/questions/32197663/how-can-i-remove-the-the-location-property-may-not-be-read-from-target-error-i
#list(FILTER CMAKE_PROPERTY_LIST EXCLUDE REGEX "^LOCATION$|^LOCATION_|_LOCATION$")
# For some reason, "TYPE" shows up twice - others might too?
list(REMOVE_DUPLICATES CMAKE_PROPERTY_LIST)

# build whitelist by filtering down from CMAKE_PROPERTY_LIST in case cmake is
# a different version, and one of our hardcoded whitelisted properties
# doesn't exist!
unset(CMAKE_WHITELISTED_PROPERTY_LIST)
foreach(prop ${CMAKE_PROPERTY_LIST})
#    if(prop MATCHES "^(INTERFACE|[_a-z]|IMPORTED_LIBNAME_|MAP_IMPORTED_CONFIG_)|^(COMPATIBLE_INTERFACE_(BOOL|NUMBER_MAX|NUMBER_MIN|STRING)|EXPORT_NAME|IMPORTED(_GLOBAL|_CONFIGURATIONS|_LIBNAME)?|NAME|TYPE|NO_SYSTEM_FROM_IMPORTED)$")
        list(APPEND CMAKE_WHITELISTED_PROPERTY_LIST ${prop})
#    endif()
endforeach(prop)

function(print_properties)
    message ("CMAKE_PROPERTY_LIST = ${CMAKE_PROPERTY_LIST}")
endfunction(print_properties)

function(print_whitelisted_properties)
    message ("CMAKE_WHITELISTED_PROPERTY_LIST = ${CMAKE_WHITELISTED_PROPERTY_LIST}")
endfunction(print_whitelisted_properties)

function(print_target_properties tgt)
    if(NOT TARGET ${tgt})
      message("There is no target named '${tgt}'")
      return()
    endif()

    get_target_property(target_type ${tgt} TYPE)
    if(target_type STREQUAL "INTERFACE_LIBRARY")
        set(PROP_LIST ${CMAKE_WHITELISTED_PROPERTY_LIST})
    else()
        set(PROP_LIST ${CMAKE_PROPERTY_LIST})
    endif()

    foreach (prop ${PROP_LIST})
        string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${prop})
        # message ("Checking ${prop}")
        get_property(propval TARGET ${tgt} PROPERTY ${prop} SET)
        if (propval)
            get_target_property(propval ${tgt} ${prop})
            message ("${tgt} ${prop} = ${propval}")
        endif()
    endforeach(prop)
endfunction(print_target_properties)


if(NOT TARGET ASS::ASS)
  find_package(PkgConfig)
  # Do not use pkgconfig on windows
  if(PKG_CONFIG_FOUND AND NOT WIN32)
message(WARNING "CMAKE_FIND_ROOT_PATH: ${CMAKE_FIND_ROOT_PATH}")

    pkg_check_modules(PC_ASS libass QUIET IMPORTED_TARGET)
    # INTERFACE_LINK_OPTIONS is incorrectly populated when cmake generation is executed
    # when an existing build generation is already done. Just set this to blank
    set_target_properties(PkgConfig::PC_ASS PROPERTIES INTERFACE_LINK_OPTIONS "")

    set(ASS_VERSION ${PC_ASS_VERSION})
print_target_properties(PkgConfig::PC_ASS)
  elseif(WIN32)
    find_package(libass CONFIG QUIET REQUIRED
                        HINTS ${DEPENDS_PATH}/lib/cmake
                        ${${CORE_PLATFORM_NAME_LC}_SEARCH_CONFIG})
    set(ASS_VERSION ${libass_VERSION})
  endif()

  find_path(ASS_INCLUDE_DIR NAMES ass/ass.h
                            HINTS ${DEPENDS_PATH}/include ${PC_ASS_INCLUDEDIR}
                            ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                            NO_CACHE)
  find_library(ASS_LIBRARY NAMES ass libass
                           HINTS ${DEPENDS_PATH}/lib ${PC_ASS_LIBDIR}
                           ${${CORE_PLATFORM_LC}_SEARCH_CONFIG}
                           NO_CACHE)

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(ASS
                                    REQUIRED_VARS ASS_LIBRARY ASS_INCLUDE_DIR
                                    VERSION_VAR ASS_VERSION)

  if(ASS_FOUND)
    if(TARGET PkgConfig::PC_ASS)
      add_library(ASS::ASS ALIAS PkgConfig::PC_ASS)
    elseif(TARGET libass::libass)
      # Kodi custom libass target used for windows platforms
      add_library(ASS::ASS ALIAS libass::libass)
    else()
      add_library(ASS::ASS UNKNOWN IMPORTED)
      set_target_properties(ASS::ASS PROPERTIES
                                     IMPORTED_LOCATION "${ASS_LIBRARY}"
                                     INTERFACE_INCLUDE_DIRECTORIES "${ASS_INCLUDE_DIR}")
    endif()
    set_property(GLOBAL APPEND PROPERTY INTERNAL_DEPS_PROP ASS::ASS)
  endif()
endif()
