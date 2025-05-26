import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/running/presentation/rank/running_view_model.dart';
import 'package:with_run_app/features/running/presentation/running/controller/running_animation_controller.dart';
import 'package:with_run_app/features/running/presentation/running/controller/running_controller.dart';
import 'package:with_run_app/features/running/presentation/running/widgets/running_host_button.dart';
import 'package:with_run_app/features/running/presentation/running/widgets/running_lottie_animation.dart';
import 'package:with_run_app/features/running/presentation/running/widgets/running_status_card.dart';

class RunningPage extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String userId;
  final bool isCreator;

  const RunningPage({
    super.key,
    required this.chatRoomId,
    required this.userId,
    required this.isCreator,
  });

  @override
  _RunningPageState createState() => _RunningPageState();
}

class _RunningPageState extends ConsumerState<RunningPage>
    with SingleTickerProviderStateMixin {
  late RunningController runningController;
  late final RunningAnimationController animationController;

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(runningViewModelProvider(widget.chatRoomId));

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RunningLottieAnimation(
                    controller: animationController.lottieController,
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: RunningStatusCard(chatRoomId: widget.chatRoomId),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (widget.isCreator)
              RunningHostButton(
                isRunning: viewModel.isStart,
                onPressed: _onHostButtonPressed,
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  viewModel.isStart ? '러닝 중입니다...' : '대기 중...',
                  style: const TextStyle(fontSize: 18),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    runningController = RunningController(
      ref: ref,
      chatRoomId: widget.chatRoomId,
      userId: widget.userId,
      context: context,
    );
    animationController = RunningAnimationController(vsync: this);
    runningController.init();
  }

  @override
  void dispose() {
    runningController.dispose();
    animationController.dispose();
    super.dispose();
  }

  void _onHostButtonPressed() async {
    final viewModelNotifier = ref.read(
      runningViewModelProvider(widget.chatRoomId).notifier,
    );
    final viewModel = ref.read(runningViewModelProvider(widget.chatRoomId));

    final isRunning = viewModel.isStart;

    final success =
        isRunning
            ? await viewModelNotifier.stopRunning()
            : await viewModelNotifier.startRunning();

    if (success) {
      await viewModelNotifier.setRunningStatus(!isRunning);
      isRunning
          ? animationController.stopAnimation()
          : animationController.startAnimation();
    } else {
      final errorMessage =
          ref.read(runningViewModelProvider(widget.chatRoomId)).errorMessage;
      final displayMessage =
          errorMessage.isNotEmpty ? errorMessage : '알 수 없는 오류';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(displayMessage)));
    }
  }
}
