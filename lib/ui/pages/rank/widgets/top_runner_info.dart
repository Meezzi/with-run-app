import 'package:flutter/material.dart';

class TopRunnerInfo extends StatelessWidget {
  final String nickname;
  final String distance;
  final String time;
  final String imageUrl;

  const TopRunnerInfo({
    super.key,
    required this.nickname,
    required this.distance,
    required this.time,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nickname,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(distance, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  Text(time, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
