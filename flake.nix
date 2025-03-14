{
  description = "LucyOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      fs = pkgs.lib.fileset;

      binuntilsStage = import ./derivations/cross_toolchain/binutils.nix { pkgs = pkgs; };
      linuxHeadersStage = import ./derivations/cross_toolchain/linuxHeaders.nix {
        pkgs = x86_pkgs;
        cc1 = gccStage1;
      };

      gccStage1 = import ./derivations/cross_toolchain/gcc.nix {
        pkgs = pkgs;
        customBinutils = binuntilsStage;
      };
    in
    {
      packages.x86_64-linux = {
        crossToolchain = {
	  
          gcc = gccStage1;
          binutils = binuntilsStage;
        };
      };
    };
}
