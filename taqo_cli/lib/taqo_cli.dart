// Copyright 2023 Google LLC
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

import 'dart:io';

import 'experiment_service.dart';

/// Taqo CLI main implementation
class TaqoCli {
  Future<void> joinPublicExperimentWithInvitationCode(String code) async {
    final experimentService = await ExperimentService.getInstance();
    final response = await experimentService.checkCode(code);
    if (!response.isSuccess) {
      stderr
          .writeln('Failed to fetch experiment information from Paco server.');
      stderr.writeln(
          'Status code: ${response.statusCode}, message: ${response.statusMsg}');
      exit(1);
    } else {
      await joinPublicExperiment(response.experimentId, response.participantId);
      print('Joined experiment with ID ${response.experimentId}. '
          'If you will join multiple experiments, you may need this experiment '
          'ID when pausing/resuming/quitting the experiment.');
    }
  }

  Future<void> joinPublicExperiment(int experimentId, int participantId) async {
    final experimentService = await ExperimentService.getInstance();

    var experiment =
        await experimentService.getPubExperimentFromServerById(experimentId);
    if (experiment != null) {
      experiment.participantId = participantId;
      experiment.anonymousPublic = true;
      await experimentService.joinExperiment(experiment);
    } else {
      stderr.writeln(
          'Error fetching experiment with id: ${experimentId}, participant: ${participantId}');
      exit(1);
    }
  }

  Future<void> setExperimentsPausedStatus(
      List<String> args, bool paused) async {
    final experimentService = await ExperimentService.getInstance();
    // Set for all experiments when none is specified
    if (args.isEmpty) {
      await experimentService.setExperimentPausedStatusForAll(paused);
      return;
    }

    for (final arg in args) {
      final experimentId = int.parse(arg);
      final experiment =
          await experimentService.getExperimentById(experimentId);
      if (experiment != null) {
        await experimentService.setExperimentPausedStatus(experiment, paused);
      }
    }
  }

  Future<void> stopExperiments(List<String> args) async {
    final experimentService = await ExperimentService.getInstance();
    // Stop all experiments when none is specified
    if (args.isEmpty) {
      await experimentService.stopAllExperiments();
      return;
    }

    for (final arg in args) {
      final experimentId = int.parse(arg);
      final experiment =
          await experimentService.getExperimentById(experimentId);
      if (experiment != null) {
        await experimentService.stopExperiment(experiment);
      }
    }
  }

  Future<void> listJoinedExperiments() async {
    final experimentService = await ExperimentService.getInstance();
    final experiments = experimentService.getJoinedExperiments();
    if (experiments.isEmpty) return;

    print('ID\t\t\tPaused\tTitle');
    for (final experiment in experiments) {
      print(
          '${experiment.id}\t${experiment.paused ? 'yes' : 'no'}\t${experiment.title}');
    }
  }
}
