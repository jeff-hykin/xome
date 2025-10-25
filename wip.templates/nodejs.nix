{
    description = "Nixpkgs_electron_template_actions";
    inputs = {
        libSource.url = "github:divnix/nixpkgs.lib";
        flake-utils.url = "github:numtide/flake-utils";
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
        home-manager.url = "github:nix-community/home-manager/release-25.05";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        xome.url = "github:jeff-hykin/xome";
        xome.inputs.nixpkgs.follows = "nixpkgs";
        xome.inputs.home-manager.follows = "home-manager";
    };
    outputs = { self, flake-utils, nixpkgs, xome, ... }:
        flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (system:
            let
                pkgs = import nixpkgs {
                    inherit system;
                    overlays = [
                    ];
                    config = {
                        allowUnfree = true;
                        allowInsecure = false;
                        permittedInsecurePackages = [
                        ];
                    };
                };
                inputPackages = [
                    pkgs.nodejs
                    pkgs.esbuild
                    
                    # pkgs.yarn
                    # pkgs.corepack # needed for yarn to work
                    # pkgs.esbuild
                    # pkgs.graphviz # used for visualizing circular dependencies (e.g. debugging only)
                    # pkgs.nodePackages.typescript
                    # pkgs.nodePackages.prettier
                ];
            in
                {
                    # this is how the package is built (as a dependency)
                    packages.default = pkgs.stdenv.mkDerivation {
                        src = ./.;
                        name = (builtins.toJSON (builtins.readFile ./package.json)).name;

                        buildInputs = inputPackages;

                        buildPhase = ''
                            export HOME=$(mktemp -d) # Needed by npm to avoid global install warnings
                            npm install
                            # tsc
                        '';

                        installPhase = ''
                            mkdir -p $out
                            cp -r dist/* $out/
                        '';
                    };
                    
                    # development environment for contributions
                    devShells = xome.simpleMakeHomeFor {
                        inherit pkgs;
                        pure = true;
                        homeModule = {
                            # for home-manager examples, see: 
                            # https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                            # all home-manager options: 
                            # https://nix-community.github.io/home-manager/options.xhtml
                            home.homeDirectory = "/tmp/virtual_homes/nixpkgs_electron_template_actions";
                            home.stateVersion = "25.05";
                            home.packages = inputPackages ++ [
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
                                        
                                        # without this npm (from nix) will not keep a reliable cache (it'll be outside of the xome home)
                                        export npm_config_cache="$HOME/.cache/npm"
                                        
                                        # 
                                        # offer to run npm install
                                        # 
                                        if ! [ -d "node_modules" ]
                                        then
                                            question="I don't see node_modules, should I run npm install? [y/n]";answer=""
                                            while true; do
                                                echo "$question"; read response
                                                case "$response" in
                                                    [Yy]* ) answer='yes'; break;;
                                                    [Nn]* ) answer='no'; break;;
                                                    * ) echo "Please answer yes or no.";;
                                                esac
                                            done
                                            
                                            if [ "$answer" = 'yes' ]; then
                                                npm install
                                            fi
                                        fi
                                        
                                        # this enables some impure stuff like sudo, comment it out to get FULL purity
                                        # export PATH="$PATH:/usr/bin/"
                                        echo
                                        echo "NOTE: if you want to use sudo/git/vim/etc (anything impure) do: sys <that command>"
                                    '';
                                };
                                starship = {
                                    enable = true;
                                    enableZshIntegration = true;
                                    settings = {
                                        character = {
                                            success_symbol = "[∫](bold green)";
                                            error_symbol = "[∫](bold red)";
                                        };
                                    };
                                };
                            };
                        }; 
                    };
                }
    );
}