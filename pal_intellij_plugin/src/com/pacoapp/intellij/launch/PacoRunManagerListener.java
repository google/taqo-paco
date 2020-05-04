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
