import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class TopRunnerSummaryCard extends StatelessWidget {
  const TopRunnerSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                SvgPicture.asset('assets/icons/gold_medal.svg', height: 32),
                SizedBox(width: 16),
                Text(
                  '오늘의 TOP 러너',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 20),
            TopRunnerInfo(
              nickname: '이닉네임',
              distance: '6.2km',
              time: '56:00',
              imageUrl: 'https://picsum.photos/200',
            ),

            SizedBox(height: 20),
            // TODO : Rank 페이지에서 리스트뷰로 해결하기
            ...List.generate(8, (index) {
              return Column(
                children: [
                  RunnerResult(
                    rank: index,
                    nickname: '박닉네임',
                    distance: '5.5km',
                    time: '47:20',
                    imageUrl: 'https://picsum.photos/200',
                  ),
                  // SizedBox(height: 20),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 32),
        SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nickname,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  distance,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 40),
                Text(
                  time,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            '$rank',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(width: 16),
          CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 28),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              nickname,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Text(
            distance,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(width: 16),
          Text(
            time,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
