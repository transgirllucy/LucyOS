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
        pkgs = pkgs;
        cc1 = gccStage1;
      };

      gccStage1 = import ./derivations/cross_toolchain/gcc.nix {
        pkgs = pkgs;
        customBinutils = binuntilsStage;
      };
      glibc64Stage = import ./derivations/cross_toolchain/glibc64.nix { pkgs = pkgs; cc1 = linuxHeadersStage; };
      glibc32Stage = import ./derivations/cross_toolchain/glibc32.nix { pkgs = pkgs; cc1 = linuxHeadersStage; };
          libstdcppStage = import ./derivations/cross_toolchain/libstdcpp.nix { pkgs = pkgs; cc1 = glibc64Stage; };
    
in
    {
      packages.x86_64-linux = {
        crossToolchain = {
          libstdcpp = libstdcppStage;
	  linuxHeaders = linuxHeadersStage;
          gcc = gccStage1;
          binutils = binuntilsStage;
	  glibc64 = glibc64Stage;
	  glibc32 = glibc32Stage;
        };
      };
      hydraJobs = {
 	inherit (self)
		packages;
      };
    };
}
