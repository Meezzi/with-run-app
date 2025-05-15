import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/pages/rank/running_view_model.dart';
import 'package:with_run_app/ui/pages/user_view_model.dart';

class MyResultSummaryCard extends ConsumerStatefulWidget {
  final String chatRoomId;

  const MyResultSummaryCard({super.key, required this.chatRoomId});

  @override
  _MyResultSummaryCardState createState() => _MyResultSummaryCardState();
}

class _MyResultSummaryCardState extends ConsumerState<MyResultSummaryCard> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userViewModelProvider);
    final runningState = ref.watch(
      runningViewModelProvider(widget.chatRoomId),
    );

    // 유저 정보 아직 로딩 중이면 로딩 표시
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user.profileImageUrl!),
                  radius: 48,
                  backgroundColor: Colors.blue[100],
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${((double.tryParse(runningState.distance) ?? 0) / 1000.0).toStringAsFixed(2)} km',

                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DetailResult(
                  title: '평균 속도',
                  content:
                      '${double.tryParse(runningState.speed)?.toStringAsFixed(1) ?? '0.0'} km/h',
                ),
                DetailResult(
                  title: '칼로리',
                  content: '${runningState.colories} kcal',
                ),
                DetailResult(
                  title: '걸음 수',
                  content: '${runningState.steps} 걸음',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DetailResult extends StatelessWidget {
  final String title;
  final String content;

  const DetailResult({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title),
        Text(
          content,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
