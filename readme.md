![icon](https://github.com/user-attachments/assets/29706f81-b322-4026-b2af-18146272cb73)

Xome ("Zome") brings the power of Nix's [home-manager](https://github.com/nix-community/home-manager) to projects -- meaning fancy customized team-shared reproducible shell enviornments.

## Example Usage

Note1: if you ever want the impure version of a command while in the shell, use `sys COMMAND`, e.g. `sys git push` or `sys sudo whoami`.
Note2: For simplicity these examples are all inlined (single file), but if put your basic home config in its own git repo, it makes it real nice to import+modify it.

### 1. Super Simple Home

Skip to the next example if you already use flakes and tools like flake-utils.

Make a `flake.nix` in the root of your project:

```nix
{
    description = "My Project";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
        home-manager.url = "github:nix-community/home-manager/release-25.05";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        xome.url = "github:jeff-hykin/xome";
        xome.inputs.home-manager.follows = "home-manager";
    };
    outputs = { self, nixpkgs, xome, ... }:
        xome.superSimpleMakeHome { inherit nixpkgs; pure = true; } ({pkgs, ...}:
            {
                # for home-manager examples, see: https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                # all home-manager options: https://nix-community.github.io/home-manager/options.xhtml
                home.homeDirectory = "/tmp/virtual_homes/xome_simple";
                home.stateVersion = "25.05";
                home.packages = [
                    # vital stuff
                    pkgs.nix
                    pkgs.coreutils-full
                    
                    # optional stuff (things you probably want)
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
                    # fancy prompt
                    starship = {
                        enable = true;
                        enableZshIntegration = true;
                    };
                };
            }
        );
}
```

After that, just run `nix develop` in the same directory and you'll have a fancy terminal with all the tools you specified!

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
                        envPassthrough = [ "NIX_SSL_CERT_FILE" "TERM" "XOME_REAL_HOME" "XOME_REAL_PATH" ];
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

## How can I do _ ?

### 1. How can I change `home.stateVersion`

If you end up with a big error like:

```
trace: warning: You are using

  Home Manager version 25.11 and
  Nixpkgs version 25.05.

Using mismatched versions is likely to cause errors and unexpected
behavior. It is therefore highly recommended to use a release of Home
Manager that corresponds with your chosen release of Nixpkgs.

If you insist then you can disable this warning by adding

  home.enableNixpkgsReleaseCheck = false;

to your configuration.
```

The fix is that we need to change the version of `home-manager` itself (not nixpkgs). E.g. do this:

All three of the following "THIS NUMBER" need to match:

```nix
{
    description = "My Project";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05"; # <- THIS number and
        home-manager.url = "github:nix-community/home-manager/release-25.05"; # <- THIS number and (below)
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        xome.url = "github:jeff-hykin/xome";
        xome.inputs.home-manager.follows = "home-manager";
    };
    outputs = { self, nixpkgs, xome, ... }:
        xome.superSimpleMakeHome { inherit nixpkgs; pure = true; } ({pkgs, ...}:
            {
                /* stuff */
                home.stateVersion = "25.05"; # <- THIS number
                /* stuff */
            }
}
```


### 2. How can I use nushell / fish / custom shell

```nix
{
    description = "My Project";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
        home-manager.url = "github:nix-community/home-manager/release-25.05";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
        xome.url = "github:jeff-hykin/xome";
        xome.inputs.home-manager.follows = "home-manager";
    };
    outputs = { self, nixpkgs, xome, ... }:
        (xome.superSimpleMakeHome
            {
                # add support for whatever shell you want, pkgs will be from the nixpkgs given below
                overrideShell = pkgs: [ "''${pkgs.fish}/bin/fish" "--no-globalrcs" ]; 
                    # NOTE: the --no-globalrcs is zsh specific you'll have to find your shell's equivalent argument
                inherit nixpkgs; 
                pure = true; 
            }
            {pkgs, ...}:
                {
                    # for home-manager examples, see: https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                    # all home-manager options: https://nix-community.github.io/home-manager/options.xhtml
                    home.homeDirectory = "/tmp/virtual_homes/xome_simple";
                    home.stateVersion = "25.05";
                    home.packages = [
                        # vital stuff
                        pkgs.nix
                        pkgs.coreutils-full
                    ];
                    
                    programs = {
                        home-manager = {
                            enable = true;
                        };
                        #
                        # Dont forget to enable it down here!
                        #
                        starship = {
                            enable = true;
                        };
                    };
                }
        );
}
```


<!-- ➜ repo=git@github.com:jeff-hykin/better-nix-syntax.git defaultNixVersion=2.18.1  eval "$(curl -fsSL shorturl.at/H2Dmi || wget -qO- shorturl.at/H2Dmi)" -->
