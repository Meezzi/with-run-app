import 'package:flutter/material.dart';

class DatePickerInput extends StatefulWidget {
  const DatePickerInput({
    super.key,
    required this.onDateChanged,
    required this.validator,
  });

  final void Function(DateTime? date) onDateChanged;
  final String? Function(DateTime?) validator;

  @override
  State<DatePickerInput> createState() => _DatePickerInputState();
}

class _DatePickerInputState extends State<DatePickerInput> {
  DateTime? _selectedDate;
  final _fieldKey = GlobalKey<FormFieldState>();

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _fieldKey.currentState?.didChange(pickedDate);
      widget.onDateChanged(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      key: _fieldKey,
      validator: widget.validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'
                        : '선택된 날짜가 없습니다.',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                OutlinedButton(
                  onPressed: _selectDate,
                  child: const Text('날짜 선택'),
                ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}