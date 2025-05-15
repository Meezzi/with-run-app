import 'package:flutter/material.dart';

class RunnerResult extends StatelessWidget {
  final int rank;
  final String nickname;
  final String distance;
  final String time;
  final String imageUrl;

  const RunnerResult({
    super.key,
    required this.rank,
    required this.nickname,
    required this.distance,
    required this.time,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$rank',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              nickname,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(distance, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
