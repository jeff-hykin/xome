{
    description = "port-kill";

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
                projectName = "port-kill";
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
                rustToolchain = pkgs.fenix.combine [
                    pkgs.fenix.stable.rustc
                    pkgs.fenix.stable.cargo
                    pkgs.fenix.stable.clippy
                    pkgs.fenix.stable.rustfmt
                ];
                rustPlatform = pkgs.makeRustPlatform {
                    rustc = rustToolchain;
                    cargo = rustToolchain;
                };
                commonRuntimeDeps = [
                    pkgs.lsof
                ];
                commonDeps = [
                    pkgs.libiconv
                ];
                macOsOnlyDeps = [
                    pkgs.clang
                ];
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
                linuxOnlyDeps = pkgsForPkgConfigTool ++ [
                    pkgs.gcc
                    pkgs.pkg-config
                ];
                nativeBuildInputs = commonDeps ++ (if pkgs.stdenv.isLinux then linuxOnlyDeps else []);
                shellHook = ''
                    export LIBRARY_PATH="$LIBRARY_PATH:${pkgs.libiconv}/lib"
                    ${if builtins.match ".*linux.*" system != null then
                        ''
                        export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"
                        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}"
                        export LIBRARY_PATH="${LIBRARY_PATH}"
                        ''
                    else
                        ""
                    }
                '';
            in
                {
                    packages.default = rustPlatform.buildRustPackage {
                        pname = projectName;
                        version = "0.1.0";
                        src = ./.;
                        
                        nativeBuildInputs = nativeBuildInputs;
                        buildInputs = commonRuntimeDeps;

                        cargoLock = {
                            lockFile = ./Cargo.lock;
                        };

                        meta = {
                            description = "port-kill";
                        };
                        
                        buildPhase = ''
                            ${shellHook}
                            if [ "$OSTYPE" = "linux-gnu" ]; then
                                sh "$src/build-linux.sh"
                            else
                                sh "$src/build-macos.sh"
                            fi
                        '';
                        installPhase = ''
                            mkdir -p "$out/bin/"
                            cp ./target/release/port-kill "$out/bin/port-kill"
                            # cp -r ./target/release "$out/bin/"
                        '';
                        XDG_CACHE_HOME = "/tmp/build/cache";
                    };
                    
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
                            home.packages = nativeBuildInputs ++ commonRuntimeDeps ++ [
                                # project stuff
                                rustToolchain
                                
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