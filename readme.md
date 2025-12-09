![icon](https://github.com/user-attachments/assets/29706f81-b322-4026-b2af-18146272cb73)

Xome ("Zome") brings the power of Nix's [home-manager](https://github.com/nix-community/home-manager) to projects -- meaning fancy customized team-shared shell environments that are even more reproducible than `nix-shell --pure`.

## Example Usage

Grab one of the nix-flakes below and run `nix develop` to see how it works. Read the Notes section to see how to have a good time once its up and running!

### 1. Super Simple Home

Skip to the next example if you use `flake-utils`.

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
        xome.superSimpleMakeHome { inherit nixpkgs; pure = true; } ({pkgs, system, ...}:
            {
                # for home-manager examples, see: https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                # all home-manager options: https://nix-community.github.io/home-manager/options.xhtml
                home.homeDirectory = "/tmp/virtual_homes/my_project1";
                home.stateVersion = "25.05";
                home.packages = [
                    # vital stuff
                    pkgs.coreutils-full
                    pkgs.dash # needed to make "sh"
                    
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
                
                # setup zsh with starship
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
                            
                            # this enables some impure stuff like sudo, comment it out to get FULL purity
                            export PATH="$PATH:/usr/bin/"
                        '';
                    };
                    # fancy prompt
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
                        commandPassthrough = [ "sudo" "nvim" "code" ]; # e.g. use external nvim instead of nix's
                        # commonly needed for MacOS: [ "sw_vers" "osascript" "otool" "hidutil" "logger" "codesign" ]
                        homeSubpathPassthrough = [ "cache/nix/" ]; # share nix cache between projects
                        homeModule = {
                            # for home-manager examples, see: 
                            # https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                            # all home-manager options: 
                            # https://nix-community.github.io/home-manager/options.xhtml
                            home.homeDirectory = "/tmp/virtual_homes/your_proj_name1";
                            home.stateVersion = "25.11";
                            home.packages = [
                                # vital stuff
                                pkgs.coreutils-full
                                pkgs.dash # needed to make "sh"
                                
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

### 3. Fully Manual Configuration

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
        flake-utils.lib.eachSystem flake-utils.lib.allSystems (system:
            let
                pkgs = nixpkgs.legacyPackages.${system};
            in
                {
                    packages = { /* your normal flake stuff*/ };
                    devShells = xome.makeHomeFor {
                        pure = true;
                        envPassthrough = [ "NIX_SSL_CERT_FILE" "TERM" "XOME_REAL_HOME" "XOME_REAL_PATH" "XOME_FAKE_HOME" "XOME_REAL_USER" ];
                        # ^this is the default list. Could add HISTSIZE, EDITOR, etc without loosing much purity
                        commandPassthrough = [ "sudo" "nvim" "code" ]; # e.g. use external nvim instead of nix's
                        # commonly needed for MacOS: [ "osascript" "otool" "hidutil" "logger" "codesign" ]
                        homeSubpathPassthrough = [ "cache/nix/" ];
                        # ^ could also add ".ssh/", "Library/Keychains/", ".pypirc", etc to get credentials symlinked into the fake home
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
                                            pkgs.coreutils-full
                                            pkgs.dash # needed to make "sh"
                                            
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
                                                    
                                                    # if you don't want things to be perfectly pure, enable the next line
                                                    # export PATH="$PATH:/usr/bin/"
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

## Notes! 

Xome comes with some minimal quality-of-life tools (because raw home manager in a nix flake has some challeges).

- Note 1: `sys <COMMAND>`
  - Xome is pure-by-default but comes with a `sys` command to escape that pureness as needed.
  - ✅ `sys git push` (grabs credentials from your real home)
  - ❌ `git push` (no git config found, because its a pure env)
  - ✅ `sys nvim` (uses your system nvim)
  - ❌ `nvim` (command not found)
  - ✅ `sys sudo chmod +x /dev/thing`
  - ❌ `sudo chmod +x /dev/thing`
- Note 2: Picking a home directory
  - Using `/tmp/somewhere/your_proj_name` like the examples is fine, but (if it works for your team) a more permanent path will help with startup time/caching. Sidenote, I'm working on a way to support relative paths and faster start times.
- Note 3: Bulky Examples
  - The examples below are big and fully inlined (one file) for clarity, but pro-tip: yours can be much more sleek! Make a big home config that is exactly how you like (nu shell / fish, colors, aliases, essential packages, etc), put it in a git repo somewhere, then import it as a starter kit for multiple projects. Its really nice to update a home config one place, then `nix flake update` to pull it into each project. 
  - I'll probably add an example of this using home-modules at some point.
  - I'm considering adding multiple profiles (e.g. someone on the team likes zsh and another person likes fish). Open an issue if you want that feature. 


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
        xome.superSimpleMakeHome { inherit nixpkgs; pure = true; } ({pkgs, system, ...}:
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
                overrideShell = pkgs: [ "${pkgs.fish}/bin/fish" "--no-globalrcs" ]; 
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
                        pkgs.coreutils-full
                        pkgs.dash # needed to make "sh"
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

### 3. Get Complete Purity (no rc or ENV vars)

I've still run into cases were even having a separate home is not enough.

To run with absolute purity, run this instead of `nix develop`:

```bash
nix develop --ignore-environment --command bash --norc --noprofile 
```

If the codebase still has "works on my machine" problems, then something absolutely crazy is going on.

<!--
todo
- example + better support for home modules
- make it easy to symlink stuff like deno cache, nixpkgs cache, and .ssh.
- maybe have a fallback sudo command that says "run sys sudo" 
- explain more about Env pass through and pure = false option.
- have home modules for stuff like ruby, npm, Python venv etc that include printouts for instructions (gem file, requirements.txt, etc)

➜ repo=git@github.com:jeff-hykin/better-nix-syntax.git defaultNixVersion=2.18.1  eval "$(curl -fsSL shorturl.at/H2Dmi || wget -qO- shorturl.at/H2Dmi)" -->
