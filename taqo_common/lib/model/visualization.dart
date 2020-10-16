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
