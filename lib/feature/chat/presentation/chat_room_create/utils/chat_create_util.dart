
import 'package:flutter/material.dart';

DateTime makeDateTimeWithTime(DateTime date, TimeOfDay time){
  return DateTime.parse('${date.toIso8601String().split('T')[0]} ${timeOfDayToString(time)}');
}

String timeOfDayToString(TimeOfDay time){
  return time.toString().split('(')[1].split(')')[0];
}