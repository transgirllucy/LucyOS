{ pkgs, cc1 }:
let
  nixpkgs = pkgs;
  stdenvNoCC = nixpkgs.stdenvNoCC;

  nativePackages = with pkgs; [
    cmake
    zlib
    bison
  ];

  coreutilsPkg = stdenvNoCC.mkDerivation {
    name = "coreutils-LucyOS";

    src = pkgs.fetchurl {
      url = "https://ftp.gnu.org/gnu/coreutils/coreutils-9.6.tar.xz";
      hash = "sha256-egEkMns5j9nrGmq95YM4mCFCLHRP+hBzSyT1V2ENMoM=";
    };

    nativeBuildInputs = [ nativePackages ];
    buildInputs = [ cc1 ];
    dontFixup = true;

    prePhases = "prepEnvironmentPhase";
    prepEnvironmentPhase = ''
      export LFS=$PWD
      export LFSTOOLS=$PWD/tools
      export LFS_TGT=$(uname -m)-lfs-linux-gnu
      export CONFIG_SITE=$LFS/usr/share/config.site
      export PATH=$PATH:$LFS/usr/bin
      export PATH=$PATH:$LFSTOOLS/bin
      export CC1=${cc1}

      cp -r $CC1/* $LFS
      chmod -R u+w $LFS
    '';

    configurePhase = ''
      ./configure --prefix=/usr                   \
          --host=$LFS_TGT                         \
          --build=$(build-aux/config.guess)       \
          --enable-install-program=hostname      \
          --enable-no-install-program=kill,uptime
    '';

    installFlags = [ "DESTDIR=$(LFS)" ];

    postInstall = ''
      echo "Install complete."
      mv -v $LFS/usr/bin/chroot               $LFS/usr/sbin
      mkdir -pv $LFS/usr/share/man/man8
      mv -v $LFS/usr/share/man/man1/chroot.1  $LFS/usr/share/man/man8/chroot.8
      sed -i 's/"1"/"8"/'                     $LFS/usr/share/man/man8/chroot.8
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
coreutilsPkg
