// RunningState 클래스: 러닝의 상태를 저장
class RunningState {
  final bool isStart;
  final String steps;
  final String distance;
  final String speed;
  final String colories;
  final String runningTime;
  final String errorMessage;

  RunningState({
    required this.isStart,
    required this.steps,
    required this.distance,
    required this.speed,
    required this.colories,
    required this.runningTime,
    required this.errorMessage,
  });

  RunningState copyWith({
    bool? isStart,
    String? steps,
    String? distance,
    String? speed,
    String? colories,
    String? runningTime,
    String? errorMessage,
  }) {
    return RunningState(
      isStart: isStart ?? this.isStart,
      steps: steps ?? this.steps,
      distance: distance ?? this.distance,
      speed: speed ?? this.speed,
      colories: colories ?? this.colories,
      runningTime: runningTime ?? this.runningTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
