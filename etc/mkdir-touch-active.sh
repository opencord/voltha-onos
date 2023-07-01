#!/bin/bash
# -----------------------------------------------------------------------
# Copyright 2023 Open Networking Foundation (ONF) and the ONF Contributors
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

##-------------------##
##---]  GLOBALS  [---##
##-------------------##
set -euo pipefail

umask 022

## -----------------------------------------------------------------------
## Intent: Display an error mesage then exit with shell exit status
## -----------------------------------------------------------------------
function error()
{
    local iam="${BASH_SOURCE[0]}::${FUNCNAME[1]}"
    echo "$iam: ERROR: $*"
    exit 1
}

## -----------------------------------------------------------------------
## Intent: Display a message labeled for the running script
## -----------------------------------------------------------------------
function func_echo()
{
    local iam="${BASH_SOURCE[0]}::${FUNCNAME[1]}"
    echo "$iam: $*"
    return
}

## -----------------------------------------------------------------------
## Intent: Display a message labeled for the running script
## -----------------------------------------------------------------------
function usage()
{
    [[ $# -gt 0 ]] && echo "$*"

    func_echo "USAGE: $0 [args] dir[, .. dir]"
    cat <<EOH
Create a directory structure required for Dockerfile use.
  --debug     Enable debug mode
  --help      This message
EOH
   
    return
}

##----------------##
##---]  MAIN  [---##
##----------------##
func_echo "HELLO"

declare -a dirs=()
while [[ $# -gt 0 ]]; do
    arg="$1"; shift
    case "$arg" in
	-*debug) set -x ;;
	-*help) usage ;;
	-*) error "Detected unknown switch [$arg]" ;;
	*) dirs+=("$arg") ;;
    esac
done

[[ ${#dirs[@]} -eq 0 ]] && {
    usage "At least one directory is required"
    exit 1;
}

for dir in "${dirs[@]}";
do
    active="$dir/active"
    mkdir -p "$dir"
    touch "$active"
done

# find "${dirs[@]}" -ls

# [EOF]
