{ pkgs, cc1 }:
let
  stdenvNoCC = pkgs.stdenvNoCC;

  nativePackages = with pkgs; [
    bison
    texinfo
    perl
    python3
  ];



  # Attributes for stdenv.mkDerivation can be found at:
  # https://nixos.org/manual/nixpkgs/stable/#sec-tools-of-stdenv
  glibcPkg = stdenvNoCC.mkDerivation {
    name = "glibc32-LucyOS";

    src = pkgs.fetchurl {
      url = "https://ftp.gnu.org/gnu/glibc/glibc-2.41.tar.xz";
      hash = "";
    };

    patchSrc = pkgs.fetchurl {
      url = "https://www.linuxfromscratch.org/patches/lfs/development/glibc-2.41-fhs-1.patch";
      hash = "sha256-ZDVS2wMOLy1//eT1WOD1+D0/q/NKLg5W69tJdQrCew0";
    };


    nativeBuildInputs = [ nativePackages ];
    buildInputs = [ cc1 pkgs.gcc ];

    prePhases = "prepEnvironmentPhase";
    prepEnvironmentPhase = ''
      export LFS=$PWD
      export LFSTOOLS=$LFS/tools
      export LFS_TGT=$(uname -m)-lfs-linux-gnu
      export PATH=$LFSTOOLS/bin:$PATH
      export PATH=$LFS/usr/bin:$PATH
      export CC1=${cc1}
      export CONFIG_SITE=$LFS/usr/share/config.site

      cp -r $CC1/* $LFS/
      chmod -R u+w $LFS

    '';

    configurePhase = ''
       echo "rootsbindir=/usr/sbin" > configparms
       cp -pv $patchSrc ./glibc.patch
       patch -Np1 -i ./glibc.patch

       CC="$LFS_TGT-gcc -m32" \
       CXX="$LFS_TGT-g++ -m32" \

       mkdir -v build
       cd build


       ../configure                             \
      --prefix=/usr                      \
      --host=$LFS_TGT32                  \
      --build=$(../scripts/config.guess) \
      --enable-kernel=5.4                 \
      --with-headers=$LFS/usr/include    \
      --disable-nscd                     \
      --libdir=/usr/lib32                \
      --libexecdir=/usr/lib32            \
      libc_cv_slibdir=/usr/lib32
    '';

    installFlags = [ "DESTDIR=$(LFS)" ];

    postInstall = ''
      sed '/RTLDLIST=/s@/usr@@g' -i $LFS/usr/bin/ldd

      pushd $LFS/lib
      	ln -svf ./lib32/ld-linux.so.2 ../lib/ld-linux.so.2
      popd

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
glibcPkg

