#!/bin/bash
# Copyright 2021-2024 Open Networking Foundation (ONF) and the ONF Contributors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

pgm_dir="${BASH_SOURCE[0]%/*}"
cd "$pgm_dir/.."

NEW_VERSION="$(head -n1 'VERSION')"

if [[ "$NEW_VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]
then
  echo "Version string '$NEW_VERSION' is a SemVer released version!"
  declare -i SNAPSHOTS
  SNAPSHOTS=$(grep --count "SNAPSHOT" 'dependencies.xml')
  if [[ $SNAPSHOTS -gt 0 ]]
  then
    echo "ERROR: Referring to -SNAPSHOT apps in a released VERSION"
    exit 1
  fi

elif [[ "$NEW_VERSION" =~ '-dev' ]]; then
    echo "** Developement version detected: $(declare -p NEW_VERSION)"

else
    echo "** Detected odd version string: $(declare -p NEW_VERSION)"
fi
