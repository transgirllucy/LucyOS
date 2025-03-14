{ pkgs }:
let
  stdenv = pkgs.stdenv;

  nativePackages = with pkgs; [
    cmake
    zlib
    gnum4
    bison
  ];

  binutilsPkg = stdenv.mkDerivation {
    name = "binutils-LucyOS";

    src = pkgs.fetchurl {
      url = "https://sourceware.org/pub/binutils/releases/binutils-2.44.tar.xz";
      hash = "sha256-ziAX4FnWPmfduSQOnU7EnCiTYFA1zWDpKtUxd/Q3cjc=";
    };

    nativeBuildInputs = [ nativePackages ];
    buildInputs = [ ];

    prePhases = "prepEnvironmentPhase";
    prepEnvironmentPhase = ''
      export LFS=$(pwd)
      export LFSTOOLS=$(pwd)/tools
      export LFS_TGT=$(uname -m)-lfs-linux-gnu
      mkdir -v $LFSTOOLS
    '';

    # Using --prefix=$out instead of $LFS/tools.
    configurePhase = ''
      echo "Configuring... "
      echo "Starting config"
      time ( ./configure --prefix=$LFSTOOLS   \
                      --with-sysroot=$LFS     \
                      --target=$LFS_TGT       \
                      --disable-nls           \
                      --enable-gprofng=no     \
                      --disable-werror        \
                      --enable-new-dtags      \
                      --enable-default-hash-style=gnu
          )
    '';

    postInstall = ''
      rm -r $LFS/$sourceRoot
      cp -rvp $LFS/* $out/
    '';

    shellHook = ''
      echo -e "\033[31mNix Develop -> $name: Loading...\033[0m"

      if [[ "$(basename $(pwd))" != "$name" ]]; then
          mkdir -p "$name"
          cd "$name"
      fi

      eval "$prepEnvironmentPhase"
      echo -e "\033[36mNix Develop -> $name: Loaded.\033[0m"
      echo -e "\033[36mNix Develop -> Current directory: $(pwd)\033[0m"
    '';
  };
in
binutilsPkg
