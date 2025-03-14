COMPILE=nix build
CRT=#crossToolchain
CRTT=#crossTempTools
libstdcpp:
	nix build .#crossToolchain.libstdcpp
linuxHeaders:
	nix build .#crossToolchain.linuxHeaders
gcc:
	nix build .#crossToolchain.gcc
binutils:
	nix build .#crossToolchain.binutils
glibc64:
	nix build .#crossToolchain.glibc64
glibc32:
	nix build .#crossToolchain.glibc32

cross_toolchain: libstdcpp linuxHeaders gcc binutils glibc64 glibc32

m4:
	nix build .#crossTempTools.m4
ncurses64:	
	nix build .#crossTempTools.ncurses64
ncurses32:
	nix build .#crossTempTools.ncurses32
bash:
	nix build .#crossTempTools.bash
coreutils:
	nix build .#crossTempTools.coreutils
diffutils:
	nix build .#crossTempTools.diffutils
file:
	nix build .#crossTempTools.file

coretemp_tools: m4 ncurses64 ncurses32 bash coreutils diffutils file

default: cross_toolchain coretemp_tools
