{ pkgs, cc1 }:
let
  # nixpkgs = import <nixpkgs> {};
  nixpkgs = pkgs;
  stdenv = nixpkgs.stdenvNoCC;

  nativePackages = with pkgs; [
    cmake
    zlib
    bison
    binutils
  ];

  # Attributes for stdenv.mkDerivation can be found at:
  # https://nixos.org/manual/nixpkgs/stable/#sec-tools-of-stdenv
  ncursesPkg = stdenv.mkDerivation {
    name = "ncurses32-LucyOS";

    src = pkgs.fetchurl {
      url = "https://invisible-mirror.net/archives/ncurses/ncurses-6.5.tar.gz";
      hash = "sha256-E22RvCaamleF5fnpgLx2q1dCj2BM4+WlqQzrx2eXHMY=";
    };

    nativeBuildInputs = [ nativePackages ] ++ [ cc1 ];
    buildInputs = [
      cc1
      pkgs.gcc
    ];
    dontFixup = true;

    prePhases = "prepEnvironmentPhase";
    prepEnvironmentPhase = ''
      export LFS=$PWD
      export LFSTOOLS=$PWD/tools
      export LFS_TGT=$(uname -m)-lfs-linux-gnu
      export LFS_TGT32=i686-lfs-linux-gnu
      export CONFIG_SITE=$LFS/usr/share/config.site
      export PATH=$LFSTOOLS/bin:$PATH
      export PATH=$LFS/usr/bin:$PATH
      export CC1=${cc1}
      cp -r $CC1/* $LFS
      chmod -R u+w $LFS
    '';

    configurePhase = ''
            sed -i s/mawk// configure
            echo $(env | grep TGT)
            echo $(env | grep LD_)
            chmod -R u+w $LFS
            mkdir build
            pushd build
                ../configure
                make -C include
                make -C progs tic
            popd

            # export CC=$LFSTOOLS/bin/x86_64-lfs-linux-gnu-gcc
            # export CXX=$LFSTOOLS/bin/x86_64-lfs-linux-gnu-g++

      ./configure --prefix=/usr           \
                  --host=$LFS_TGT32       \
                  --build=$(./config.guess)    \
                  --libdir=/usr/lib32     \
                  --mandir=/usr/share/man \
                  --with-shared           \
                  --without-normal        \
                  --with-cxx-shared       \
                  --without-debug         \
                  --without-ada           \
                  --disable-stripping

    '';

    installPhase = ''
            make DESTDIR=$PWD/DESTDIR TIC_PATH=$(pwd)/build/progs/tic install
      ln -sv libncursesw.so DESTDIR/usr/lib32/libncurses.so
      mkdir -pv $LFS/usr/lib32
      cp -Rv DESTDIR/usr/lib32/* $LFS/usr/lib32
      rm -rf DESTDIR
      	
            runHook postInstall
    '';

    postInstall = ''
      mkdir $out
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
ncursesPkg
