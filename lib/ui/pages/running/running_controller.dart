import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/pages/rank/rank_page.dart';
import 'package:with_run_app/ui/pages/rank/running_view_model.dart';

/// 러닝 세션을 관리하는 컨트롤러 (러닝 시작/종료, 시간 증가, 결과 저장 및 페이지 이동)
class RunningController {
  final WidgetRef ref;
  final String chatRoomId;
  final String userId;
  final BuildContext context;

  Timer? _timer;
  StreamSubscription<bool>? _runningStatusSubscription;
  bool _hasStartedRunning = false;
  bool _isFirstLoad = true;

  RunningController({
    required this.ref,
    required this.chatRoomId,
    required this.userId,
    required this.context,
  });

  /// 러닝 상태 스트림 구독 시작
  void init() {
    final viewModel = ref.read(runningViewModelProvider(chatRoomId).notifier);
    _runningStatusSubscription = viewModel.runningStatusStream().listen(
      _onRunningStatusChanged,
    );
  }

  /// 러닝 시작/종료 상태가 변경될 때 호출
  Future<void> _onRunningStatusChanged(bool isRunning) async {
    if (_isFirstLoad) {
      // 최초 구독 시 상태만 맞춰주고 리턴
      _isFirstLoad = false;
      await ref
          .read(runningViewModelProvider(chatRoomId).notifier)
          .setRunningStatus(isRunning);
      return;
    }

    if (isRunning) {
      // 러닝 시작
      _hasStartedRunning = true;
      await ref
          .read(runningViewModelProvider(chatRoomId).notifier)
          .startRunning();
      _startTimer();
    } else {
      if (_hasStartedRunning) {
        // 러닝 종료 후 결과 저장
        await ref
            .read(runningViewModelProvider(chatRoomId).notifier)
            .stopRunning();
        _timer?.cancel();

        // 러닝 종료 후 RankPage로 이동
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => RankPage(chatRoomId: chatRoomId, userId: userId),
            ),
          );
        }
      }
    }

    // 러닝 상태 서버에 업데이트
    await ref
        .read(runningViewModelProvider(chatRoomId).notifier)
        .setRunningStatus(isRunning);
  }

  /// 러닝 중 시간 카운트 시작 (1초마다 runningTime +1)
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref
          .read(runningViewModelProvider(chatRoomId).notifier)
          .increaseRunningTime();
    });
  }

  /// 타이머 및 스트림 구독 해제
  void dispose() {
    _timer?.cancel();
    _runningStatusSubscription?.cancel();
  }
}
