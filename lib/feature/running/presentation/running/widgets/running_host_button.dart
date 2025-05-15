import 'package:flutter/material.dart';

class RunningHostButton extends StatelessWidget {
  final bool isRunning;
  final VoidCallback onPressed;

  const RunningHostButton({
    super.key,
    required this.isRunning,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isRunning ? Colors.redAccent : Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
        child: Text(isRunning ? '러닝 종료' : '러닝 시작'),
      ),
    );
  }
}
