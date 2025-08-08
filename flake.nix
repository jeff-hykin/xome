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
            defaultEnvPassthrough = [ "NIX_SSL_CERT_FILE" "TERM" "XOME_REAL_HOME" "XOME_REAL_PATH" ];
            makeHomeFor = ({ overrideShell ? null, home, pure ? true, envPassthrough ? defaultEnvPassthrough, ... }@args:
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
                            builtins.throw ''Sorry I don't support the shell you selected in home manager (I only support zsh and bash) However you can override this by giving xome.makeHomeFor an argument: overrideShell = system: [ "''${yourShellExecutablePath}" "--no-globalrcs" ]; ''
                    );
                    shellCommandList = (
                        if (shellPackageNameProbably == "zsh") then
                            [ "${pkgs.zsh}/bin/zsh" "--no-globalrcs" ]
                        else if (shellPackageNameProbably == "bash") then
                            [ "${pkgs.bash}/bin/bash" "--noprofile" ]
                        else if (builtins.isFunction overrideShell) then
                            (overrideShell pkgs)
                        else
                            builtins.throw ''Note: this should be unreachable, but as a fallback: Sorry I don't support the shell you selected in home manager (I only support zsh and bash at the moment). However you can override this by giving xome.makeHomeFor an argument: overrideShell = pkgs: [ "''${yourShellExecutablePath}" "--no-globalrcs" ]; ''
                    );
                    shellCommandString = "${lib.concatStringsSep " " (builtins.map lib.escapeShellArg shellCommandList)}";
                    homePath = home.config.home.homeDirectory;
                    envPassthroughFiltered = builtins.filter (envVar: envVar != "PATH" && envVar != "HOME" && envVar != "SHELL") envPassthrough;
                    envPassthroughString = lib.concatStringsSep " " (builtins.map (envVar: lib.escapeShellArg envVar + ''="$'' + envVar + ''"'') envPassthroughFiltered);
                    
                    mainCommand = (
                        if (pure) then
                            ''env -i XOME_ACTIVE=1 PATH=${lib.escapeShellArg homePath}/.local/bin:${lib.escapeShellArg homePath}/bin:${lib.escapeShellArg homePath}/.nix-profile/bin HOME=${lib.escapeShellArg homePath} SHELL=${lib.escapeShellArg (builtins.elemAt shellCommandList 0)} ${envPassthroughString} ${shellCommandString}''
                        else
                            ''XOME_ACTIVE=1 PATH=${lib.escapeShellArg homePath}/.local/bin:${lib.escapeShellArg homePath}/bin:${lib.escapeShellArg homePath}/.nix-profile/bin:"$PATH" HOME=${lib.escapeShellArg homePath} SHELL=${lib.escapeShellArg (builtins.elemAt shellCommandList 0)} ${shellCommandString}''
                    );
                in 
                    {
                        default = pkgs.mkShell {
                            packages = home.config.home.packages;
                            shellHook = ''
                                if [ -n "$XOME_INFER_REAL_PATH" ]
                                then
                                    print '%s' "XOME_PATH_START"
                                    echo
                                    print '%s' "$PATH"
                                    exit
                                elif [ -n "$XOME_INFER_REAL_PATH_DEBUG" ]
                                    what_is_added_to_path_full="$(XOME_INFER_REAL_PATH=true USER=$XOME_REAL_USER PATH="/usr/local/bin:/usr/bin:/bin" ${pkgs.nix}/bin/nix develop 2>/dev/null)"
                                    what_is_added_to_path="$(XOME_INFER_REAL_PATH=true USER=$XOME_REAL_USER PATH="/usr/local/bin:/usr/bin:/bin" ${pkgs.nix}/bin/nix develop 2>/dev/null | ${pkgs.coreutils}/bin/tail -n 1)"
                                    length="''${#what_is_added_to_path}"
                                    path_minus_nix_junk="''${PATH:$length}"
                                    echo 'what_is_added_to_path_full: '"$what_is_added_to_path_full"
                                    echo 'what_is_added_to_path: '"$what_is_added_to_path"
                                    echo 'path_minus_nix_junk: '"$path_minus_nix_junk"
                                else
                                    export XOME_REAL_USER="$USER"
                                    export XOME_REAL_PATH="$PATH"
                                    export XOME_REAL_HOME="$HOME"
                                    export HOME=${lib.escapeShellArg homePath}
                                    mkdir -p "$HOME/.local/state/nix/profiles"
                                    mkdir -p "$HOME/.local/bin"
                                    echo 'PATH="$XOME_REAL_PATH" HOME="$XOME_REAL_HOME" "$@"' > "$HOME/.local/bin/sys"
                                    chmod +x "$HOME/.local/bin/sys"
                                    # note: the grep is to remove common startup noise
                                    USER="default" HOME=${lib.escapeShellArg homePath} ${home.activationPackage.out}/activate 2>&1 | ${pkgs.gnugrep}/bin/grep -v -E "Starting Home Manager activation|warning: unknown experimental feature 'repl-flake'|Activating checkFilesChanged|Activating checkLinkTargets|Activating writeBoundary|No change so reusing latest profile generation|Activating installPackages|warning: unknown experimental feature 'repl-flake'|replacing old 'home-manager-path'|installing 'home-manager-path'|Activating linkGeneration|Cleaning up orphan links from .*|Creating home file links in .*|Activating onFilesChange|Activating setupLaunchAgents"
                                    ${mainCommand}
                                    exit $?
                                fi
                            '';
                        };
                    }
            );
            simpleMakeHomeFor = ({ pkgs, overrideShell ? null, pure ? true, envPassthrough ? defaultEnvPassthrough, homeModule, ... }:
                makeHomeFor {
                    envPassthrough = envPassthrough;
                    overrideShell = overrideShell;
                    pure = pure;
                    home = (
                        let
                            setupModule = homeModule // {
                                home = homeModule.home // {
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
                }
            );
        in
            {
                makeHomeFor = makeHomeFor;
                simpleMakeHomeFor = simpleMakeHomeFor;
                superSimpleMakeHome = {nixpkgs, overrideShell ? null, pure ? true, envPassthrough ? defaultEnvPassthrough}: homeConfigFunc: (flake-utils.lib.eachSystem
                    flake-utils.lib.allSystems
                    (system:
                        {
                            devShells = simpleMakeHomeFor {
                                pkgs = nixpkgs.legacyPackages.${system}; 
                                envPassthrough = envPassthrough; 
                                overrideShell = overrideShell;
                                pure = pure;
                                homeModule = (homeConfigFunc
                                    {
                                        inherit system;
                                        pkgs = nixpkgs.legacyPackages.${system};
                                    }
                                );
                            };
                        }
                    )
                );
            }
    ;
}