
import 'package:time_range_picker/time_range_picker.dart';

String? timeRangePickerValidator(TimeRange? timeRange){
  if(timeRange == null) return '시간을 설정해주세요';
  return null;
}

String? datePickerValidation(DateTime? selectedDate){
  if(selectedDate == null) return '날짜를 선택해 주세요';
  return null;
}

String? titleInputValidator(String? value) {
  if(value == null) return '방 이름을 입력해주세요';
  if(value == '') return '방 이름을 입력해주세요';
  return null;
}

String? alwaysValid(String? value){
  return null;
}