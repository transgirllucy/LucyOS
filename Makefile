binutils:
	nix build .#crossToolchain.binutils -v
gcc:
	nix build .#crossToolchain.gcc -v
