import 'package:json_annotation/json_annotation.dart';

part 'event.g.dart';

@JsonSerializable()

// TODO add the other properties of event here.
class Event {
  Map<String, dynamic> responses = {};

  Event();

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);

  Map<String, dynamic> toJson() => _$EventToJson(this);
}