# Copyright 2023 Google LLC

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#      http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# For event-handler Fish scripts, they need to be installed in
# $XDG_CONFIG_HOME/fish/config.fish to get registered.

function prehook --on-event fish_preexec
    if status is-interactive
        $logcmd start $argv shell_pid bg|fg 
    end
    commandline
end

function posthook --on-event fish_postexec
    if status is-interactive
        $logcmd end shell_pid exitcode
    end
    commandline
end



