import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/pages/rank/rank_page.dart';
import 'package:with_run_app/ui/pages/rank/running_view_model.dart';
import 'package:with_run_app/ui/pages/running/controller/running_animation_controller.dart';
import 'package:with_run_app/ui/pages/running/widgets/running_host_button.dart';
import 'package:with_run_app/ui/pages/running/widgets/running_lottie_animation.dart';
import 'package:with_run_app/ui/pages/running/widgets/running_status_card.dart';

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
  ConsumerState<RunningPage> createState() => RunningPageState();
}

class RunningPageState extends ConsumerState<RunningPage>
    with SingleTickerProviderStateMixin {
  late final RunningAnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = RunningAnimationController(vsync: this);
    
    // 러닝 상태 확인하여 애니메이션 시작/중지
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(runningViewModelProvider(widget.chatRoomId));
      if (viewModel.isStart) {
        animationController.startAnimation();
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(runningViewModelProvider(widget.chatRoomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('러닝'),
      ),
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

  void _onHostButtonPressed() async {
    final viewModelNotifier = ref.read(
      runningViewModelProvider(widget.chatRoomId).notifier,
    );
    final viewModel = ref.read(runningViewModelProvider(widget.chatRoomId));

    final isRunning = viewModel.isStart;

    if (isRunning) {
      // 러닝 종료
      final success = await viewModelNotifier.stopRunning();
      if (success) {
        await viewModelNotifier.setRunningStatus(false);
        animationController.stopAnimation();
        
        // 랭킹 페이지로 이동
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RankPage(
                chatRoomId: widget.chatRoomId,
                userId: widget.userId,
              ),
            ),
          );
        }
      } else {
        _showErrorSnackBar();
      }
    } else {
      // 러닝 시작
      final success = await viewModelNotifier.startRunning();
      if (success) {
        await viewModelNotifier.setRunningStatus(true);
        animationController.startAnimation();
      } else {
        _showErrorSnackBar();
      }
    }
  }

  void _showErrorSnackBar() {
    final errorMessage = ref.read(runningViewModelProvider(widget.chatRoomId)).errorMessage;
    final displayMessage = errorMessage.isNotEmpty ? errorMessage : '알 수 없는 오류';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(displayMessage)),
    );
  }
}