import 'package:taqo_client/model/viz_variable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:taqo_client/util/zoned_date_time.dart';

part 'visualization.g.dart';


@JsonSerializable()
class Visualization {

  int id;
  int experimentId;
  String title;

  @JsonKey(fromJson: _zonedDateTimeFromInt, toJson: _zonedDateTimeToInt)
  ZonedDateTime modifyDate;
  String question;

  VizVariable xAxisVariable;
  List<VizVariable> yAxisVariables;

  List<String> participants;
  String type;
  String description;

  @JsonKey(fromJson: _zonedDateTimeFromInt, toJson: _zonedDateTimeToInt)
  ZonedDateTime startDatetime;

  @JsonKey(fromJson: _zonedDateTimeFromInt, toJson: _zonedDateTimeToInt)
  ZonedDateTime endDatetime;

  Visualization();

  factory Visualization.fromJson(Map<String, dynamic> json) => _$VisualizationFromJson(json);

  Map<String, dynamic> toJson() => _$VisualizationToJson(this);

  static ZonedDateTime _zonedDateTimeFromInt(int millis) =>
      millis == null ? null : ZonedDateTime.fromInt(millis);

  static int _zonedDateTimeToInt(ZonedDateTime zonedDateTime) =>
      zonedDateTime?.toMillis();
}
