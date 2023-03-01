// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shell_command_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShellCommandStart _$ShellCommandStartFromJson(Map<String, dynamic> json) {
  return ShellCommandStart(
    timestamp: _zonedDateTimeFromString(json['timestamp'] as String),
    command: json['command'] as String,
    shellPid: json['shellPid'] as int,
    isBackground: json['isBackground'] as bool,
  );
}

Map<String, dynamic> _$ShellCommandStartToJson(ShellCommandStart instance) =>
    <String, dynamic>{
      'timestamp': _zonedDateTimeToString(instance.timestamp),
      'command': instance.command,
      'shellPid': instance.shellPid,
      'isBackground': instance.isBackground,
    };

ShellCommandEnd _$ShellCommandEndFromJson(Map<String, dynamic> json) {
  return ShellCommandEnd(
    timestamp: _zonedDateTimeFromString(json['timestamp'] as String),
    shellPid: json['shellPid'] as int,
    exitCode: json['exitCode'] as int,
  );
}

Map<String, dynamic> _$ShellCommandEndToJson(ShellCommandEnd instance) =>
    <String, dynamic>{
      'timestamp': _zonedDateTimeToString(instance.timestamp),
      'shellPid': instance.shellPid,
      'exitCode': instance.exitCode,
    };
