#!/usr/bin/env sh

#===============================================
# Project: fpp
# Author:  ConzZah
# Last Modification: 2/3/26 5:20 AM
#===============================================

# shellcheck disable=SC2009 # REASON: pgrep is not POSIX
# shellcheck disable=SC2012 # REASON: THERE ARE NO NON-ALPHANUMERIC FILENAMES WE'D NEED TO WORRY ABOUT

[ "$1" = "-h" ] && echo '
===============================
 FPP v1.4 /// ConzZah /// 2026 
===============================

OPTIONS:

-o      USE YOUR OWN FIREFOX PROFILE

-p      SPECIFY CUSTOM PATH TO FIREFOX PROFILE

-fr     CREATE FIRSTRUN FLAG

-kill   PUT THE FOX TO REST

-h      SHOW THIS HELP

[URL]   OPEN ANY URL

NOTES:

ANY OPTIONS MUST BE SPECIFIED BEFORE THE URL
' && exit 0

pathnotfound="--> ERROR: COULDN'T FIND PATH TO PROFILE"

path2profile="$(pwd)/fpp"; firefox=""
### check if firefox is even installed & exit if it shouldn't be
command -v firefox-esr >/dev/null && firefox="firefox-esr"
[ -z "$firefox" ] && command -v firefox >/dev/null && firefox="firefox"
[ -z "$firefox" ] && command -v librewolf >/dev/null && firefox="librewolf"
[ -z "$firefox" ] && echo "--> ERROR: FIREFOX APPEARS TO BE MISSING." && exit 1

### check if the user wants to use their own profile and
### find the path to the most recently used firefox profile
[ "$1" = "-o" ] && shift && {
[ ! -d "$HOME/.mozilla/firefox/" ] && echo "$pathnotfound" && exit 1
path2profile="$(ls -t "$HOME"/.mozilla/firefox/*/compatibility.ini| head -n1| sed 's#compatibility.ini##g')"
}

### check if the user wants to specify a custom path to a profile
[ "$1" = '-p' ] && shift && {
path2profile="$1"
[ ! -d "$path2profile" ] && \
echo "$pathnotfound" && exit 1
}

### kill firefox if the user asks for it
[ "$1" = "-kill" ] && {
[ ! -f ".pid" ] && echo '--> ERROR: NO .PID FILE FOUND' && exit 1
ps -aux| grep -v grep| grep -qo "$(cat .pid)" && \
echo '--> KILLING FIREFOX PROCESS..' && kill -15 "$(cat .pid)"
[ -f ".pid" ] && rm -f .pid; exit
}

### if $path2profile couldn't be found, and is equal to the default,
### check if the 7z archive is present, if not, download & extract it, and create .fr
[ ! -d "$path2profile" ] && [ "$path2profile" = "$(pwd)/fpp" ] && {
[ ! -f "fpp.7z" ] && command -v curl >/dev/null && echo '--> DOWNLOADING fpp.7z' && \
curl -#LO 'https://github.com/ConzZah/fpp/raw/refs/heads/main/fpp.7z'
7z x -y "fpp.7z" && touch "$path2profile/.fr"
}

### check again, so we don't try to load something that's not there
[ ! -d "$path2profile" ] && { echo "--> ERROR: COULDN'T FIND PATH TO PROFILE"; exit 1 ;}

### delete addonStartup.json.lz4, to make addon/extension paths fix themselves
rm -f "$path2profile/addonStartup.json.lz4" >/dev/null

### if $1 is '-fr', create firstrun flag
[ "$1" = '-fr' ] && touch "$path2profile/.fr" && shift

### if .fr (firstrun flag) does exist, perform first run
[ -f ".fr"  ] || [ -f "$path2profile/.fr" ] && {
echo '--> PERFORMING FIRST RUN, PLS WAIT..'
rm -f "$path2profile/.fr" ".fr" >/dev/null
rm -f "$path2profile/sessionstore.jsonlz4" >/dev/null
rm -rf "$path2profile/sessionstore-backups" >/dev/null
}

url="about:newtab" ### <-- default url
### if "$1" seems to be an url,
### treat it as one & overwrite default
echo "$1"| grep -q '.*://.*' && url="$1"

#### LAUNCH ####
launch="$firefox $url --allow-downgrade --profile $path2profile"
[ "$url" != "about:newtab" ] && echo "--> VISITING: $url"
$launch >/dev/null 2>&1 &

### get pid, write it to file, and display it
ps -aux| grep ".*$firefox.*$path2profile.*"| grep -v '.*grep.*'| tr -s ' '| cut -d ' ' -f 2| head -n1 > .pid
echo "--> PID: $(cat .pid)"
echo "--> RUNNING: $($firefox --version)"
echo "--> LAUNCHING WITH PROFILE @ $path2profile"
