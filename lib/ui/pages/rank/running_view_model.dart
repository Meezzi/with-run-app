import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:with_run_app/data/repository/running_repository.dart';

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

class RunningViewModel extends StateNotifier<RunningState> {
  final RunningRepository runningRepository;
  final Stopwatch _stopwatch = Stopwatch(); // 시간 측정을 위한 Stopwatch
  StreamSubscription<StepCount>? _stepSubscription; // 걸음 수 스트림
  int _initialSteps = 0; // 초기 걸음 수
  int _currentSteps = 0; // 현재 걸음 수

  RunningViewModel({required String chatRoomId})
    : runningRepository = RunningRepository(chatRoomId: chatRoomId),
      super(
        RunningState(
          isStart: false,
          steps: '0',
          distance: '0.0',
          speed: '0.0',
          colories: '0',
          runningTime: '0',
          errorMessage: '',
        ),
      );

  // 현재 걸음 수
  int get currentSteps => _currentSteps;
}
