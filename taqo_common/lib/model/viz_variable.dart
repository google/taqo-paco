import 'package:json_annotation/json_annotation.dart';

part 'viz_variable.g.dart';

@JsonSerializable()
class VizVariable {
  String id;
  String group;
  String name;
  String responseType;

  VizVariable();

  factory VizVariable.fromJson(Map<String, dynamic> json) =>
      _$VizVariableFromJson(json);

  Map<String, dynamic> toJson() => _$VizVariableToJson(this);
}
