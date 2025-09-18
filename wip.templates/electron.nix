{
    description = "nixpkg_electron_template";

    inputs = {
        libSource.url = "github:divnix/nixpkgs.lib";
        flake-utils.url = "github:numtide/flake-utils";
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
        home-manager.url = "github:nix-community/home-manager/release-25.05";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        xome.url = "github:jeff-hykin/xome";
        xome.inputs.nixpkgs.follows = "nixpkgs";
        xome.inputs.home-manager.follows = "home-manager";
        fenix.url = "github:nix-community/fenix";
        fenix.inputs.nixpkgs.follows = "nixpkgs";
    };
    outputs = { self, flake-utils, nixpkgs, fenix, xome, ... }:
        flake-utils.lib.eachSystem (builtins.attrNames fenix.packages) (system:
            let
                projectName = "nixpkg_electron_template";
                pkgs = import nixpkgs {
                    inherit system;
                    overlays = [
                        fenix.overlays.default 
                    ];
                    config = {
                        allowUnfree = true;
                        allowInsecure = false;
                        permittedInsecurePackages = [
                        ];
                    };
                };
                
                # 
                # pkg-config stuff
                # 
                pkgsForPkgConfigTool = [
                    # given inputs
                    pkgs.atk.dev
                    pkgs.gdk-pixbuf.dev
                    pkgs.gtk3.dev
                    pkgs.pango.dev
                    pkgs.libayatana-appindicator-gtk3.dev
                    pkgs.glib.dev
                    # discovered needed inputs
                    pkgs.dbus.dev
                    pkgs.libpng.dev
                    pkgs.libjpeg.dev
                    pkgs.libtiff.dev
                    pkgs.cairo.dev
                    pkgs.fribidi.dev
                    pkgs.fontconfig.dev
                    pkgs.harfbuzz.dev
                    pkgs.libthai.dev
                    pkgs.freetype.dev
                    pkgs.xorg.libXrender.dev
                    pkgs.xorg.libXft.dev
                    pkgs.zlib
                    pkgs.zlib.dev
                    pkgs.libffi.dev
                    pkgs.libselinux.dev
                    pkgs.expat.dev
                    pkgs.graphite2.dev
                    pkgs.bzip2.dev
                    pkgs.lerc.dev
                    pkgs.libsepol.dev
                    # libs not even on the list, but needed at link time 
                    pkgs.json-glib
                    pkgs.libselinux
                    pkgs.wayland
                    pkgs.libjson
                    pkgs.tinysparql
                    pkgs.tinysparql.dev
                    pkgs.json-glib.dev
                    pkgs.libselinux.dev
                    pkgs.wayland.dev
                ];
                PKG_CONFIG_PATH = builtins.concatStringsSep ":" (map (x: "${x}/lib/pkgconfig") pkgsForPkgConfigTool);
                LD_LIBRARY_PATH = builtins.concatStringsSep ":" (map (x: "${x}/lib") pkgsForPkgConfigTool);
                LIBRARY_PATH = builtins.concatStringsSep ":" (map (x: "${x}/lib") pkgsForPkgConfigTool);
                
                #
                # TODO: this is probably the better way compared to whats above (pkg-config)
                #
                fhsName = "electron-fhs-shell";
                fhs = pkgs.buildFHSEnv {
                    name = fhsName;
                    targetPkgs = (pkgs:
                        [
                            pkgs.zsh
                            pkgs.alsa-lib
                            pkgs.atkmm
                            pkgs.at-spi2-atk
                            pkgs.cairo
                            pkgs.cups
                            pkgs.dbus
                            pkgs.expat
                            pkgs.glib
                            pkgs.glibc
                            pkgs.gtk2
                            pkgs.gtk3
                            pkgs.gtk4
                            pkgs.libdrm
                            pkgs.libxkbcommon
                            pkgs.mesa
                            pkgs.nspr
                            pkgs.nss
                            pkgs.nodePackages.pnpm
                            pkgs.nodejs_20
                            pkgs.pango
                            pkgs.udev
                            pkgs.xorg.libXcomposite
                            pkgs.xorg.libXdamage
                            pkgs.xorg.libXext
                            pkgs.xorg.libXfixes
                            pkgs.xorg.libXrandr
                            pkgs.xorg.libX11
                            pkgs.xorg.xcbutil
                            pkgs.xorg.libxcb
                        ]
                    );
                    runScript = "zsh";
                };
                
                # 
                # dependencies
                #
                depenencies = {
                    common = [
                        pkgs.libiconv
                    ];
                    linux = pkgsForPkgConfigTool ++ [
                        pkgs.gcc
                        pkgs.pkg-config
                    ];
                    macos = [
                        pkgs.xcbuild
                        pkgs.xcodebuild
                        # pkgs.darwin.libobjc 
                        # pkgs.darwin.apple_sdk.frameworks.CoreServices 
                        # pkgs.darwin.apple_sdk.frameworks.CoreFoundation 
                        
                        pkgs.clang
                        pkgs.cmake
                        pkgs.python3
                        pkgs.dfu-programmer
                        pkgs.dfu-util
                        pkgs.wb32-dfu-updater
                        pkgs.gnumake
                        pkgs.teensy-loader-cli
                        # pkgs.python3.pkgs.setuptools
                        # pkgs.python3.pkgs.dotty-dict
                        # pkgs.python3.pkgs.hid
                        # pkgs.python3.pkgs.hjson
                        # pkgs.python3.pkgs.jsonschema
                        # pkgs.python3.pkgs.milc
                        # pkgs.python3.pkgs.pygments
                        # pkgs.python3.pkgs.pyserial
                        # pkgs.python3.pkgs.pyusb
                        # pkgs.python3.pkgs.pillow
                        pkgs.nodejs
                        pkgs.electron
                        # pkgs.gcc-arm-embedded
                        # pkgs.gcc
                    ];
                };
                nativeBuildInputs = depenencies.common ++ (if pkgs.stdenv.isLinux then depenencies.linux else (if pkgs.stdenv.isDarwin then depenencies.macos else []));
                
                shellHook = ''
                    echo build command is: 
                    echo '    npx electron-packager . my-app --electron-version "$(electron -v)"  --platform=darwin --arch=arm64 --out=dist --overwrite  --ignore='"'"'^(?!main|node_modules|package.json|package.json|package-lock.json|.*/main|.*/node_modules|.*/package.json|.*/package.json|.*/package-lock.json)(.+)$'"'"' '
                    export LIBRARY_PATH="$LIBRARY_PATH:${pkgs.libiconv}/lib"
                    ${if builtins.match ".*linux.*" system != null then
                        ''
                        export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"
                        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}"
                        export LIBRARY_PATH="${LIBRARY_PATH}"
                        # "${fhs}/bin/${fhsName}" # start the shell with the FHS
                        ''
                    else
                        ''
                        mkdir -p "$HOME/.local/bin/"
                        
                        # need to enable IMPURE hdiutil, sips, and sudo for macos
                        
                        ! [ -x "$HOME/.local/bin/hdiutil" ] && ln -s /usr/bin/hdiutil    "$HOME/.local/bin/hdiutil"
                        ! [ -x "$HOME/.local/bin/sips" ] && ln -s /usr/bin/sips    "$HOME/.local/bin/sips"
                        ! [ -x "$HOME/.local/bin/sudo" ] && ln -s /usr/bin/sudo    "$HOME/.local/bin/sudo"
                        ''
                    }
                '';
            in
                {
                    devShells = xome.simpleMakeHomeFor {
                        inherit pkgs;
                        pure = true;
                        homeModule = {
                            # for home-manager examples, see: 
                            # https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                            # all home-manager options: 
                            # https://nix-community.github.io/home-manager/options.xhtml
                            home.homeDirectory = "/tmp/virtual_homes/${projectName}";
                            home.stateVersion = "25.05";
                            home.packages = nativeBuildInputs ++ [
                                # vital stuff
                                pkgs.coreutils-full
                                pkgs.dash # for sh
                                
                                # optional stuff
                                pkgs.gnugrep
                                pkgs.findutils
                                pkgs.wget
                                pkgs.curl
                                pkgs.unixtools.locale
                                pkgs.unixtools.more
                                pkgs.unixtools.ps
                                pkgs.unixtools.getopt
                                pkgs.unixtools.ifconfig
                                pkgs.unixtools.hostname
                                pkgs.unixtools.ping
                                pkgs.unixtools.hexdump
                                pkgs.unixtools.killall
                                pkgs.unixtools.mount
                                pkgs.unixtools.sysctl
                                pkgs.unixtools.top
                                pkgs.unixtools.umount
                                pkgs.git
                                pkgs.htop
                                pkgs.ripgrep
                            ];
                            
                            programs = {
                                home-manager = {
                                    enable = true;
                                };
                                zsh = {
                                    enable = true;
                                    enableCompletion = true;
                                    autosuggestion.enable = true;
                                    syntaxHighlighting.enable = true;
                                    shellAliases.ll = "ls -la";
                                    history.size = 100000;
                                    # this is kinda like .zshrc
                                    initContent = ''
                                        # lots of things need "sh"
                                        ln -s "$(which dash)" "$HOME/.local/bin/sh" 2>/dev/null
                                        
                                        # without this npm (from nix) will not keep a reliable cache (it'll be outside of the xome home)
                                        export npm_config_cache="$HOME/.cache/npm"
                                        
                                        alias nix="nix --experimental-features 'nix-command flakes'"
                                        ${shellHook}
                                    '';
                                };
                                starship = {
                                    enable = true;
                                    enableZshIntegration = true;
                                };
                            };
                        }; 
                    };
                }
    );
}