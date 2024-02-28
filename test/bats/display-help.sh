#!/usr/bin/env bats
# -----------------------------------------------------------------------
# Copyright 2024 Open Networking Foundation Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------
# SPDX-FileCopyrightText: 2024 Open Networking Foundation Contributors
# SPDX-License-Identifier: Apache-2.0
# -----------------------------------------------------------------------

# load 'libs/bats-support/load'
# load 'libs/bats-assert/load'

@test "Verify option --help" {
    run bash ../../app-install.sh --fail
    [ "$status" -eq 99 ] # non-zero exit status

    run bash ../../app-install.sh --pass
    [ "$status" -eq 0 ]

#    declare -i result="$(../../app-install.sh --pass)"
#    assert_output -p "Usage app-install.sh"
}

# [SEE ALSO]
# * https://opensource.com/article/19/2/te

# [EOF]
