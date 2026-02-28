#!/usr/bin/env sh

#===============================================
# Project: fpp
# Author:  ConzZah
# Last Modification: 2/27/26 10:30 PM
#===============================================

# shellcheck disable=SC2009 # REASON: pgrep is not POSIX
# shellcheck disable=SC2012 # REASON: THERE ARE NO NON-ALPHANUMERIC FILENAMES WE'D NEED TO WORRY ABOUT 

help () { echo '
===============================
 FPP v1.5 /// ConzZah /// 2026
===============================

OPTIONS:

-m      USE MOST RECENT FIREFOX PROFILE

-p      SPECIFY PATH TO FIREFOX PROFILE

-fr     CREATE FIRSTRUN FLAG

-kill   PUT THE FOX TO REST

-h      SHOW THIS HELP

[URL]   OPEN ANY URL

'; exit ;}

foxes="firefox-esr firefox librewolf"
firefox=""; path2profile="$(pwd)/fpp"
url="about:newtab" ### <-- default url
pathnotfound="--> ERROR: COULDN'T FIND PATH TO PROFILE"

### check if firefox is even installed & exit if it shouldn't be
for fox in $foxes; do
command -v "$fox" >/dev/null && firefox="$fox"; done
[ -z "$firefox" ] && echo "--> ERROR: FIREFOX APPEARS TO BE MISSING." && exit 1

#### PROCESS ARGS ####
while [ "$#" -gt "0" ]; do
case $1 in

m|M'-m'|'-M')
### find the path to the most recently used firefox profile
[ ! -d "$HOME/.mozilla/firefox/" ] && echo "$pathnotfound" && exit 1
path2profile="$(ls -t "$HOME"/.mozilla/firefox/*/compatibility.ini| head -n1| sed 's#compatibility.ini##g')"; shift 
;;

p|P|'-p'|'-P') 
### if the user wants to specify a path to a profile, check if it exists
shift; [ -d "$1" ] && path2profile="$1" && shift || \
[ ! -d "$1" ] && echo "$pathnotfound" && exit 1
;;

k|K|'-kill')
### kill firefox if the user asks for it
[ ! -f ".pid" ] && echo '--> ERROR: NO .PID FILE FOUND' && exit 1
ps -aux| grep -v grep| grep -qo "$(cat .pid)" && \
echo '--> KILLING FIREFOX PROCESS..' && kill -15 "$(cat .pid)"
[ -f ".pid" ] && rm -f .pid; exit
;;

fr|'-fr')
### if $1 is '-fr', create firstrun flag
touch "$path2profile/.fr" && shift
;;

### check if "$1" is pingable and overwrite "$url" if so
*.*) ping -c 1 -W 0.5 "$1" >/dev/null && url="$1"; shift ;; 

### help, when needed
h|'-h'|'help') help ;;
*) help ;;
esac
done

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
ps -aux| grep ".*$firefox.*$path2profile.*"| grep -v '.*grep.*'| tr -s ' '| cut -d ' ' -f 2| head -n1 > .pid
echo "--> PID: $(cat .pid)"
echo "--> RUNNING: $($firefox --version)"
echo "--> LAUNCHING WITH PROFILE @ $path2profile"
