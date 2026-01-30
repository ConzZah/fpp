#!/usr/bin/env sh

#===============================================
# Project: fpp v1.3
# Author:  ConzZah
# Last Modification: 1/30/26 9:19 AM
#===============================================

echo; echo "== FPP v1.3 =="; echo
path2profile="$(pwd)/fpp"; firefox=""
url="about:newtab" ### <-- default url
### if "$1" seems to be an url,
### treat it as one & overwrite default
echo "$1"| grep -q 'http.*' && url="$1"

### check if firefox is even installed & exit if it shouldn't be
command -v firefox-esr >/dev/null && firefox="firefox-esr"
[ -z "$firefox" ] && command -v firefox >/dev/null && firefox="firefox"
[ -z "$firefox" ] && command -v librewolf >/dev/null && firefox="librewolf"
[ -z "$firefox" ] && echo "--> ERROR: FIREFOX COULD NOT BE FOUND" && exit 1

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
[ "$1" = '-fr' ] && touch "$path2profile/.fr"

### if .fr (firstrun flag) does exist, perform first run
[ -f ".fr"  ] || [ -f "$path2profile/.fr" ] && {
echo '--> PERFORMING FIRST RUN, PLS WAIT..'
rm -f "$path2profile/.fr" ".fr" >/dev/null
rm -f "$path2profile/sessionstore.jsonlz4" >/dev/null
rm -rf "$path2profile/sessionstore-backups" >/dev/null
}

#### LAUNCH ####
launch="$firefox $url --allow-downgrade --profile $path2profile"
[ "$url" != "about:newtab" ] && echo "--> VISITING: $url"
$launch >/dev/null 2>&1 &

### get pid, write it to file, and display it
# shellcheck disable=SC2009 # REASON: pgrep is not POSIX
ps -aux| grep ".*$firefox.*$path2profile.*"| grep -v '.*grep.*'| tr -s ' '| cut -d ' ' -f 2| head -n1 > .pid
echo "--> FIREFOX PID: $(cat .pid)"
echo "--> RUNNING: $($firefox --version)"
echo "--> LAUNCHING WITH PROFILE @ $path2profile"
