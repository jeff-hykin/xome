![icon](https://github.com/user-attachments/assets/29706f81-b322-4026-b2af-18146272cb73)

Xome ("Zome") brings the power of Nix's [home-manager](https://github.com/nix-community/home-manager) to projects -- build project-specific homes that are shared with a team and reproducible.

## Example Usage

### 1. Super Simple Home

Skip to the next example if you already use flakes and tools like flake-utils.

Make a `flake.nix` in the root of your project:

```nix
{
    description = "My Project";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        xome.url = "github:jeff-hykin/xome";
    };
    outputs = { self, nixpkgs, xome, ... }:
        xome.superSimpleMakeHome { inherit nixpkgs; pure = true; } ({pkgs, ...}:
            {
                # for home-manager examples, see: https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                # all home-manager options: https://nix-community.github.io/home-manager/options.xhtml
                home.homeDirectory = "/tmp/virtual_homes/xome_simple";
                home.stateVersion = "25.11";
                home.packages = [
                    # vital stuff
                    pkgs.nix
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
                            # this enables some impure stuff like sudo, comment it out to get FULL purity
                            export PATH="$PATH:/usr/bin/"
                        '';
                    };
                    starship = {
                        enable = true;
                        enableZshIntegration = true;
                    };
                };
            }
        );
}
```

After that, run `nix develop` and you'll enter an isolated nicely configured home.

### 2. Simple Home

If you use flake utils you probably have something like this:

```nix
{
    description = "My Project";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        flake-utils.url = "github:numtide/flake-utils";
        xome.url = "github:jeff-hykin/xome";
    };
    outputs = { self, nixpkgs, flake-utils, xome, ... }:
        let
            something = "something";
        in
            flake-utils.lib.eachDefaultSystem (system:
                {
                    packages = { /* your normal stuff */ };
                }
            );
}
```

You can add Xome like this:

```nix
{
    description = "My Project";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        flake-utils.url = "github:numtide/flake-utils";
        xome.url = "github:jeff-hykin/xome";
    };
    outputs = { self, nixpkgs, flake-utils, xome, ... }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                pkgs = nixpkgs.legacyPackages.${system};
            in
                {
                    packages = { /* your normal stuff */ };
                    devShells = xome.simpleMakeHomeFor {
                        inherit pkgs;
                        pure = true;
                        homeModule = {
                            # for home-manager examples, see: 
                            # https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                            # all home-manager options: 
                            # https://nix-community.github.io/home-manager/options.xhtml
                            home.homeDirectory = "/tmp/virtual_homes/xome_simple";
                            home.stateVersion = "25.11";
                            home.packages = [
                                # vital stuff
                                pkgs.nix
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
```

### 3. Fully Configured Home 

If you want absolute control, this is the flake template for you:


```nix
{
    description = "My Project";
    inputs = {
        flake-utils.url = "github:numtide/flake-utils";
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        xome.url = "github:jeff-hykin/xome";
    };
    outputs = { self, nixpkgs, flake-utils, home-manager, xome, ... }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                pkgs = nixpkgs.legacyPackages.${system};
            in
                {
                    packages = { /* your normal flake stuff*/ };
                    devShells = xome.makeHomeFor {
                        pure = true;
                        envPassthrough = [ "NIX_SSL_CERT_FILE" "TERM" ];
                        # ^this is the default list. Could add HISTSIZE, EDITOR, etc without loosing much purity
                        home = (home-manager.lib.homeManagerConfiguration
                             {
                                inherit pkgs;
                                modules = [
                                    {
                                        home.username = "default"; # it NEEDS to be "default", it cant actually be 
                                        home.homeDirectory = "/tmp/virtual_homes/xome_simple";
                                        home.stateVersion = "25.11";
                                        home.packages = [
                                            # vital stuff
                                            pkgs.nix
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
                                                    # this enables some impure stuff like sudo, comment it out to get FULL purity
                                                    export PATH="$PATH:/usr/bin/"
                                                '';
                                            };
                                            starship = {
                                                enable = true;
                                                enableZshIntegration = true;
                                            };
                                        };
                                    }
                                ];
                             }
                        );
                    };
                }
        );
}
```
