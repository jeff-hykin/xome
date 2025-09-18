{
    description = "Render UI with yew";

    inputs = {
        libSource.url = "github:divnix/nixpkgs.lib";
        flake-utils.url = "github:numtide/flake-utils";
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
        home-manager.url = "github:nix-community/home-manager/release-25.05";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        xome.url = "github:jeff-hykin/xome";
        xome.inputs.nixpkgs.follows = "nixpkgs";
        xome.inputs.home-manager.follows = "home-manager";
        # rustFlake.url = "github:jeff-hykin/rust_flake/v1.89.0";
        # rustFlake.inputs.nixpkgs.follows = "nixpkgs";
        fenix.url = "github:nix-community/fenix";
        fenix.inputs.nixpkgs.follows = "nixpkgs";
    };
    outputs = { self, flake-utils, nixpkgs, fenix, xome, ... }:
        flake-utils.lib.eachSystem (builtins.attrNames fenix.packages) (system:
            let
                pkgs = import nixpkgs {
                    inherit system;
                    overlays = [
                        fenix.overlays.default 
                    ];
                    config = {
                        allowUnfree = true;
                        allowInsecure = true;
                        permittedInsecurePackages = [
                        ];
                    };
                };
                rustToolchain = pkgs.fenix.combine [
                    pkgs.fenix.stable.rustc
                    pkgs.fenix.stable.cargo
                    pkgs.fenix.stable.clippy
                    pkgs.fenix.stable.rustfmt
                    pkgs.fenix.targets.wasm32-unknown-unknown.stable.rust-std
                    # pkgs.fenix.targets.x86_64-unknown-linux-musl.stable.rust-std
                ];
                rustPlatform = pkgs.makeRustPlatform {
                    rustc = rustToolchain;
                    cargo = rustToolchain;
                };
                nativeBuildInputs = [
                    pkgs.trunk
                    pkgs.wasm-bindgen-cli
                    pkgs.nodePackages.sass
                    pkgs.pkg-config
                ];
            in
                {
                    packages.default = rustPlatform.buildRustPackage {
                        pname = "render-ui";
                        version = "0.1.0";
                        src = ./.;
                        
                        nativeBuildInputs = nativeBuildInputs;

                        cargoLock = {
                            lockFile = ./Cargo.lock;
                        };

                        meta = {
                            description = "3D render UI with yew";
                        };
                        
                        buildPhase = "
                            trunk build
                            cargo build --release
                        ";
                        installPhase = ''
                            cp -r dist $out
                            # mkdir -p "$out/bin/"
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
                            home.homeDirectory = "/tmp/virtual_homes/render_ui";
                            home.stateVersion = "25.05";
                            home.packages = nativeBuildInputs ++ [
                                # project stuff
                                rustToolchain
                                
                                # vital stuff
                                pkgs.dash # provides "sh" 
                                pkgs.coreutils-full
                                
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
                                        setopt interactivecomments
                                        
                                        alias nix="nix --experimental-features 'nix-command flakes'"
                                        
                                        echo "dont forget deno wasm-pack-embed-unofficial"
                                        # this enables some impure stuff like sudo, comment it out to get FULL purity
                                        export PATH="$PATH:/usr/bin/"
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