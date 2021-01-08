// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package com.pacoapp.intellij.launch;

import com.intellij.execution.BeforeRunTask;
import com.intellij.openapi.util.Key;
import org.jetbrains.annotations.NotNull;

/**
 * Inspired heavily by code from COPE: http://cope.eecs.oregonstate.edu/index.html
 */
public class PacoBeforeRunTask extends BeforeRunTask<PacoBeforeRunTask> {

  protected PacoBeforeRunTask(@NotNull Key<PacoBeforeRunTask> providerId) {
    super(providerId);
    setEnabled(true);
  }

}
