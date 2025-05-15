import 'package:flutter/material.dart';

/// 러닝 화면에서 Lottie 애니메이션을 제어하는 컨트롤러
class RunningAnimationController {
  late final AnimationController lottieController;

  RunningAnimationController({required TickerProvider vsync}) {
    // AnimationController 생성
    lottieController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 2),
    );
  }

  /// 애니메이션 반복 재생 시작
  void startAnimation() {
    lottieController.repeat();
  }

  /// 애니메이션 정지
  void stopAnimation() {
    lottieController.stop();
  }

  /// AnimationController 메모리 해제
  void dispose() {
    lottieController.dispose();
  }
}
