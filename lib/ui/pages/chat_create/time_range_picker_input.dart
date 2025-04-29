import 'package:flutter/material.dart';
import 'package:time_range_picker/time_range_picker.dart';

class TimeRangePickerInput extends StatefulWidget {
  const TimeRangePickerInput({
    super.key,
    required this.onRangeChanged,
    required this.validator,
  });

  final void Function(TimeRange timeRange) onRangeChanged;
  final String? Function(TimeRange?) validator;

  @override
  State<TimeRangePickerInput> createState() => _TimeRangePickerInputState();
}

class _TimeRangePickerInputState extends State<TimeRangePickerInput> {
  TimeRange? _selectedRange;
  final _fieldKey = GlobalKey<FormFieldState>();

  Future<void> _pickRange(BuildContext context) async {
    final result = await showTimeRangePicker(
      context: context,
      strokeWidth: 4,
      ticks: 12,
      ticksOffset: 2,
      ticksLength: 8,
      handlerRadius: 8,
      ticksColor: Colors.grey,
      rotateLabels: false,
      labels: [
        "24 h", "3 h", "6 h", "9 h", "12 h", "15 h", "18 h", "21 h"
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
      clockRotation: 180.0,
    );

    if (result != null) {
      setState(() {
        _selectedRange = result;
      });
      _fieldKey.currentState?.didChange(result);
      widget.onRangeChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<TimeRange>(
      key: _fieldKey,
      validator: widget.validator,
      builder: (state) {
        final startTime = _selectedRange?.startTime;
        final endTime = _selectedRange?.endTime;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    startTime != null && endTime != null
                        ? '${startTime.format(context)} ~ ${endTime.format(context)}'
                        : '시간을 설정해주세요',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _pickRange(context),
                  child: const Text("시간 설정"),
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