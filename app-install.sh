#!/bin/bash
# -----------------------------------------------------------------------
# Copyright 2017-2024 Open Networking Foundation Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------
# SPDX-FileCopyrightText: 2017-2024 Open Networking Foundation Contributors
# SPDX-License-Identifier: Apache-2.0
# -----------------------------------------------------------------------

##-------------------##
##---]  GLOBALS  [---##
##-------------------##
set -euo pipefail
umask 022

## -----------------------------------------------------------------------
## Intent: Display a stack trace on error
## -----------------------------------------------------------------------
function errexit()
{
    local err=$?
    set +o xtrace
    local code="${1:-1}"

    local prefix="${BASH_SOURCE[1]}:${BASH_LINENO[1]}"
    echo -e "\nOFFENDER: ${prefix}"
    if [ $# -gt 0 ] && [ "$1" == '--stacktrace-quiet' ]; then
        code=1
    else
        echo "ERROR: '${BASH_COMMAND}' exited with status $err"
    fi

    # Print out the stack trace described by $function_stack
    if [ ${#FUNCNAME[@]} -gt 2 ]
    then
	    echo "Call tree:"
	    for ((i=1;i<${#FUNCNAME[@]}-1;i++))
	    do
	        echo " $i: ${BASH_SOURCE[$i+1]}:${BASH_LINENO[$i]} ${FUNCNAME[$i]}(...)"
	    done
    fi

    echo "Exiting with status ${code}"
    echo
    exit "${code}"
}
trap 'errexit' ERR

## -----------------------------------------------------------------------
## Intent: Display an error mesage then exit with shell exit status
## -----------------------------------------------------------------------
function error()
{
    echo "${BASH_SOURCE[0]} ERROR: $*"
    exit 1
}

## -----------------------------------------------------------------------
## Intent: Verify required environment variables are set
## -----------------------------------------------------------------------
## TODO: Covert into command line args
## -----------------------------------------------------------------------
# shellcheck disable=SC2120
function init()
{
    declare -a vars=()
    vars+=('APP_INSTALL_ROOT')
    vars+=('APPS_ROOT')
    vars+=('DOWNLOAD_ROOT')
    vars+=('KARAF_M2')

    local var
    for var in "${vars[@]}";
    do
        [[ ! -v "$var" ]] && { error "EnvVar ${var}= is required"; }
    done

    cat <<EOM

** -----------------------------------------------------------------------
** Running: $0 $@
** -----------------------------------------------------------------------
** $(declare -p APP_INSTALL_ROOT)
** $(declare -p APPS_ROOT)
** $(declare -p DOWNLOAD_ROOT)
** -----------------------------------------------------------------------
** $(declare -p KARAF_M2)
** -----------------------------------------------------------------------
EOM

    return
}

## -----------------------------------------------------------------------
## Intent: Gather artifact *.oar files to unpack
## -----------------------------------------------------------------------
## GIVEN
##   ref   An indirect array variable to return values through.
##   dir   Directory to glob *.oar files from
## -----------------------------------------------------------------------
function get_oar_files()
{
    local -n ref=$1 ; shift
    local dir="$1"  ; shift

    readarray -t oars < <(find "$dir" -name '*.oar' -type f -print)
    [[ ${#oars[@]} -eq 0 ]] && { error "No \*.oar files detected in $dir"; }

    # shellcheck disable=SC2034
    ref=("${oars[@]}")
    return
}

## -----------------------------------------------------------------------
## Intent: Display program usage
## -----------------------------------------------------------------------
function usage()
{
    if [[ $# -gt 0 ]]; then
        printf "\n** $@\n"
    fi

    cat <<__HELP__
Usage: ${BASH_SOURCE[0]##*/}
  --download                 Holding directory for downloaded oar files
  --install                  Unpack and install app files into this directory

[Test Helpers]
  --fail                     Force script exit with status fail ($?==99)
  --pass                     Force script exit with status pass ($?==0)

  --debug                    Enable debug mode.
  --help                     Display program usage.
__HELP__

    return
}

##-------------------##
##---]  GETOPTS  [---##
##-------------------##

declare arg
while [[ $# -gt 0 ]]; do
    arg="$1"; shift
    case "$arg" in
        '--debug') declare -g -i debug=1 ;;
        '--down'*)
            arg="$1"; shift
            [[ ! -e "$arg" ]] && { error "--download $arg does not exist"; }
            export DOWNLOAD_ROOT="$arg"
            ;;
        '--inst'*)
            arg="$1"; shift
            [[ ! -e "$arg" ]] && { error "--install $arg does not exist"; }
            export APP_INSTALL_ROOT="$arg"
            ;;
        '--fail') exit 99 ;;
        '--pass') exit 0 ;;
        '--help') usage; exit 0 ;;
        *) echo "[SKIP] Unknown argument [$arg]" ;;
    esac
done

##----------------##
##---]  MAIN  [---##
##----------------##
init

declare -a oars
get_oar_files oars "$DOWNLOAD_ROOT"

for oar in "${oars[@]}"; do

    # app_xml="$APP_INSTALL_ROOT/app.xml"
    app_xml='app.xml'
    oar_basename="${oar##*/}"    # bash builtin

    cat <<EOF

** -----------------------------------------------------------------------
** Artifact: ${oar}
** Basename: ${oar_basename}
** -----------------------------------------------------------------------
EOF

    echo "Installing application '${oar##*/}'"
    rm -rf "$APP_INSTALL_ROOT"
    mkdir -p "$APP_INSTALL_ROOT"

    rsync --checksum "$oar" "$APP_INSTALL_ROOT/."

    ## pushd()/popd(): cd $here && cd $root w/error checking
    pushd "$APP_INSTALL_ROOT" >/dev/null \
        || { error "pushd failed: $APP_INSTALL_ROOT"; }

    [[ -v debug ]] && { echo "** Installing: $oar"; }

    unzip -oq -d . "${oar_basename}"

    # ------------------------------------------------------------
    # [IN]  <app name="org.opencord.kafka" origin="ONF" version="2.13.2"
    # [OUT] declare -a names=([0]="org.opencord.kafka")
    # ------------------------------------------------------------
    readarray -t names < <(grep 'name=' "$app_xml" \
                               | sed 's/<app name="//g;s/".*//g')

    if [[ ${#names[@]} -eq 0 ]]; then
        echo
        echo "APP_XML FILE: $APP_INSTALL/${app_xml}"
        cat "$app_xml"

        cat <<ERR

** -----------------------------------------------------------------------
**  FILE: $APP_INSTALL/${app_xml}
**  GREP: $(grep 'name=' "$app_xml")
**   SED: $(grep 'name=' "$app_xml" | sed 's/<app name="//g;s/".*//g')
** ERROR: Detected invalid app_xml=${app_xml} name gathering.
** NAMES: $(declare -p names)
** -----------------------------------------------------------------------
ERR
        exit 1
    fi

    printf '** %s\n' "$(declare -p names)"
    name="${names[0]}"
    apps_name="$APPS_ROOT/$name"

    mkdir -p "$apps_name"
    rsync -v --checksum "$app_xml" "${apps_name}/app.xml"

    touch "${apps_name}/active" # what is this used for (?)

    declare app_png="$APP_INSTALL_ROOT/app.png"
    [ -f "$app_png" ] && { rsync -v --checksum "$app_png" "${apps_name}/."; }
    rsync -v "${oar_basename}" "${apps_name}/${name}.oar"

    popd >/dev/null || { error "popd failed: $APP_INSTALL_ROOT"; }

    rsync -rv --checksum "$APP_INSTALL_ROOT/m2/." "$KARAF_M2/."
    rm -rf "$APP_INSTALL_ROOT"

done

# [EOF]
