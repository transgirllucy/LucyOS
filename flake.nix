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
      glibc64Stage = import ./derivations/cross_toolchain/glibc64.nix {
        pkgs = pkgs;
        cc1 = linuxHeadersStage;
      };
      glibc32Stage = import ./derivations/cross_toolchain/glibc32.nix {
        pkgs = pkgs;
        cc1 = linuxHeadersStage;
      };
      libstdcppStage = import ./derivations/cross_toolchain/libstdcpp.nix {
        pkgs = pkgs;
        cc1 = glibc64Stage;
      };

      m4Stage = import ./derivations/temp_tools/m4.nix {
        pkgs = pkgs;
        cc1 = libstdcppStage;
      };
      ncurses64Stage = import ./derivations/temp_tools/ncurses64.nix {
        pkgs = pkgs;
        cc1 = m4Stage;
      };
      ncurses32Stage = import ./derivations/temp_tools/ncurses32.nix {
        pkgs = pkgs;
        cc1 = m4Stage;
      };
      bashStage = import ./derivations/temp_tools/bash.nix {
	pkgs = pkgs;
        cc1 = ncurses64Stage;
      };
     coreutilsStage = import ./derivations/temp_tools/coreutils.nix { pkgs = pkgs; cc1 = bashStage; };

      diffutilsStage = import ./derivations/temp_tools/diffutils.nix { pkgs = pkgs; cc1 = coreutilsStage; };
      fileStage = import ./derivations/temp_tools/file.nix { pkgs = pkgs; cc1 = diffutilsStage; };


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
        crossTempTools = {
          m4 = m4Stage;
          ncurses64 = ncurses64Stage;
          ncurses32 = ncurses32Stage;
          bash = bashStage;
	  coreutils = coreutilsStage;
          diffutils = diffutilsStage;
          file = fileStage;
        };
      };
      hydraJobs = {
        inherit (self)
          packages
          ;
      };
    };
}
