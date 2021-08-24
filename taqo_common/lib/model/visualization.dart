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

// @dart=2.9

import 'package:json_annotation/json_annotation.dart';

import '../util/zoned_date_time.dart';
import 'viz_variable.dart';

part 'visualization.g.dart';

@JsonSerializable()
class Visualization {
  int id;
  int experimentId;
  String title;

  @JsonKey(fromJson: _zonedDateTimeFromMillis, toJson: _zonedDateTimeToMillis)
  ZonedDateTime modifyDate;
  String question;

  VizVariable xAxisVariable;
  List<VizVariable> yAxisVariables;

  List<String> participants;
  String type;
  String description;

  @JsonKey(fromJson: _zonedDateTimeFromMillis, toJson: _zonedDateTimeToMillis)
  ZonedDateTime startDatetime;

  @JsonKey(fromJson: _zonedDateTimeFromMillis, toJson: _zonedDateTimeToMillis)
  ZonedDateTime endDatetime;

  Visualization();

  factory Visualization.fromJson(Map<String, dynamic> json) =>
      _$VisualizationFromJson(json);

  Map<String, dynamic> toJson() => _$VisualizationToJson(this);

  static ZonedDateTime _zonedDateTimeFromMillis(int millis) =>
      millis == null ? null : ZonedDateTime.fromMillis(millis);

  static int _zonedDateTimeToMillis(ZonedDateTime zonedDateTime) =>
      zonedDateTime?.toMillis();
}
