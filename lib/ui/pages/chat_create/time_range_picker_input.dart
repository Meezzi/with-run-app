import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:time_range_picker/time_range_picker.dart';

class TimeRangePickerInput extends StatefulWidget {
  const TimeRangePickerInput({super.key});

  @override
  State<TimeRangePickerInput> createState() => _TimeRangePickerInputState();
}

class _TimeRangePickerInputState extends State<TimeRangePickerInput> {
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.fromDateTime(
    DateTime.now().add(const Duration(hours: 3)),
  );

  void onRangeChanged(TimeRange result){
    setState(() {
      _startTime = result.startTime;
      _endTime = result.endTime;
    });
  }

  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('${_startTime.format(context)} ~ ${_endTime.format(context)}',
        style: TextStyle(
          fontSize: 18,
        ),),
        SizedBox(width: 10,),
        ElevatedButton(
          onPressed: () async {
            TimeRange? result = await showTimeRangePicker(
              context: context,
              strokeWidth: 4,
              ticks: 12,
              ticksOffset: 2,
              ticksLength: 8,
              handlerRadius: 8,
              ticksColor: Colors.grey,
              rotateLabels: false,
              labels:
                  [
                    "24 h",
                    "3 h",
                    "6 h",
                    "9 h",
                    "12 h",
                    "15 h",
                    "18 h",
                    "21 h",
                  ].asMap().entries.map((e) {
                    return ClockLabel.fromIndex(
                      idx: e.key,
                      length: 8,
                      text: e.value,
                    );
                  }).toList(),
              labelOffset: 30,
              padding: 55,
              labelStyle: const TextStyle(fontSize: 18, color: Colors.black),
              start: const TimeOfDay(hour: 12, minute: 0),
              end: const TimeOfDay(hour: 15, minute: 0),
              // disabledTime: TimeRange(
              //   startTime: const TimeOfDay(hour: 6, minute: 0),
              //   endTime: const TimeOfDay(hour: 10, minute: 0),
              // ),
              clockRotation: 180.0,
            );
        
            if (kDebugMode) {
              print("result $result");
            }
          },
          child: const Text("시간 설정"),
        ),
      ],
    );
  }
}
