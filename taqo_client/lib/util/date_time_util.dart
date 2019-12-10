import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const DAYS_SHORT_NAMES = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" ];
const ORDINAL_NUMBERS = ["", "1st", "2nd", "3rd", "4th", "5th" ];

int getMsFromMidnight(TimeOfDay time) => (60 * time.hour + time.minute) * 60 * 1000;

String getHourOffsetAsTimeString(int millisFromMidnight) {
  final hourFormatter = DateFormat('hh:mma');
  final now = DateTime.now();
  final endHour = DateTime(now.year, now.month, now.day)
      .add(Duration(milliseconds: millisFromMidnight));
  return hourFormatter.format(endHour);
}
