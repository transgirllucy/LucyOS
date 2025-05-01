{ pkgs, cc2, lib }:
let
  stdenv = pkgs.stdenv;
  fhsEnv = stdenv.mkDerivation {
    name = "neofetch";

    src = pkgs.fetchFromGitHub {
      owner = "dylanaraps";
      repo = "neofetch";
      rev = "ccd5d9f52609bbdcd5d8fa78c4fdb0f12954125f";
      sha256 = "sha256-9MoX6ykqvd2iB0VrZCfhSyhtztMpBTukeKejfAWYW1w=";
    };
    patches = [
      (pkgs.fetchpatch {
        url =
          "https://github.com/dylanaraps/neofetch/commit/413c32e55dc16f0360f8e84af2b59fe45505f81b.patch";
        sha256 = "1fapdg9z79f0j3vw7fgi72b54aw4brn42bjsj48brbvg3ixsciph";
        name = "avoid_overwriting_gio_extra_modules_env_var.patch";
      })
      # https://github.com/dylanaraps/neofetch/pull/2114
      (pkgs.fetchpatch {
        url =
          "https://github.com/dylanaraps/neofetch/commit/c4eb4ec7783bb94cca0dbdc96db45a4d965956d2.patch";
        sha256 = "sha256-F6Q4dUtfmR28VxLbITiLFJ44FjG4T1Cvuz3a0nLisMs=";
        name = "update_old_nixos_logo.patch";
      })
      # https://github.com/dylanaraps/neofetch/pull/2157
      (pkgs.fetchpatch {
        url =
          "https://github.com/dylanaraps/neofetch/commit/de253afcf41bab441dc58d34cae654040cab7451.patch";
        sha256 = "sha256-3i7WnCWNfsRjbenTULmKHft5o/o176imzforNmuoJwo=";
        name = "improve_detect_nixos_version.patch";
      })
    ];

    phases =
      [ "prepEnvironmentPhase" "unpackPhase" "configurePhase" "buildPhase" ];

    buildInputs = [ cc2 ];
    nativeBuildInputs = with pkgs; [ gnutar xz ];

    prePhases = "prepEnvironmentPhase";
    prepEnvironmentPhase = ''
      export LFS=$PWD
      export CC2=${cc2}
      export PATH=$PATH:$LFS/usr/bin
      export CONFIG_SITE=$LFS/usr/share/config.site

      cp -r $CC2/* $LFS
      chmod -R u+w $LFS
    '';

    configurePhase = ''
      export SRC=$PWD
      # Output directory
      mkdir $out
      # src folder
      mkdir -pv $LFS/tmp/src

      cp -rpv $SRC/* $LFS/tmp/src
    '';

    buildPhase = ''
      ${
        pkgs.buildFHSEnv {
          name = "fhs";

          # This is necessary to override default /lib64 symlink set to /lib.
          # This symlink prevented binding LFS lib to FHS lib64.
          # see setupTargetProfile in buildFHSenv.nix
          # LFS bin interpreter is set to /lib64, so this is important in order
          # for LFS bins to function in FHS env.
          extraBuildCommands = ''
            rm -rf lib64
          '';

          extraBwrapArgs = [
            "--unshare-all"
            "--hostname lfs-bwrap-bash"
            "--uid 0"
            "--gid 0"
            "--chdir /"
            "--tmpfs /tmp"
            "--tmpfs /run"
            "--tmpfs /dev/shm"
            "--tmpfs /etc"
            "--dir /tmp/out"
            "--dir /build_tools"
            "--bind $out /tmp/out"
            "--bind $LFS/usr/lib /lib64"
            "--bind $LFS/tmp/src /tmp/src"
            "--bind $LFS/usr/lib /lib"
            "--bind $LFS/root /root"
            "--bind $LFS/media /media"
            "--bind $LFS/sbin /sbin"
            "--bind $LFS/bin /bin"
            "--bind $LFS/usr /usr"
            "--bind $LFS/usr/lib /usr/lib"
            "--bind $LFS/var /var"
            "--bind $LFS/etc /etc"
            "--bind $LFS/home /home"
            "--bind $LFS/build_tools /build_tools"
            "--clearenv"
            "--setenv HOME /root"
            "--setenv MAKEFLAGS -j$(nproc)"
            "--setenv PATH /usr/bin:/usr/sbin"
            "--setenv OUT /tmp/out"
            "--setenv SRC /tmp/src"
            "--setenv CONFIG_SITE $LFS/usr/share/config.site"
          ];
        }
      }/bin/fhs ${pkgs.writeShellScript "setup" setupEnvScript};
    '';

    shellHook = ''
      echo -e "\033[31mNix Develop -> $name: Loading...\033[0m"

      if [[ "$(basename $(pwd))" != "$name" ]]; then
          mkdir -p "$name"
          cd "$name"
      fi

      eval "$prepEnvironmentPhase"
      eval "$unpackPhase"
      eval "$configurePhase"
      eval "$buildPhase"
      echo -e "\033[36mNix Develop -> $name: Loaded.\033[0m"
      echo -e "\033[36mNix Develop -> Current directory: $(pwd)\033[0m"
    '';
  };

  setupEnvScript = ''
    export PATH=/build_tools/bin:$PATH
    set -e
    cd /tmp/src

    make -j$(nproc)

    make install

    set +e
    mkdir $OUT/{usr,opt,srv,tmp,boot,home,sbin,root,etc,lib,var,bin,tools,media,build_tools}
    cp -pvr /usr/* $OUT/usr
    cp -pvr /opt/* $OUT/opt
    cp -pvr /srv/* $OUT/srv
    cp -pvr /boot/* $OUT/boot
    
    cp -pvr /sbin/* $OUT/sbin
    cp -pvr /root/* $OUT/root
    cp -pvr /etc/* $OUT/etc
    cp -pvr /lib/* $OUT/lib
    cp -pvr /var/* $OUT/var
    cp -pvr /bin/* $OUT/bin
    cp -pvr /media/* $OUT/media
    cp -pvr /build_tools/* $OUT/build_tools
  '';
in fhsEnv
