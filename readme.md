# Xome

Xome ("Zome") lets you build project-specific homes for nix that are reproducible and shared with a team. 

## Example Usage


### 1. Super Simple Home

If you already use flakes and tools like flake-utils, you'll probably want to skip to the next example.

Make a flake.nix in your project:

```nix
{
    description = "My Project";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        xome.url = "github:jeff-hykin/xome";
    };
    outputs = { self, nixpkgs, xome, ... }:
        xome.superSimpleMakeHome nixpkgs ({pkgs, ...}:
            {
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

Then run `HOME="$PWD" nix develop` and you'll enter an isolated nicely configured home.
NOTE: despite how it looks, the PWD is not being used as home. Its just a way to avoid your normal bashrc/zshrc/etc long enough for Xome to get a chance to properly setup home without inheriting your shell's environment.

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
                    packages = [ /* your stuff */ ];
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
                    packages = [ /* */ ];
                    devShells = xome.simpleMakeHomeFor {
                        inherit pkgs;
                        homeModule = {
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
        libSource.url = "github:divnix/nixpkgs.lib";
        flake-utils.url = "github:numtide/flake-utils";
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };
    outputs = { self, nixpkgs, flake-utils, xome, ... }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                pkgs = nixpkgs.legacyPackages.${system};
            in
                {
                    packages = [ /* */ ];
                    devShells = xome.makeHomeFor {
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
                                ]
                             }
                        );
                    };
                }
        );
}
```