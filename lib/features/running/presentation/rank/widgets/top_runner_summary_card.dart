import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'top_runner_info.dart';
import 'runner_result.dart';

class TopRunnerSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> participants;

  const TopRunnerSummaryCard({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const SizedBox();

    final topRunner = participants.first;
    final others = participants.length > 1 ? participants.sublist(1) : [];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle(),
            const SizedBox(height: 24),
            TopRunnerInfo(
              nickname: topRunner['nickname'] ?? '알 수 없음',
              distance: _formatDistance(topRunner['distance']),
              time: _formatTime(topRunner['runningTime']),
              imageUrl:
                  topRunner['profileImageUrl'] ?? 'https://picsum.photos/200',
            ),
            if (others.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...others.asMap().entries.map((entry) {
                final idx = entry.key;
                final data = entry.value;
                return RunnerResult(
                  rank: idx + 2,
                  nickname: data['nickname'] ?? '알 수 없음',
                  distance: _formatDistance(data['distance']),
                  time: _formatTime(data['runningTime']),
                  imageUrl:
                      data['profileImageUrl'] ?? 'https://picsum.photos/200',
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      children: [
        SvgPicture.asset('assets/icons/gold_medal.svg', height: 32),
        const SizedBox(width: 12),
        const Text(
          '오늘의 TOP 러너',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return '0.00 km';
    final parsedDistance =
        distance is String
            ? double.tryParse(distance) ?? 0
            : (distance is num ? distance.toDouble() : 0);
    return '${parsedDistance.toStringAsFixed(2)} km';
  }

  String _formatTime(dynamic runningTime) {
    final seconds = int.tryParse(runningTime?.toString() ?? '0') ?? 0;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
