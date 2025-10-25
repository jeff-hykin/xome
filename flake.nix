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
            defaultCommandPassthrough = [];
            defaultRealHomeSubpathPassthrough = [ "cache/nix/" ];
            makeHomeFor = ({
                overrideShell ? null,
                home,
                pure ? true,
                envPassthrough ? defaultEnvPassthrough,
                commandPassthrough ? defaultCommandPassthrough,
                realHomeSubpathPassthrough ? defaultRealHomeSubpathPassthrough,
                _interallyUsedPkgs ? null,
                 ...
            }@args:
                let 
                    pkgs = home.pkgs;
                    commandPassthrough1         = if null != commandPassthrough         then commandPassthrough else [];
                    realHomeSubpathPassthrough1 = if null != realHomeSubpathPassthrough then realHomeSubpathPassthrough else defaultRealHomeSubpathPassthrough;
                    interallyUsedPkgs1          = if null != _interallyUsedPkgs         then _interallyUsedPkgs else {};
                    interallyUsedPkgs2 = {
                        coreutils = if (builtins.hasAttr "coreutils" interallyUsedPkgs1) then (interallyUsedPkgs1.coreutils) else (pkgs.coreutils);
                        gnugrep = if (builtins.hasAttr "gnugrep" interallyUsedPkgs1) then (interallyUsedPkgs1.gnugrep) else (pkgs.gnugrep);
                    };
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
                    commandPassthroughString = lib.concatStringsSep "\n" (builtins.map
                        # NOTE: there is a case where the command doesn't exist (ex: deleted on the host) but the 
                        (eachCommandName: 
                            ''
                                cmd=${lib.escapeShellArg eachCommandName}
                                cmd_path="$(command -v "$cmd")"
                                symlink="$HOME/.local/bin/$cmd"
                                current_target="$("$readlink" -f "$symlink")"
                                if ! [ -x "$current_target" ]; then
                                    current_target=""
                                fi
                                # if command exists
                                if [ -n "$cmd_path" ]; then
                                    # if target is wrong/different replace it
                                    if ! [ "$current_target" = "$cmd_path" ]; then
                                        rm -f "$symlink"
                                        # link it
                                        ln -s "$cmd_path" "$symlink"
                                    fi
                                fi
                            ''
                        )
                        commandPassthrough
                    );
                    realHomeSubpathPassthroughString = lib.concatStringsSep "\n" (builtins.map
                        # NOTE: there is an unhandled risk of the intermediate in a sub-path being a file 
                        # ex: subpath="cache/thing1/thing2" where "cache/thing1" somehow ended up being a file
                        (eachPath:
                            let
                                # trailing slash can change how ln -s works
                                pathNoTrailingSlash = lib.removeSuffix "/" eachPath;
                            in
                                ''
                                    subpath=${lib.escapeShellArg pathNoTrailingSlash}
                                    link_path="$XOME_FAKE_HOME/$subpath"
                                    current_link_target="$("$readlink" -f "$link_path")"
                                    intended_link_target="$XOME_REAL_HOME/$subpath"
                                    # delete broken links
                                    if ! [ -e "$current_link_target"]; then
                                        rm -rf "$link_path"
                                    fi
                                    # link if not set to correct target
                                    if [ "$current_link_target" = "$intended_link_target" ]
                                    then
                                        rm -rf "$link_path"
                                        mkdir -p "$("$dirname" "$link_path")"
                                        ln -s "$XOME_REAL_HOME/$subpath" "$link_path"
                                    fi
                                ''
                        )
                        realHomeSubpathPassthrough1
                    );
                    baseCommand = "XOME_ACTIVE=1 HOME=${lib.escapeShellArg homePath} SHELL=${lib.escapeShellArg (builtins.elemAt shellCommandList 0)} PATH=${lib.escapeShellArg "${pkgs.nix}/bin/"}:${lib.escapeShellArg homePath}/.local/bin:${lib.escapeShellArg homePath}/bin:${lib.escapeShellArg homePath}/.nix-profile/bin";
                    mainCommand = (
                        if (pure) then
                            ''env -i ${baseCommand} ${envPassthroughString} ${shellCommandString}''
                        else
                            ''${baseCommand}:"$PATH" ${shellCommandString}''
                    );
                    escapeShellArg1 = arg: if (builtins.isString arg) then lib.escapeShellArg arg else lib.escapeShellArg (builtins.toString arg);
                in 
                    {
                        default = pkgs.mkShell {
                            packages = home.config.home.packages;
                            shellHook = ''
                                export XOME_REAL_USER="$USER"
                                export XOME_REAL_PATH="$PATH"
                                export XOME_REAL_HOME="$HOME"
                                export XOME_FAKE_HOME=${escapeShellArg1 homePath}
                                export HOME="$XOME_FAKE_HOME"
                                mkdir -p "$HOME/.local/state/nix/profiles"
                                mkdir -p "$HOME/.local/bin"
                                mkdir -p "$HOME/.cache/"
                                
                                # setup command passthrough
                                readlink=${lib.escapeShellArg interallyUsedPkgs2.coreutils /* NOTE: commandPassthroughString and realHomeSubpathPassthroughString depend on this */ }/bin/readlink
                                dirname=${lib.escapeShellArg interallyUsedPkgs2.coreutils /* NOTE: realHomeSubpathPassthroughString depends on this */ }/bin/dirname
                                ${commandPassthroughString}
                                ${realHomeSubpathPassthroughString}
                                # keep env clean
                                unset readlink
                                unset dirname
                                unset subpath
                                unset link_path
                                unset current_link_target
                                unset intended_link_target
                                unset cmd
                                unset cmd_path
                                unset symlink
                                unset current_target
                                # must hardcode standard paths (missing stuff like /opt/homebrew/bin:/opt/homebrew/sbin:/opt/X11/bin on Mac and stuff like /snap/bin on Ubuntu)
                                # because XOME_REAL_PATH is already polluted with stuff from the nix flake. Its hard to undo that without making a wrapper around `nix develop`
                                # we need this prefix because we want `sys THING` to default to the system thing, not the nix flake thing
                                echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:"$HOME/.nix-profile/bin":/nix/var/nix/profiles/default/bin/:/nix/var/nix/profiles/per-user/$USER/profile/bin/:$XOME_REAL_PATH" HOME="$XOME_REAL_HOME" "$@"' > "$HOME/.local/bin/sys"
                                chmod +x "$HOME/.local/bin/sys"
                                # note: the grep is to remove common startup noise
                                USER="default" HOME=${lib.escapeShellArg homePath} ${home.activationPackage.out}/activate 2>&1 | ${interallyUsedPkgs2.gnugrep}/bin/grep -v -E "Starting Home Manager activation|warning: unknown experimental feature 'repl-flake'|Activating checkFilesChanged|Activating checkLinkTargets|Activating writeBoundary|No change so reusing latest profile generation|Activating installPackages|warning: unknown experimental feature 'repl-flake'|replacing old 'home-manager-path'|installing 'home-manager-path'|Activating linkGeneration|Cleaning up orphan links from .*|Creating home file links in .*|Activating onFilesChange|Activating setupLaunchAgents"
                                ${mainCommand}
                                exit $?
                            '';
                        };
                    }
            );
            simpleMakeHomeFor = ({
                pkgs,
                overrideShell ? null,
                pure ? true,
                envPassthrough ? defaultEnvPassthrough,
                commandPassthrough ? defaultCommandPassthrough,
                homeModule,
                realHomeSubpathPassthrough ? defaultRealHomeSubpathPassthrough,
                _interallyUsedPkgs ? null,
                ... 
            }:
                makeHomeFor {
                    envPassthrough = envPassthrough;
                    commandPassthrough = commandPassthrough;
                    overrideShell = overrideShell;
                    realHomeSubpathPassthrough = realHomeSubpathPassthrough;
                    _interallyUsedPkgs = _interallyUsedPkgs;
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
                superSimpleMakeHome = ({
                    nixpkgs,
                    overrideShell ? null,
                    pure ? true,
                    envPassthrough ? defaultEnvPassthrough,
                    commandPassthrough ? defaultCommandPassthrough,
                    realHomeSubpathPassthrough ? defaultRealHomeSubpathPassthrough,
                    _interallyUsedPkgs ? null,
                    ...
                }: 
                    (homeConfigFunc: 
                        (flake-utils.lib.eachSystem
                            flake-utils.lib.allSystems
                            (system:
                                {
                                    devShells = simpleMakeHomeFor {
                                        pkgs = nixpkgs.legacyPackages.${system}; 
                                        envPassthrough = envPassthrough; 
                                        commandPassthrough = commandPassthrough;
                                        realHomeSubpathPassthrough = realHomeSubpathPassthrough;
                                        overrideShell = overrideShell;
                                        pure = pure;
                                        homeModule = (homeConfigFunc
                                            {
                                                inherit system;
                                                pkgs = nixpkgs.legacyPackages.${system};
                                            }
                                        );
                                        _interallyUsedPkgs = _interallyUsedPkgs;
                                    };
                                }
                            )
                        )
                    )
                );
            }
    ;
}