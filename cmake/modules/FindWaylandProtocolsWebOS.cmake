# FindWaylandProtocolsWebOS
# -------------------------
# Find wayland-protocol-webOS
#
# This will define the following variables::
#
# WAYLANDPROTOCOLSWEBOS_PROTOCOLSDIR -  directory containing the additional webOS Wayland protocols
#                                       from the webos-wayland-extensions package

find_path(WAYLAND_PROTOCOLS_WEBOS_PROTOCOLDIR NAMES webos-shell.xml
                                              PATH_SUFFIXES wayland-webos
                                              PATHS ${DEPENDS_PATH}/share
                                              REQUIRED)

include(FindPackageMessage)
find_package_message(udfread "Found WaylandProtocols-WebOS: ${WAYLAND_PROTOCOLS_WEBOS_PROTOCOLDIR}"[${WAYLAND_PROTOCOLS_WEBOS_PROTOCOLDIR}]")

mark_as_advanced(WAYLANDPROTOCOLSWEBOS_PROTOCOLSDIR)
