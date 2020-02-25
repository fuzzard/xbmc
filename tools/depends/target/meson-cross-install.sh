#!/bin/bash

parsestring () {
  IFS=' '
  read -ra tmparray <<< "$1"
  declare -i arrcount=0
  printf %s "['"
  for i in "${tmparray[@]}"; do # access each element of array
    if [ "$arrcount" -gt 0 ]; then
      printf %s "', '"
    fi
    printf %s "$i"
    ((arrcount++))
  done
  printf %s "']"
}

cat > $prefix/$deps_dir/share/cross-file.meson << EOF
[binaries]
c = $(parsestring "$CC")
cpp = $(parsestring "$CXX")
ar = $(parsestring "$AR")
as = $(parsestring "$AS")
strip = $(parsestring "$STRIP")
pkgconfig = '$prefix/$deps_dir/bin/pkg-config'

[host_machine]
system = '$meson_system'
cpu_family = '$meson_cpu'
cpu = '$use_cpu'
endian = 'little'

[properties]
c_args = $(parsestring "$platform_cflags")
c_link_args = $(parsestring "$platform_ldflags")
cpp_args = $(parsestring "$platform_cxxflags")
cpp_link_args = $(parsestring "$platform_ldflags")

# meson 0.5.4 enables this. when we bump, uncomment
#pkg_config_libdir = '$prefix/$deps_dir/lib/pkg-config'

[paths]
prefix = '$prefix/$deps_dir/'
libdir = 'lib'
bindir = 'bin'
EOF