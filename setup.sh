# Note: this script isnt as cursed as it looks, its actually MUCH more cursed than it looks. God I hate POSIX
_temp="$(mktemp)"
printf "%s" '#!/usr/bin/env sh
"\"",`$(echo --% '"'"' |out-null)" >$null;function :{};function dv{<#${/*'"'"'>/dev/null )` 2>/dev/null;dv() { #>
echo "2.2.11"; : --% '"'"' |out-null <#'"'"'; }; echo "one moment... bootstrapping here"; deno_version="$(dv)"; deno="$HOME/.deno/$deno_version/bin/deno"; if [ -x "$deno" ];then  exec "$deno" run -q -A --no-lock --no-config "$0" "$@";  elif [ -f "$deno" ]; then  chmod +x "$deno" && exec "$deno" run -q -A --no-lock --no-config "$0" "$@"; fi; has () { command -v "$1" >/dev/null; };  set -e;  if ! has unzip && ! has 7z; then echo "Can I try to install unzip for you? (its required for this command to work) ";read ANSWER;echo;  if [ "$ANSWER" =~ ^[Yy] ]; then  if ! has brew; then  brew install unzip; elif has apt-get; then if [ "$(whoami)" = "root" ]; then  apt-get install unzip -y; elif has sudo; then  echo "I'"'"'m going to try sudo apt install unzip";read ANSWER;echo;  sudo apt-get install unzip -y;  elif has doas; then  echo "I'"'"'m going to try doas apt install unzip";read ANSWER;echo;  doas apt-get install unzip -y;  else apt-get install unzip -y;  fi;  fi;  fi;   if ! has unzip; then  echo ""; echo "So I couldn'"'"'t find an '"'"'unzip'"'"' command"; echo "And I tried to auto install it, but it seems that failed"; echo "(This script needs unzip and either curl or wget)"; echo "Please install the unzip command manually then re-run this script"; exit 1;  fi;  fi;   if ! has unzip && ! has 7z; then echo "Error: either unzip or 7z is required to install Deno (see: https://github.com/denoland/deno_install#either-unzip-or-7z-is-required )." 1>&2; exit 1; fi;  if [ "$OS" = "Windows_NT" ]; then target="x86_64-pc-windows-msvc"; else case $(uname -sm) in "Darwin x86_64") target="x86_64-apple-darwin" ;; "Darwin arm64") target="aarch64-apple-darwin" ;; "Linux aarch64") target="aarch64-unknown-linux-gnu" ;; *) target="x86_64-unknown-linux-gnu" ;; esac fi;  print_help_and_exit() { echo "Setup script for installing deno  Options: -y, --yes Skip interactive prompts and accept defaults --no-modify-path Don'"'"'t add deno to the PATH environment variable -h, --help Print help " echo "Note: Deno was not installed"; exit 0; };  for arg in "$@"; do case "$arg" in "-h") print_help_and_exit ;; "--help") print_help_and_exit ;; "-"*) ;; *) if [ -z "$deno_version" ]; then deno_version="$arg"; fi ;; esac done; if [ -z "$deno_version" ]; then deno_version="$(curl -s https://dl.deno.land/release-latest.txt)"; fi;  deno_uri="https://dl.deno.land/release/v${deno_version}/deno-${target}.zip"; deno_install="${DENO_INSTALL:-$HOME/.deno/$deno_version}"; bin_dir="$deno_install/bin"; exe="$bin_dir/deno";  if [ ! -d "$bin_dir" ]; then mkdir -p "$bin_dir"; fi;  if has curl; then curl --fail --location --progress-bar --output "$exe.zip" "$deno_uri"; elif has wget; then wget --output-document="$exe.zip" "$deno_uri"; else echo "Error: curl or wget is required to download Deno (see: https://github.com/denoland/deno_install )." 1>&2; fi;  if has unzip; then unzip -d "$bin_dir" -o "$exe.zip"; else 7z x -o"$bin_dir" -y "$exe.zip"; fi; chmod +x "$exe"; rm "$exe.zip";  exec "$deno" run -q -A --no-lock --no-config "$0" "$@";     #>}; $DenoInstall = "${HOME}/.deno/$(dv)"; $BinDir = "$DenoInstall/bin"; $DenoExe = "$BinDir/deno.exe"; if (-not(Test-Path -Path "$DenoExe" -PathType Leaf)) { $DenoZip = "$BinDir/deno.zip"; $DenoUri = "https://github.com/denoland/deno/releases/download/v$(dv)/deno-x86_64-pc-windows-msvc.zip";  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;  if (!(Test-Path $BinDir)) { New-Item $BinDir -ItemType Directory | Out-Null; };  Function Test-CommandExists { Param ($command); $oldPreference = $ErrorActionPreference; $ErrorActionPreference = "stop"; try {if(Get-Command "$command"){RETURN $true}} Catch {Write-Host "$command does not exist"; RETURN $false}; Finally {$ErrorActionPreference=$oldPreference}; };  if (Test-CommandExists curl) { curl -Lo $DenoZip $DenoUri; } else { curl.exe -Lo $DenoZip $DenoUri; };  if (Test-CommandExists curl) { tar xf $DenoZip -C $BinDir; } else { tar -Lo $DenoZip $DenoUri; };  Remove-Item $DenoZip;  $User = [EnvironmentVariableTarget]::User; $Path = [Environment]::GetEnvironmentVariable('"'"'Path'"'"', $User); if (!(";$Path;".ToLower() -like "*;$BinDir;*".ToLower())) { [Environment]::SetEnvironmentVariable('"'"'Path'"'"', "$Path;$BinDir", $User); $Env:Path += ";$BinDir"; } }; & "$DenoExe" run -q -A --no-lock --no-config "$PSCommandPath" @args; Exit $LastExitCode; <# 
# */0}`;
import $ from "https://esm.sh/@jsr/david__dax@0.43.2/mod.ts"
import { version } from '"'"'https://esm.sh/gh/jeff-hykin/good-js@1.17.2.0/source/flattened/version.js'"'"'
import { FileSystem, glob } from "https://deno.land/x/quickr@0.8.4/main/file_system.js"
import { pickFile, pickDirectory } from "https://esm.sh/jsr/@ayonli/jsext@1.8.0/dialog.ts"
const $$ = (...args)=>$(...args).noThrow()

console.log("Great, got past the hard-ish part now lets take a look at your system")
const repo = Deno.env.get("repo")
if (!repo) {
    throw new Error("Looks like setup was called, but no repo was given for me to setup. I need that!")
}
const defaultNixVersionString = Deno.env.get("defaultNixVersion") || "2.18.1" // FIXME: this will be overridden with a CLI argument

const shellEscape = (arg)=>{
    if (arg.match(/^[a-zA-Z0-9_/.-]+$/)) {
        return arg
    }
    return `'"'"'${arg.replace(/'"'"'/g,`'"'"'"'"'"'"'"'"'`)}'"'"'`
}

async function getUsername() {
    let whoami
    try {
        // whoami is harder to fool than USER
        whoami = (await $`whoami 2>/dev/null`.text())
    } catch (error) {
        whoami = Deno.env.get("USER")
    }
}

async function getNixVersionString() {
    return (await $$`nix --version`.text("combined")).replace(/nix \(Nix\) /,"").trim()
}

function getNameFromUrl(urlString) {
    // "https://github.com/jeff-hykin/xome.git" => "xome"
    // "git@github.com:jeff-hykin/xome.git" => "xome"
    // "https://github.com/jeff-hykin/adlkfjalskj.adf.a,.42,42.fadfadlk;kd;'"'"''"'"')(&$)(;lfdka" => "adlkfjalskj_adf_a_42_42_fadfadlk_kd_lfdka"
    const nameString = urlString.replace(/\/+$/,"").split("/").pop().replace(/\.git$/,"").split(/[^a-zA-Z0-9_-]*(?<![a-zA-Z0-9_-])(?=[a-zA-Z0-9_-]+)/).join("_")
    if (nameString.length > 0) {
        return nameString
    } else {
        return "untitled_project"
    }
}

// 
// setup nix path, even if it isn'"'"'t active yet
// 
let PATH = Deno.env.get("PATH")
let HOME = Deno.env.get("HOME")
const username = await getUsername()
PATH=`${PATH}:${HOME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin/:/nix/var/nix/profiles/per-user/${username}/profile/bin/`
Deno.env.set("PATH", PATH)

// 
// check for nix
// 
let nixVersionString = await getNixVersionString()
let nixExists = nixVersionString.match(/^\d+\.\d+/)
if (!nixExists) {
    const installCommand = `curl -L https://install.determinate.systems/nix | bash -s -- --nix-version ${defaultNixVersionString}`
    if (confirm(`\nNix not found, can I install it?\nIts necessary for this setup\nI would be running the following command:\n${installCommand}`)) {
        await $.raw`${installCommand}`
    }
    // check again (because we'"'"'ve already added to the PATH it should show up here)
    nixVersionString = await getNixVersionString()
    nixExists = nixVersionString.match(/^\d+\.\d+/)
    if (!nixExists) {
        throw new Error("Well the install command was run, but I didn'"'"'t see nix in the output. Please install nix manually and try again")
    }
} else {
    console.log("    I see you have nix, good")
}

// 
// nix must exist at this point
// 
const nixVersion = version(nixVersionString)
if (nixVersion.isLessThan(defaultNixVersionString)) {
    if (!confirm(`\nYour nix version is older than the one used for this project (${defaultNixVersionString})\nDo you want to continue anyways?`)) {
        console.log(`Okay, please update nix: https://nix.dev/manual/nix/2.28/installation/upgrading.html then try again`)
        Deno.exit(1)
    }
}

// 
// make sure flakes are enabled
// 
const hasFlakesEnabled = (await $$`nix flake show`.cwd("/").text("combined")).match(/\n*error: could not find a flake\.nix file/)
let nixCommand = ["nix"]
if (!hasFlakesEnabled) {
    nixCommand.push(
        "--extra-experimental-features",
        "nix-command flakes",
    )
}

// 
// run self with a git shell
// 
const repoName = getNameFromUrl(repo)
console.log(`\nI need to download ${JSON.stringify(repoName)} to a folder`)
prompt("Which folder should I download it to?\n(press enter and I'"'"'ll open a file dialog)")
let directory
selectDirectoryLoop: while (true) {
    try {
        directory = await pickDirectory()
        break
    } catch (error) {
        if (confirm("Did that crash? (Say no if you cancelled)")) {
            console.log("\nOkay, so I guess my fancy folder picker failed.")
            while (1) {
                directory = prompt("\nPlease paste the path to the folder you want to download the project to then press enter:")
                if (!FileSystem.sync.info(directory).exists) {
                    console.log(`That does not seem to be a folder, please try again`)
                } else {
                    break selectDirectoryLoop
                }
            }
        } else {
            prompt("Oh okay, well sorry I need a directory to download the project to.\nPress ctrl+C if you want to cancel, otherwise press enter to try again")
        }
    }
}

// 
// try to clone
// 
if (repo.endsWith(".git")) {
    repo.slice(0,-4)
}
let chosenName = repoName
let targetFolder
let targetInfo
while (true) {
    targetFolder = `${directory}/${chosenName}`
    targetInfo = await FileSystem.info(targetFolder)
    if (targetInfo.exists) {
        if (confirm(`\nThe name ${JSON.stringify(chosenName)} already exists in the folder you picked\nDo you want to delete it so this can be downloaded?`)) {
            await FileSystem.remove(targetFolder)
        } else {
            prompt("Please enter a new name for the project")
            chosenName = (await prompt()).trim()
        }
    } else {
        break
    }
}
console.log(`Downloading ${JSON.stringify(chosenName)} to ${JSON.stringify(targetFolder)}`)
await $$`nix run "github:NixOS/nixpkgs/25.05#git" clone ${repo} ${targetFolder}`

// 
// try to develop
// 
console.log(``)
console.log(``)
console.log(`Alright this setup script is over!`)
console.log(`Next time, all you need to run is the following Okay?\n(I'll run them once you press enter)`)
console.log(`    cd ${targetFolder}`)
console.log(`    ${nixCommand.map(shellEscape).join(" ")} develop`)
console.log(``)
prompt(``)
Deno.chdir(targetFolder)
let { code } = await $$`${nixCommand} develop`
Deno.exit(code)
' > "$_temp"
export repo
export defaultNixVersion
chmod +x "$_temp"
sh "$_temp"