import 'package:flutter/material.dart';

DateTime makeDateTimeWithTime(DateTime date, TimeOfDay time) {
  // 기존 방식은 문자열 파싱 관련 오류가 발생할 수 있음
  // 직접 DateTime 객체를 생성하는 방식으로 변경
  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}