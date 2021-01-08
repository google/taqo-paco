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

import com.google.common.collect.Maps;
import com.intellij.execution.BeforeRunTaskProvider;
import com.intellij.execution.configurations.RunConfiguration;
import com.intellij.execution.impl.RunnerAndConfigurationSettingsImpl;
import com.intellij.execution.runners.ExecutionEnvironment;
import com.intellij.openapi.actionSystem.DataContext;
import com.intellij.openapi.util.Key;
import com.intellij.openapi.util.WriteExternalException;
import com.pacoapp.intellij.PacoApplicationComponent;
import com.pacoapp.intellij.PacoIntellijEventTypes;
import io.flutter.run.FlutterDevice;
import io.flutter.run.daemon.DeviceService;
import org.jetbrains.annotations.Nullable;

import java.util.Map;

/**
 * Inspired heavily by code from COPE: http://cope.eecs.oregonstate.edu/index.html
 */
public class PacoBeforeRunTaskProvider extends BeforeRunTaskProvider<PacoBeforeRunTask> {

  public static final String EXTENSION_NAME = "Paco Run Recorder";

  private Key<PacoBeforeRunTask> launchProvider = new Key<PacoBeforeRunTask>("com.pacoapp.intellij.launchprovider");

  public PacoBeforeRunTaskProvider() {
  }

  @Override
  public Key<PacoBeforeRunTask> getId() {
    return launchProvider;
  }

  @Override
  public String getName() {
    return EXTENSION_NAME;
  }

  @Override
  public String getDescription(PacoBeforeRunTask task) {
    return "Paco Run Recorder";
  }

  @Override
  public boolean isConfigurable() {
    return false;
  }

  @Nullable
  @Override
  public PacoBeforeRunTask createTask(RunConfiguration runConfiguration) {
    return new PacoBeforeRunTask(launchProvider);
  }

  @Override
  public boolean configureTask(RunConfiguration runConfiguration, PacoBeforeRunTask task) {
    return true;
  }

  @Override
  public boolean canExecuteTask(RunConfiguration configuration, PacoBeforeRunTask task) {
    return true;
  }

  @Override
  public boolean executeTask(DataContext context, final RunConfiguration configuration, ExecutionEnvironment env, PacoBeforeRunTask task) {
    try {
      String runTypeName = ((RunnerAndConfigurationSettingsImpl) env.getRunnerAndConfigurationSettings()).getType().getDisplayName();

      String projectName = env.getProject().getName();
      String configurationName = configuration.getName();
      String configurtationType = env.getExecutor().getActionName();
      FlutterDevice device = DeviceService.getInstance(env.getProject()).getSelectedDevice();

      Map<String, String> data = Maps.newHashMap();
      data.put("project", projectName);
      data.put("run_configuration_name", configurationName);
      data.put("run_configuration_action", configurtationType);
      data.put("run_configuration_type", runTypeName);
      if (device != null) {
        data.put("device_name", device.deviceName());
        data.put("device_platform", device.platform());
        data.put("device_emulator", String.valueOf(device.emulator()));
      }
      PacoApplicationComponent.appendPacoEvent(PacoIntellijEventTypes.EventType.LAUNCH, data);
    } catch (WriteExternalException e) {
    }

    return true;
  }
}
