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

function taqo_prehook --on-event fish_preexec
    if status is-interactive
    	set -f fgbg "fg"
    	if string match -r "&\$" $argv 1 >/dev/null
    	  set -f fgbg "bg"
    	end
      $taqologcmd start $argv $fish_pid $fgbg
    end
    commandline
end

function taqo_posthook --on-event fish_postexec
    # do not check if status is-interactive as it wipes the $status value
    set -f stat $status
    if status is-interactive; and not string match -r "&\$" $argv 1 >/dev/null
       $taqologcmd end $fish_pid $stat
    end
    commandline
end
