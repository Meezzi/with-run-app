import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:with_run_app/core/result/result.dart';
import 'package:with_run_app/data/model/running_data.dart';
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
  Timer? _timer; // 러닝 타이머
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
      ) {
    // 초기 상태 로드
    _loadRunningStatus();
  }

  // 현재 러닝 상태 불러오기
  Future<void> _loadRunningStatus() async {
    try {
      final statusStream = runningRepository.runningStatusStream();
      await for (final result in statusStream) {
        if (result is Ok<bool>) {
          final isRunning = result.value;
          
          if (isRunning && !_stopwatch.isRunning) {
            // 러닝 중이면 스톱워치 시작
            _stopwatch.start();
            _startTimer();
            await _startPedometer();
          } else if (!isRunning && _stopwatch.isRunning) {
            // 러닝 중이 아니면 스톱워치 정지
            _stopwatch.stop();
            _timer?.cancel();
            await _stepSubscription?.cancel();
          }
          
          state = state.copyWith(isStart: isRunning);
        }
        // 최초 상태 로드 후 스트림 종료
        break;
      }
    } catch (e) {
      _handleError(Exception('러닝 상태 로드 실패: $e'));
    }
  }

  // 현재 걸음 수
  int get currentSteps => _currentSteps;

  // 현재 이동 거리 (1걸음 = 0.7m로 가정)
  double get currentDistance => _currentSteps * 0.7;

  // 현재 속도 (시속 km 단위)
  double get currentSpeed {
    final seconds = _stopwatch.elapsed.inSeconds;
    if (seconds == 0) return 0;
    return (currentDistance / 1000) / (seconds / 3600);
  }

  // 현재 소모된 칼로리
  int get currentCalories => (_currentSteps * 0.04).round();

  // 러닝 타이머 시작
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(
        runningTime: _stopwatch.elapsed.inSeconds.toString(),
      );
    });
  }

  // 만보계 시작
  Future<bool> _startPedometer() async {
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      _handleError(Exception('걸음 수 측정 권한이 필요합니다.'));
      return false;
    }

    try {
      _stepSubscription = Pedometer.stepCountStream.listen(
        (event) {
          _initialSteps = _initialSteps == 0 ? event.steps : _initialSteps;
          _currentSteps = event.steps - _initialSteps;

          // 상태 갱신
          state = state.copyWith(
            steps: _currentSteps.toString(),
            distance: currentDistance.toString(),
            speed: currentSpeed.toString(),
            colories: currentCalories.toString(),
          );
        },
        onError: (error) {
          _handleError(Exception('Pedometer 오류: $error'));
        },
      );
      return true;
    } catch (e) {
      _handleError(Exception('Pedometer 시작 실패: $e'));
      return false;
    }
  }

  // 러닝 시작 메서드
  Future<bool> startRunning() async {
    try {
      _stopwatch.start();
      _startTimer();
      final success = await _startPedometer();
      
      if (success) {
        state = state.copyWith(isStart: true);
        return true;
      }
      
      // 실패 시 리소스 정리
      _stopwatch.stop();
      _timer?.cancel();
      return false;
    } catch (e) {
      _handleError(Exception('러닝 시작 실패: $e'));
      return false;
    }
  }

  // 러닝 종료 메서드
  Future<bool> stopRunning() async {
    if (!_stopwatch.isRunning) return false;

    try {
      _stopwatch.stop();
      _timer?.cancel();
      await _stepSubscription?.cancel();

      final data = RunningData(
        steps: _currentSteps,
        distance: currentDistance,
        speed: currentSpeed,
        calories: currentCalories,
        runningTime: _stopwatch.elapsed.inSeconds,
      );

      final result = await runningRepository.saveRunningData(data);
      state = state.copyWith(isStart: false);
      return result is Ok;
    } catch (e) {
      _handleError(Exception('러닝 종료 실패: $e'));
      return false;
    }
  }

  // 러닝 상태 업데이트
  Future<bool> setRunningStatus(bool isRunning) async {
    final result = await runningRepository.updateRunningStatus(isRunning);
    if (result is Ok) return true;
    _handleError((result as Error).error);
    return false;
  }

  // 러닝 상태 스트림
  Stream<bool> runningStatusStream() {
    return runningRepository.runningStatusStream().map((result) {
      if (result is Ok<bool>) {
        return result.value;
      } else {
        _handleError((result as Error).error);
        return false;
      }
    });
  }

  // 러닝 시간 1초씩 증가
  void increaseRunningTime() {
    state = state.copyWith(
      runningTime: (int.parse(state.runningTime) + 1).toString(),
    );
  }

  // 에러 처리
  void _handleError(Exception e) {
    state = state.copyWith(errorMessage: e.toString());
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _stepSubscription?.cancel();
    super.dispose();
  }
}

// RunningViewModel에서 chatRoomIdProvider 사용
final runningViewModelProvider =
    StateNotifierProvider.family<RunningViewModel, RunningState, String>(
      (ref, chatRoomId) => RunningViewModel(chatRoomId: chatRoomId),
    );