# Copyright 2023 Google LLC
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

# Avoid duplicate inclusion
if [[ -n "${taqo_logger_imported:-}" ]]; then
    return 0
fi
taqo_logger_imported="defined"

__taqo_lib_dir=$1
__taqo_log_cmd=$2

source "$__taqo_lib_dir/scripts/register_logger.sh"
export PROMPT="🔴$PROMPT"
