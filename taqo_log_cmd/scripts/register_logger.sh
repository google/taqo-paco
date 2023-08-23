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

preexec_log_command() {
    if [[ "$1" == *\& ]]; then
        __taqo_bfg=bg
        unset __taqo_need_log_precmd
    else
        __taqo_bfg=fg
        __taqo_need_log_precmd=1
    fi
    $__taqo_log_cmd start "$1" "$$" "$__taqo_bfg"
}

precmd_log_status() {
    __taqo_last_ret="$?"
    if [[ "$__taqo_need_log_precmd" == 1 ]]; then
        $__taqo_log_cmd end "$$" "$__taqo_last_ret"
        unset __taqo_need_log_precmd
    fi
}

preexec_functions+=(preexec_log_command)
precmd_functions+=(precmd_log_status)
