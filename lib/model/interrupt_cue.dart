import 'package:taqo_survey/model/validatable.dart';
import 'package:taqo_survey/model/validator.dart';
import 'package:json_annotation/json_annotation.dart';

part 'interrupt_cue.g.dart';

@JsonSerializable()
class InterruptCue extends Validatable {

  static const PHONE_HANGUP = 1;
  static const USER_PRESENT = 2;
  static const PACO_ACTION_EVENT = 3;
  static const APP_USAGE = 4;
  static const APP_CLOSED = 5;
  static const MUSIC_STARTED = 6;
  static const MUSIC_STOPPED = 7;
  static const PHONE_INCOMING_CALL_STARTED = 8;
  static const PHONE_INCOMING_CALL_ENDED = 9;
  static const PHONE_OUTGOING_CALL_STARTED = 10;
  static const PHONE_OUTGOING_CALL_ENDED = 11;
  static const PHONE_MISSED_CALL = 12;
  static const PHONE_CALL_STARTED = 13;
  static const PHONE_CALL_ENDED = 14;
  static const PACO_EXPERIMENT_JOINED_EVENT = 15;
  static const PACO_EXPERIMENT_ENDED_EVENT = 16;
  static const PACO_EXPERIMENT_RESPONSE_RECEIVED_EVENT = 17;
  static const APP_REMOVED = 18;
  static const APP_ADDED = 19;
  static const PERMISSION_CHANGED = 20;
  static const ACCESSIBILITY_EVENT_VIEW_CLICKED = 21;
  static const NOTIFICATION_CREATED = 22;
  static const NOTIFICATION_TRAY_OPENED = 23;
  static const NOTIFICATION_TRAY_CLEAR_ALL = 24;
  static const NOTIFICATION_TRAY_SWIPE_DISMISS = 25;
  static const NOTIFICATION_TRAY_CANCELLED = 26;
  static const NOTIFICATION_CLICKED = 27;




  static const CUE_EVENTS = [PHONE_HANGUP, USER_PRESENT, PACO_ACTION_EVENT, APP_USAGE, APP_CLOSED, MUSIC_STARTED, MUSIC_STOPPED,
  PHONE_INCOMING_CALL_STARTED, PHONE_INCOMING_CALL_ENDED,
  PHONE_OUTGOING_CALL_STARTED, PHONE_OUTGOING_CALL_ENDED, PHONE_MISSED_CALL, PHONE_CALL_STARTED, PHONE_CALL_ENDED,
  PACO_EXPERIMENT_JOINED_EVENT,
  PACO_EXPERIMENT_ENDED_EVENT, PACO_EXPERIMENT_RESPONSE_RECEIVED_EVENT, APP_REMOVED, APP_ADDED, PERMISSION_CHANGED,
  ACCESSIBILITY_EVENT_VIEW_CLICKED,
  NOTIFICATION_CREATED, NOTIFICATION_TRAY_OPENED,
  NOTIFICATION_TRAY_CLEAR_ALL, NOTIFICATION_TRAY_SWIPE_DISMISS,
  NOTIFICATION_TRAY_CANCELLED, NOTIFICATION_CLICKED];

  static const CUE_EVENT_NAMES = ["HANGUP (deprecated)", "USER_PRESENT", "Paco Action",
  "App Started", "App Stopped",
  "Music Started", "Music Stopped",
  "Incoming call started", "Incoming call ended",
  "Outgoing call started", "Outgoing call ended",
  "Missed call", "Call started (in or out)", "Call ended (in or out)",
  "Experiment joined", "Experiment ended", "Response received", "App Removed",
  "App Installed", "Permission changed", "View Clicked in App",
  "Notification Created", "Notification shade opened",
  "Notification shade dismiss all notifications",
  "Notification shade dismiss notification",
  "Notification shade closed",
  "Notification tapped in shade"];
  static const VIEW_CLICKED = 1;







  int cueCode;
  String cueSource; // doubles as package name for view_clicked event type
  String cueAEClassName;
  int cueAEEventType = VIEW_CLICKED;
  String cueAEContentDescription;

  int id;

  InterruptCue() {
    cueCode = 0;
  }

  factory InterruptCue.fromJson(Map<String, dynamic> json) => _$InterruptCueFromJson(json);

  Map<String, dynamic> toJson() => _$InterruptCueToJson(this);
  
  void validateWith(Validator validator) {
//    System.out.println("VALIDATING CUE");
    validator.isNotNull(cueCode, "cue code is not properly initialized");
    if (cueCode != null && (cueCode == PACO_ACTION_EVENT || cueCode == APP_USAGE)) {
      validator.isNonEmptyString(cueSource,
          "cuesource must be valid for cuecode: " + CUE_EVENT_NAMES[cueCode - 1]);
    }
  }


  
}