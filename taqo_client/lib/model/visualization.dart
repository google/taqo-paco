import 'package:taqo_client/model/viz_variable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'visualization.g.dart';


@JsonSerializable()
class Visualization {

  int id;
  int experimentId;
  String title;

  DateTime modifyDate;
  String question;

  VizVariable xAxisVariable;
  List<VizVariable> yAxisVariables;

  List<String> participants;
  String type;
  String description;

  DateTime startDatetime;
  DateTime endDatetime;

  Visualization();

  factory Visualization.fromJson(Map<String, dynamic> json) => _$VisualizationFromJson(json);

  Map<String, dynamic> toJson() => _$VisualizationToJson(this);
  
}
