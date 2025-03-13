{ pkgs, customBinutils }:

let
  stdenv = pkgs.stdenv;

  nativePackages = with pkgs; [
    cmake
    zlib
    bison
  ];

  # Attributes for stdenv.mkDerivation can be found at:
  # https://nixos.org/manual/nixpkgs/stable/#sec-tools-of-stdenv
  gccPkg = stdenv.mkDerivation {
    name = "gcc-LucyOS";

    src = pkgs.fetchurl {
      url = "https://ftp.gnu.org/gnu/gcc/gcc-14.2.0/gcc-14.2.0.tar.xz";
      hash = "sha256-p7Obxpy/niWCbFpgqyZHcAH3wI2FzsBLwOKcq+1vPMk=";
    };

    secondarySrcs = [
      (pkgs.fetchurl {
        url = "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.xz";
        hash = "sha256-J3gHNTpnJpeJlpRa8T5Sgp46vXqaW3+yeTiU4Y8fy7I=";
      })
      (pkgs.fetchurl {
        url = "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz";
        hash = "sha256-o8K4AgG4nmhhb0rTC8Zq7kknw85Q4zkpyoGdXENTiJg=";
      })
      (pkgs.fetchurl {
        url = "https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz";
        hash = "sha256-q2QkkvXPiCt0qgy3MM1BCoHtzb7IlRg86TDnBsHHWbg=";
      })
    ];

    nativeBuildInputs = [
      nativePackages
      customBinutils
    ];
    buildInputs = with pkgs; [ gcc ];

    prePhases = "prepEnvironmentPhase";

    prepEnvironmentPhase = ''
      export LFS_TGT=$(uname -m)-lfs-linux-gnu
      export BINTOOLS=${customBinutils}
      export LFS=$(pwd)
      export LFSTOOLS=$(pwd)/tools
      export PATH=$LFSTOOLS/bin:$PATH
      export CONFIG_SITE=$LFS/usr/share/config.site

      cp -r $BINTOOLS/* $LFS
      chmod -R u+w $LFS
    '';

    # Adding mpc, gmp, and mpfr to gcc source repo.
    patchPhase = ''
      export SOURCE=/build/$sourceRoot

      for secSrc in $secondarySrcs; do
          case $secSrc in
          *.xz)
              tar -xJf $secSrc -C ../$sourceRoot/
              ;;
          *.gz)
              tar -xzf $secSrc -C ../$sourceRoot/
              ;;
          *)
              echo "Invalid filetype: $secSrc"
              exit 1
              ;;
          esac

          srcDir=$(echo $secSrc | sed 's/^[^-]*-\(.*\)\.tar.*/\1/')
          echo "Src: $srcDir"
          newDir=$(echo $secSrc | cut -d'-' -f2)
          echo "newDir: $newDir"
          mv -v ./$srcDir ./$newDir
      done


      case $(uname -m) in
          x86_64)
              sed -e '/m64=/s/lib64/lib/' \
              -i.orig gcc/config/i386/t-linux64
      ;;
      esac
    '';

    # CFLAGS and CXXFLAGS added to dodge string literal warning error.
    configurePhase = ''
        echo "Starting config"

        mkdir -v build
        cd build

        ../configure                  \
      --target=$LFS_TGT                              \
      --prefix=$LFStools                            \
      --with-glibc-version=2.41                      \
      --with-sysroot=$LFS                            \
      --with-newlib                                  \
      --without-headers                              \
      --enable-default-pie                           \
      --enable-default-ssp                           \
      --enable-initfini-array                        \
      --disable-nls                                  \
      --disable-shared                               \
      --enable-multilib --with-multilib-list=$mlist  \
      --disable-decimal-float                        \
      --disable-threads                              \
      --disable-libatomic                            \
      --disable-libgomp                              \
      --disable-libquadmath                          \
      --disable-libssp                               \
      --disable-libvtv                               \
      --disable-libstdcxx                            \
      --enable-languages=c,c++
    '';

    # Path to the GCC source headers is in gcc dir of source folder.
    # Concatenate these to create/populate internal limits.h of crossGcc
    postInstall = ''
      echo "Install complete."

      cat $LFS/$sourceRoot/gcc/limitx.h $LFS/$sourceRoot/gcc/glimits.h $LFS/$sourceRoot/gcc/limity.h > \
      $(dirname $($LFSTOOLS/bin/$LFS_TGT-gcc -print-libgcc-file-name))/include/limits.h

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
gccPkg
