import 'package:flutter/material.dart';

class TimePickerInput extends StatefulWidget {
  const TimePickerInput({super.key});
  final String? Function(String?) validator;

  @override
  State<TimePickerInput> createState() => _TimePickerInputState();
}

class _TimePickerInputState extends State<TimePickerInput> {
  TimeOfDay? selectedTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          selectedTime == null ? '시간을 설정해주세요' : '${selectedTime!.hour} : ${selectedTime!.minute}',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        SizedBox(width: 10,),
        ElevatedButton(
          child: const Text('시간 설정'),
          onPressed: () async {
            final TimeOfDay? time = await showTimePicker(
              context: context,
              initialTime: selectedTime ?? TimeOfDay.now(),
              initialEntryMode: TimePickerEntryMode.inputOnly,
              orientation: Orientation.landscape,
              builder: (BuildContext context, Widget? child) {
                return Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(alwaysUse24HourFormat: false),
                      child: child!,
                    ),
                  ),
                );
              },
            );
            setState(() {
              selectedTime = time;
            });
          },
        ),
      ],
    );
  }
}
