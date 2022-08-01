{
  description = "Flutter FHS Environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flutter-nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flutter-nixpkgs, devshell, android-nixpkgs }: {
    getShell = {
      pkgs ? import nixpkgs {
        inherit system;
        config = nixpkgsConfig // {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
        overlays = [ devshell.overlay ];
      }
      , flutter-pkgs ? import flutter-nixpkgs {
        inherit system;
      }
      , name ? "flutter-project", system, nixpkgsConfig ? { }
      , enable-android ? false, enable-ios ? false
      , enable-linuxDesktop ? false, enable-web ? false
      , enable-windowsDesktop ? false, enable-macDesktop ? false
      , extra-deps ? [ ], extra-libs ? [ ], jdk ? pkgs.jdk11
      , chromeExecutable ? pkgs.ungoogled-chromium + "/bin/chromium"
      , android-sdk ? android-nixpkgs.sdk.${system} (sdkPkgs: with sdkPkgs; [
        cmdline-tools-latest
        build-tools-30-0-3
        emulator
        patcher-v4
        platform-tools
        platforms-android-31
      ])
    }: with pkgs; let
      optList = q: xs: if q then xs else [ ];
      linuxLibs = [
        at-spi2-atk
        at-spi2-core
        dbus
        atk
        bzip2
        cairo
        epoxy
        expat
        fontconfig
        freetype
        fribidi
        gdk-pixbuf
        glib
        graphite2
        gtk3
        harfbuzz
        libGL
        libdatrie
        libffi
        libjpeg
        libpng
        libselinux
        libsepol
        libthai
        libtiff
        libuuid
        libxkbcommon
        pango
        pcre
        pixman
        wayland
        xorg.libX11
        xorg.libXau
        xorg.libXcomposite
        xorg.libXcursor
        xorg.libXdmcp
        xorg.libXext
        xorg.libXfixes
        xorg.libXft
        xorg.libXi
        xorg.libXinerama
        xorg.libXrandr
        xorg.libXrender
        xorg.libxcb
        xorg.xorgproto
        zlib
      ];

      flutter-deps = optList enable-android [
        android-sdk
        gradle
        jdk
      ] ++ optList enable-linuxDesktop [
        clang
        cmake
        ninja
        pkg-config
      ]
      ++ optList enable-linuxDesktop (map lib.getLib linuxLibs)
      ++ optList enable-linuxDesktop (map lib.getDev linuxLibs)
      ++ (map lib.getLib extra-libs) ++ (map lib.getDev extra-libs);
    in pkgs.devshell.mkShell {
      name = name;
      env = [
        {
          name = "PATH";
          prefix = "$HOME/.pub-cache/bin";
        }
        {
          name = "PATH";
          prefix = "${flutter-pkgs.flutter}/bin/cache/dart-sdk/bin";
        }
      ] ++ optList enable-android [
        {
          name = "ANDROID_HOME";
          value = "${android-sdk}/share/android-sdk";
        }
        {
          name = "ANDROID_SDK_ROOT";
          value = "${android-sdk}/share/android-sdk";
        }
        {
          name = "JAVA_HOME";
          value = jdk.home;
        }
      ] ++ optList enable-linuxDesktop [
        {
          name = "LD_LIBRARY_PATH";
          prefix = "$DEVSHELL_DIR/lib";
        }
        {
          name = "C_INCLUDE_PATH";
          prefix = "$DEVSHELL_DIR/include";
        }
        {
          name = "CPLUS_INCLUDE_PATH";
          prefix = "$DEVSHELL_DIR/include";
        }
        {
          name = "PKG_CONFIG_PATH";
          prefix = "$DEVSHELL_DIR/lib/pkgconfig";
        }
        {
          name = "CMAKE_PREFIX_PATH";
          prefix = "$DEVSHELL_DIR";
        }
      ] ++ optList enable-web [
        {
          name = "CHROME_EXECUTABLE";
          value = chromeExecutable;
        }
      ];
      packages = [ flutter-pkgs.flutter ] ++ flutter-deps ++ extra-deps;
    };
  };
}
