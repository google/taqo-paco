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

import 'package:json_annotation/json_annotation.dart';

import '../util/zoned_date_time.dart';

part 'shell_command_log.g.dart';

abstract class ShellCommandLog {
  String get type;
  Map<String, dynamic> toJson();
}

@JsonSerializable()
class ShellCommandStart implements ShellCommandLog {
  @override
  final type = 'start';

  @JsonKey(fromJson: _zonedDateTimeFromString, toJson: _zonedDateTimeToString)
  final ZonedDateTime timestamp;
  final String command;
  final int shellPid;
  final bool isBackground;

  ShellCommandStart(
      {required this.timestamp,
      required this.command,
      required this.shellPid,
      required this.isBackground});

  factory ShellCommandStart.fromJson(Map<String, dynamic> json) =>
      _$ShellCommandStartFromJson(json);
  // TODO(https://github.com/google/taqo-paco/issues/142):
  // Once we migrated to null-safe Dart, we can upgrade json_annotation to 4.8.0 or higher,
  // where we can force `type` to be serialized and does not need to manually append key-value pairs.
  // See also https://github.com/google/json_serializable.dart/issues/274
  @override
  Map<String, dynamic> toJson() =>
      _$ShellCommandStartToJson(this)..putIfAbsent('type', () => this.type);
}

@JsonSerializable()
class ShellCommandEnd implements ShellCommandLog {
  @override
  final type = 'end';

  @JsonKey(fromJson: _zonedDateTimeFromString, toJson: _zonedDateTimeToString)
  final ZonedDateTime timestamp;
  final int shellPid; // currently pid of the shell
  final int exitCode;

  ShellCommandEnd(
      {required this.timestamp,
      required this.shellPid,
      required this.exitCode});

  factory ShellCommandEnd.fromJson(Map<String, dynamic> json) =>
      _$ShellCommandEndFromJson(json);
  // TODO(https://github.com/google/taqo-paco/issues/142):
  // Once we migrated to null-safe Dart, we can upgrade json_annotation to 4.8.0 or higher,
  // where we can force `type` to be serialized and does not need to manually append key-value pairs.
  // See also https://github.com/google/json_serializable.dart/issues/274
  @override
  Map<String, dynamic> toJson() =>
      _$ShellCommandEndToJson(this)..putIfAbsent('type', () => this.type);
}

ZonedDateTime _zonedDateTimeFromString(String string) =>
    ZonedDateTime.fromString(string);

String _zonedDateTimeToString(ZonedDateTime zonedDateTime) =>
    zonedDateTime.toString();
