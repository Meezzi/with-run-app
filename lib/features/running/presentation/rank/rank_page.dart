import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/running/presentation/rank/participantsProvider.dart';
import 'package:with_run_app/features/running/presentation/rank/widgets/my_result_summary_card.dart';
import 'package:with_run_app/features/running/presentation/rank/widgets/top_runner_summary_card.dart';

class RankPage extends ConsumerWidget {
  final String chatRoomId;
  final String userId;

  const RankPage({super.key, required this.chatRoomId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantsProvider(chatRoomId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF036FF4),
        foregroundColor: Colors.white,
      ),
      backgroundColor: Color(0xFF036FF4),
      body: participantsAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러: $e')),
        data: (participants) {
          if (participants.isEmpty) {
            return Center(child: Text('참가자가 없습니다.'));
          }

          // 거리순 내림차순 정렬 (복사본 만들기)
          final sortedParticipants = [...participants];
          sortedParticipants.sort((a, b) {
            double distA =
                double.tryParse(a['distance']?.toString() ?? '0') ?? 0;
            double distB =
                double.tryParse(b['distance']?.toString() ?? '0') ?? 0;
            return distB.compareTo(distA);
          });

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ListView(
              children: [
                MyResultSummaryCard(chatRoomId: chatRoomId),
                SizedBox(height: 16),
                TopRunnerSummaryCard(participants: sortedParticipants),
              ],
            ),
          );
        },
      ),
    );
  }
}
