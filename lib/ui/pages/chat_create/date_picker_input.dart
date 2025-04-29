import 'package:flutter/material.dart';

class DatePickerInput extends StatefulWidget {
  const DatePickerInput({super.key, required this.onDateChanged});
  final void Function(DateTime? date) onDateChanged;

  @override
  State<DatePickerInput> createState() => _DatePickerInputState();
}

class _DatePickerInputState extends State<DatePickerInput> {
  DateTime? selectedDate;

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    setState(() {
      selectedDate = pickedDate;
    });
    widget.onDateChanged(pickedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          selectedDate != null
              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
              : '선택된 날짜가 없습니다.',
              style: TextStyle(
                fontSize: 18,
              ),
        ),
        OutlinedButton(onPressed: _selectDate, child: const Text('날짜 선택')),
      ],
    );
  }
}
