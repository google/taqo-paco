#!/bin/bash

# Copyright 2021 Google LLC
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

# Fail on any error.
set -e

read_config_value() {
    (grep -E "^${2}=" -m 1 "${1}" 2>/dev/null || echo "VAR= INVALID_KEY") | head -n 1 | cut -d '=' -f 2-;
}
value=""
get_value() {
    value="$(read_config_value deps.cfg "${1}")";
}
