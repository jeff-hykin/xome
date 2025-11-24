{
    description = "YOUR_PROJECT_NAME";

    inputs = {
        nixpkgs.url      = "github:NixOS/nixpkgs/nixos-unstable";
        flake-utils.url  = "github:numtide/flake-utils";
        lib.url          = "github:jeff-hykin/quick-nix-toolkits";
        xome.url         = "github:jeff-hykin/xome";
        xome.inputs.nixpkgs.follows = "nixpkgs";
        lib.inputs.flakeUtils.follows = "flake-utils";
    };
    outputs = { self, nixpkgs, flake-utils, lib, xome, ... }:
        flake-utils.lib.eachDefaultSystem (system:
            let
                pkgs = import nixpkgs { inherit system; };
                
                # ------------------------------------------------------------
                # 1. all packages (dev/runtime/build-time with flags for what each package is needed for)
                # ------------------------------------------------------------
                aggregation = lib.aggregator [
                    # interactive stuff (things you probably want)
                    { vals.pkg=pkgs.gnugrep;            flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.findutils;          flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.wget;               flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.curl;               flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.locale;   flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.more;     flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.ps;       flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.getopt;   flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.ifconfig; flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.hostname; flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.ping;     flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.hexdump;  flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.killall;  flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.mount;    flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.sysctl;   flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.top;      flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.unixtools.umount;   flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.git;                flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.htop;               flags={ devShellOnly=true; }; }
                    { vals.pkg=pkgs.ripgrep;            flags={ devShellOnly=true; }; }
                    
                    # vital stuff
                    { vals.pkg=pkgs.coreutils-full;     flags={ }; }
                    { vals.pkg=pkgs.stdenv.cc.cc.lib;   flags={ ldLibraryGroup=true; }; }
                    {
                        # "sh" executable
                        flags = {};
                        vals = {
                            pkg=pkgs.dash;
                            shellHook = ''
                                # lots of things need "sh"
                                ln -s "$(which dash)" "$HOME/.local/bin/sh" 2>/dev/null
                            '';
                        };
                    }

                    ### Python
                    { vals.pkg=pkgs.python312;                    flags={ }; }
                    { vals.pkg=pkgs.python312Packages.pip;        flags={ }; }
                    { vals.pkg=pkgs.python312Packages.setuptools; flags={ }; }
                    { vals.pkg=pkgs.python312Packages.virtualenv; flags={ }; }
                    { vals.pkg=pkgs.sqlite;                       flags={ }; }
                    {
                        vals.shellHook = ''
                            # 
                            # python venv setup
                            # 
                            __temp_project_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
                            if [ -f "$__temp_project_root/venv/bin/activate" ]; then
                                # if there is a venv, load it
                                _nix_python_path="$(realpath "$(which python)")"
                                . "$__temp_project_root/venv/bin/activate"
                                # check the venv to make sure it wasn't created with a different (non nix) python
                                if [ "$_nix_python_path" != "$(realpath "$(which python)")" ]
                                then
                                        echo
                                        echo
                                        echo "WARNING:"
                                        echo "     Your venv was created with something other than the current nix python"
                                        echo "     This could happen if you made the venv before doing `nix develop`"
                                        echo "     It could also happen if the nix-python was updated but the venv wasn't"
                                        echo "     WHAT YOU NEED TO DO:"
                                        echo "     - If you're about to make/test a PR, delete/rename your venv and run `nix develop` again" 
                                        echo "     - If you're just trying to get the code working, you can continue but you might get bugs FYI" 
                                        echo
                                        echo
                                        echo "Got it? (press enter)"; read _
                                        echo
                                fi
                            else
                                ANSWER="y"
                                # if interactive, ask the question
                                if case "$-" in *i*) true;; *) false;; esac; then
                                    echo "I don't see a python virtual environment. Want me to set it up? [y/n]";read ANSWER;echo
                                fi
                                if [ "$ANSWER" =~ ^[Yy] ]; then
                                    echo "Setting up virtualenv..."
                                    python3 -m venv "$__temp_project_root/venv"
                                    echo "Activating virtualenv..."
                                    . "$__temp_project_root/venv"
                                    # check if file exists
                                    if [ -f "$__temp_project_root/pyproject.toml" ]; then
                                        echo "installing python dependencies from pyproject.toml ..."
                                        pip install -e .
                                    elif [ -f "./requirements.txt" ]; then
                                        echo "installing python dependencies from requirements.txt ..."
                                        pip install -r ./requirements.txt
                                    fi
                                else
                                    echo "okay skipping"  
                                fi
                            fi
                            unset __temp_project_root
                        '';
                    }

                    # ### Runtime deps for python
                    # { vals.pkg=pkgs.python312Packages.pyaudio; flags={}; }
                    # { vals.pkg=pkgs.portaudio;                 flags={}; }
                    # { vals.pkg=pkgs.ffmpeg_6;                  flags={}; }
                    # { vals.pkg=pkgs.ffmpeg_6.dev;              flags={}; }
                    
                    # ### Graphics / X11 stack
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.libGL;              flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.libGLU;             flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.mesa;               flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.glfw;               flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libX11;        flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXi;         flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXext;       flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXrandr;     flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXinerama;   flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXcursor;    flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXfixes;     flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXrender;    flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXdamage;    flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXcomposite; flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libxcb;        flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXScrnSaver; flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.xorg.libXxf86vm;    flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.udev;               flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.SDL2;               flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.SDL2.dev;           flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.zlib;               flags={ ldLibraryGroup=true; }; }

                    # ### GTK / OpenCV helpers
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.glib;                  flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.gtk3;                  flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.gdk-pixbuf;            flags={ ldLibraryGroup=true; }; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.gobject-introspection; flags={ ldLibraryGroup=true; }; }
                    
                    # ### GStreamer
                    # { vals.pkg=pkgs.gst_all_1.gstreamer;          flags={ ldLibraryGroup=true; }; flags.giTypelibGroup=true; }
                    # { vals.pkg=pkgs.gst_all_1.gst-plugins-base;   flags={ ldLibraryGroup=true; }; flags.giTypelibGroup=true; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.gst_all_1.gst-plugins-good;   flags={}; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.gst_all_1.gst-plugins-bad;    flags={}; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.gst_all_1.gst-plugins-ugly;   flags={}; }
                    # { onlyIf=pkgs.stdenv.isLinux; vals.pkg=pkgs.python312Packages.gst-python; flags={}; }

                    # ### Open3D & build-time
                    # { vals.pkg=pkgs.eigen;   flags={}; }
                    # { vals.pkg=pkgs.cmake;   flags={}; }
                    # { vals.pkg=pkgs.ninja;   flags={}; }
                    # { vals.pkg=pkgs.jsoncpp; flags={}; }
                    # { vals.pkg=pkgs.libjpeg; flags={}; }
                    # { vals.pkg=pkgs.libpng;  flags={}; }
                ];
                
                # ------------------------------------------------------------
                # 2. group / aggregate the packages as needed 
                # ------------------------------------------------------------
                buildPackages        = aggregation.getAll { attrPath=[ "pkg" ]; hasNoneOfTheseFlags=[ "devShellOnly" ]; };
                devPackages          = aggregation.getAll { attrPath=[ "pkg" ]; };
                ldLibraryPackages    = aggregation.getAll { attrPath=[ "pkg" ]; hasAllFlags=[ "ldLibraryGroup" ]; };
                aggregatedShellHooks = aggregation.getAll { attrPath=[ "shellHook" ]; strJoin="\n"; };

            in 
                {
                    #
                    # normal dev shell
                    #
                    devShells.default = xome.simpleMakeHomeFor {
                        inherit pkgs;
                        pure = true;
                        commandPassthrough = [ "sudo" "nvim" "code" "sysctl" ]; # e.g. use external nvim instead of nix's
                        # commonly needed for MacOS: [ "osascript" "otool" "hidutil" "logger" "codesign" ]
                        homeSubpathPassthrough = [ "cache/nix/" ]; # share nix cache between projects
                        homeModule = {
                            # for home-manager examples, see: 
                            # https://deepwiki.com/nix-community/home-manager/5-configuration-examples
                            # all home-manager options: 
                            # https://nix-community.github.io/home-manager/options.xhtml
                            home.homeDirectory = "/tmp/virtual_homes/YOUR_PROJECT_NAME";
                            home.stateVersion = "25.11";
                            home.packages = devPackages;
                            
                            programs = {
                                zsh = {
                                    enable = true;
                                    enableCompletion = true;
                                    autosuggestion.enable = true;
                                    syntaxHighlighting.enable = true;
                                    shellAliases.ll = "ls -la";
                                    history.size = 100000;
                                    # this is kinda like .zshrc
                                    initContent = ''
                                        export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath ldLibraryPackages}:$LD_LIBRARY_PATH"
                                        export DISPLAY=":0"
                                        PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
                                        
                                        ${aggregatedShellHooks}
                                    '';
                                };
                                home-manager = {
                                    enable = true;
                                };
                                starship = {
                                    enable = true;
                                    enableZshIntegration = true;
                                    settings = {
                                        character = {
                                            success_symbol = "[▣](bold green)";
                                            error_symbol = "[▣](bold red)";
                                        };
                                    };
                                };
                            };
                        }; 
                    };
                    
                    # 
                    # docker image
                    # 
                    packages.devcontainer = pkgs.dockerTools.buildLayeredImage {
                        name      = "dimensionalos/dimos-dev";
                        tag       = "latest";
                        contents  = [ 
                            pkgs.buildEnv {
                                name = "dimos-image-root";
                                paths = devPackages;
                                pathsToLink = [ "/bin" ];
                            }
                        ];
                        config = {
                            WorkingDir = "/workspace";
                            Cmd        = [ "bash" ];
                        };
                    };
                }
        );
}
