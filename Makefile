OPTIONS=--builders 'ssh://lucy@nix2twink.gay x86_64-linux'

binutils:
	nix build --impure .#crossToolchain.binutils -v ${OPTIONS}
gcc:
	nix build .#crossToolchain.gcc -v ${OPTIONS}
