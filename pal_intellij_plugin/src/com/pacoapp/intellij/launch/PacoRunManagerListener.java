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

import com.intellij.execution.BeforeRunTaskProvider;
import com.intellij.execution.RunManagerEx;
import com.intellij.execution.RunManagerListener;
import com.intellij.execution.RunnerAndConfigurationSettings;
import com.intellij.execution.configurations.RunConfiguration;
import com.intellij.openapi.project.Project;
import com.pacoapp.intellij.PacoApplicationComponent;
import org.jetbrains.annotations.NotNull;

/**
 * Inspired heavily by code from COPE: http://cope.eecs.oregonstate.edu/index.html
 */
public class PacoRunManagerListener implements RunManagerListener {

  private final RunManagerEx runManager;
  private final Project project;
  private final BeforeRunTaskProvider<PacoBeforeRunTask> beforeRunTaskProvider;

  public PacoRunManagerListener(RunManagerEx runManager, Project project,
                                BeforeRunTaskProvider<PacoBeforeRunTask> beforeRunTaskProvider) {
    this.runManager = runManager;
    this.project = project;
    this.beforeRunTaskProvider = beforeRunTaskProvider;
  }

  @Override
  public void runConfigurationSelected() {
  }

  @Override
  public void beforeRunTasksChanged() {

  }

  @Override
  public void runConfigurationAdded(@NotNull RunnerAndConfigurationSettings settings) {
    RunConfiguration runConfiguration = settings.getConfiguration();
    PacoApplicationComponent.addPacoTaskToRunConfiguration(runManager, runConfiguration,
            beforeRunTaskProvider);
  }

  @Override
  public void runConfigurationRemoved(@NotNull RunnerAndConfigurationSettings settings) {
  }

  @Override
  public void runConfigurationChanged(@NotNull RunnerAndConfigurationSettings settings) {
  }
}
