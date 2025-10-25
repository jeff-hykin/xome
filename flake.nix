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
            defaultHomeSubpathPassthrough = [ "cache/nix/" ];
            makeHomeFor = ({
                overrideShell ? null,
                home,
                pure ? true,
                envPassthrough ? defaultEnvPassthrough,
                commandPassthrough ? defaultCommandPassthrough,
                homeSubpathPassthrough ? defaultHomeSubpathPassthrough,
                _interallyUsedPkgs ? null,
                 ...
            }@args:
                let 
                    pkgs = home.pkgs;
                    commandPassthrough1         = if null != commandPassthrough         then commandPassthrough else [];
                    homeSubpathPassthrough1     = if null != homeSubpathPassthrough     then homeSubpathPassthrough else defaultHomeSubpathPassthrough;
                    interallyUsedPkgs1          = if null != _interallyUsedPkgs         then _interallyUsedPkgs else {};
                    interallyUsedPkgs2 = {
                        coreutils = if (builtins.hasAttr "coreutils" interallyUsedPkgs1) then (interallyUsedPkgs1.coreutils) else (pkgs.coreutils);
                        gnugrep   = if (builtins.hasAttr "gnugrep"   interallyUsedPkgs1) then (interallyUsedPkgs1.gnugrep)   else (pkgs.gnugrep);
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
                        # NOTE: there is a subtle issue with external commands. If the external command is a nix value it will be ignored
                        (eachCommandName: 
                            ''
                                cmd=${lib.escapeShellArg eachCommandName}
                                cmd_path="$(PATH="$XOME_REAL_PATH" command -v "$cmd")"
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
                    homeSubpathPassthroughString = lib.concatStringsSep "\n" (builtins.map
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
                        homeSubpathPassthrough1
                    );
                    baseCommand = "XOME_ACTIVE=1 HOME=${lib.escapeShellArg homePath} SHELL=${lib.escapeShellArg (builtins.elemAt shellCommandList 0)} PATH=${lib.escapeShellArg "${pkgs.nix}/bin/"}:${lib.escapeShellArg homePath}/.local/bin:${lib.escapeShellArg homePath}/bin:${lib.escapeShellArg homePath}/.nix-profile/bin";
                    mainCommand = (
                        if (pure) then
                            ''env -i ${baseCommand} ${envPassthroughString} ${shellCommandString}''
                        else
                            ''${baseCommand}:"$PATH" ${shellCommandString}''
                    );
                in 
                    {
                        default = pkgs.mkShell {
                            packages = home.config.home.packages;
                            shellHook = ''
                                # 
                                # we have to do a lot of work to get the user's real PATH
                                # 
                                
                                # we must recreate the external PATH by figuring out what gets added to the PATH by nix
                                _prefix_finder_value="__PREFIX_FINDER_0249858203"
                                # end this devshell early if just getting the PATH prefix
                                case "$PATH" in
                                    *"$_prefix_finder_value"*) printf '%s' "$PATH"; exit 0;;
                                esac
                                _path_with_prefix="$(PATH="$_prefix_finder_value:$PATH" nix develop --command bash --pure 2>/dev/null)"
                                _path_prefix=""
                                _old_ifs="$IFS"
                                IFS=':'
                                for dir in $_path_with_prefix; do
                                    if [ "$dir" = "$_prefix_finder_value" ]
                                    then
                                        break
                                    fi
                                    _path_prefix="$_path_prefix:$dir"
                                done
                                IFS="$_old_IFS"
                                unset _prefix_finder_value
                                unset _path_with_prefix
                                unset _old_IFS
                                
                                # removal the nix devshell prefix from the PATH to get the real path
                                export XOME_REAL_PATH="$PATH"
                                _i=0
                                while [ "$_i" -lt "''${#_path_prefix}" ]; do
                                    XOME_REAL_PATH="''${XOME_REAL_PATH#?}"  # remove first character
                                    _i=$((_i + 1))
                                done
                                unset _path_prefix
                                unset _i
                                
                                #
                                # everything below is more straightforward
                                #
                                export XOME_REAL_USER="$USER"
                                export XOME_REAL_HOME="$HOME"
                                export XOME_FAKE_HOME=${lib.escapeShellArg homePath}
                                export HOME="$XOME_FAKE_HOME"
                                mkdir -p "$HOME/.local/state/nix/profiles"
                                mkdir -p "$HOME/.local/bin"
                                mkdir -p "$HOME/.cache/"
                                
                                readlink=${lib.escapeShellArg interallyUsedPkgs2.coreutils /* NOTE: commandPassthroughString and homeSubpathPassthroughString depend on this */ }/bin/readlink
                                dirname=${lib.escapeShellArg interallyUsedPkgs2.coreutils /* NOTE: homeSubpathPassthroughString depends on this */ }/bin/dirname
                                ${commandPassthroughString}
                                ${homeSubpathPassthroughString}
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
                                echo 'PATH="$XOME_REAL_PATH" HOME="$XOME_REAL_HOME" "$@"' > "$HOME/.local/bin/sys"
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
                homeSubpathPassthrough ? defaultHomeSubpathPassthrough,
                homeModule,
                _interallyUsedPkgs ? null,
                ... 
            }:
                makeHomeFor {
                    overrideShell = overrideShell;
                    pure = pure;
                    envPassthrough = envPassthrough;
                    commandPassthrough = commandPassthrough;
                    homeSubpathPassthrough = homeSubpathPassthrough;
                    _interallyUsedPkgs = _interallyUsedPkgs;
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
                    homeSubpathPassthrough ? defaultHomeSubpathPassthrough,
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
                                        overrideShell = overrideShell;
                                        pure = pure;
                                        envPassthrough = envPassthrough; 
                                        commandPassthrough = commandPassthrough;
                                        homeSubpathPassthrough = homeSubpathPassthrough;
                                        _interallyUsedPkgs = _interallyUsedPkgs;
                                        homeModule = (homeConfigFunc
                                            {
                                                inherit system;
                                                pkgs = nixpkgs.legacyPackages.${system};
                                            }
                                        );
                                    };
                                }
                            )
                        )
                    )
                );
            }
    ;
}