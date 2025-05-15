import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RunningLottieAnimation extends StatelessWidget {
  final AnimationController controller;

  const RunningLottieAnimation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Lottie.asset(
        'assets/lottie/running.json',
        controller: controller,
        onLoaded: (composition) {
          controller.duration = composition.duration;
        },
      ),
    );
  }
}
