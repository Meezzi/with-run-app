import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/core/utils/duration_formatter.dart';
import 'package:with_run_app/features/running/presentation/rank/running_view_model.dart';

class RunningStatusCard extends ConsumerWidget {
  final String chatRoomId;

  const RunningStatusCard({super.key, required this.chatRoomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(runningViewModelProvider(chatRoomId));

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              viewModel.steps,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '걸음',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _detailStatusCard(
                  icon: Icons.location_on_outlined,
                  value:
                      '${(double.parse(viewModel.distance) / 1000).toStringAsFixed(2)} km',
                ),
                _detailStatusCard(
                  icon: Icons.speed_outlined,
                  value:
                      '${double.parse(viewModel.speed).toStringAsFixed(1)} km/h',
                ),
                _detailStatusCard(
                  icon: Icons.local_fire_department_outlined,
                  value: '${viewModel.colories} kcal',
                ),
                _detailStatusCard(
                  icon: Icons.timer_outlined,
                  value: formatDuration(int.parse(viewModel.runningTime)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailStatusCard({required IconData icon, required String value}) {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
