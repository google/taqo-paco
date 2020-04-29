import 'package:json_annotation/json_annotation.dart';

part 'event_save_outcome.g.dart';

@JsonSerializable()
class EventSaveOutcome {
  int eventId;
  bool status;
  String errorMessage;

  EventSaveOutcome();

  factory EventSaveOutcome.fromJson(Map<String, dynamic> json) =>
      _$EventSaveOutcomeFromJson(json);

  Map<String, dynamic> toJson() => _$EventSaveOutcomeToJson(this);
}
