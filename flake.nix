{
    description = "Xome: virtual homes for nix";
    inputs = {
        libSource.url = "github:divnix/nixpkgs.lib";
        flake-utils.url = "github:numtide/flake-utils";
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
    };
    outputs = { self, libSource, flake-utils, home-manager, ... }:
        let
            lib = libSource.lib;
            mkHomeFor = ({ overrideShell ? null, home, ... }@args:
                let 
                    pkgs = home.pkgs;
                    shellPackageNameProbably = (
                        if (home.config.programs.zsh.enable) then
                            "zsh"
                        else if (home.config.programs.bash.enable) then
                            "bash"
                        else if (builtins.isFunction overrideShell) then
                            true
                        else
                            builtins.throw ''Sorry I don't support the shell you selected in home manager (I only support zsh and bash) However you can override this by giving xome an argument: overrideShell = system: [ "''${yourShellExecutablePath}" "--no-globalrcs" ]; ''
                    );
                    shellCommandList = (
                        if (shellPackageNameProbably == "zsh") then
                            [ "${pkgs.zsh}/bin/zsh" "--no-globalrcs" ]
                        else if (shellPackageNameProbably == "bash") then
                            [ "${pkgs.bash}/bin/bash" "--noprofile" ]
                        else if (builtins.isFunction overrideShell) then
                            (overrideShell pkgs)
                        else
                            builtins.throw ''Note: this should be unreachable, but as a fallback: Sorry I don't support the shell you selected in home manager (I only support zsh and bash at the moment). However you can override this by giving xome an argument: overrideShell = pkgs: [ "''${yourShellExecutablePath}" "--no-globalrcs" ]; ''
                    );
                    shellCommandString = "${lib.concatStringsSep " " (builtins.map lib.escapeShellArg shellCommandList)}";
                    homePath = home.config.home.homeDirectory;
                in 
                    {
                        default = pkgs.mkShell {
                            packages = home.config.home.packages;
                            shellHook = ''
                                export REAL_HOME="$HOME"
                                export HOME=${lib.escapeShellArg homePath}
                                mkdir -p "$HOME/.local/state/nix/profiles"
                                # note: the grep is to remove common startup noise
                                USER="default" HOME=${lib.escapeShellArg homePath} ${home.activationPackage.out}/activate 2>&1 | ${pkgs.gnugrep}/bin/grep -v -E "Starting Home Manager activation|warning: unknown experimental feature 'repl-flake'|Activating checkFilesChanged|Activating checkLinkTargets|Activating writeBoundary|No change so reusing latest profile generation|Activating installPackages|warning: unknown experimental feature 'repl-flake'|replacing old 'home-manager-path'|installing 'home-manager-path'|Activating linkGeneration|Cleaning up orphan links from .*|Creating home file links in .*|Activating onFilesChange|Activating setupLaunchAgents"
                                env -i VIRTUAL_ACTIVE=1 PATH=${lib.escapeShellArg homePath}/bin:${lib.escapeShellArg homePath}/.nix-profile/bin HOME=${lib.escapeShellArg homePath} USER="$USER" SHELL=${lib.escapeShellArg (builtins.elemAt shellCommandList 0)} TERM="$TERM" ${shellCommandString}
                                exit $?
                            '';
                        };
                    }
            );
        in
            {
                mkHomeFor = mkHomeFor;
                superSimpleHomeBuild = nixpkgs: homeConfigFunc: (flake-utils.lib.eachSystem
                    flake-utils.lib.allSystems
                    (system:
                        {
                            devShells = mkHomeFor {
                                home = (
                                    let
                                        pkgs = nixpkgs.legacyPackages.${system};
                                        givenModule = (homeConfigFunc
                                            {
                                                inherit system;
                                                pkgs = nixpkgs.legacyPackages.${system}; 
                                            }
                                        );
                                        setupModule = givenModule // {
                                            home = givenModule.home // {
                                                username = "default";
                                            };
                                        };
                                        config = {
                                            # so user doesn't need to inherit pkgs every time
                                            inherit pkgs;
                                            modules = [
                                                setupModule
                                            ];
                                        };
                                    in 
                                        (home-manager.lib.homeManagerConfiguration 
                                            config
                                        )
                                );
                            };
                        }
                    )
                );
            }
    ;
}