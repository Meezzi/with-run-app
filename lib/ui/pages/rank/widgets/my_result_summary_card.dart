import 'package:flutter/material.dart';

class MyResultSummaryCard extends StatelessWidget {
  const MyResultSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage('https://picsum.photos/200'),
                  radius: 48,
                  backgroundColor: Colors.blue[100],
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '김닉네임',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '5.2 km',
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
                DetailResult(title: '평균 속도', content: '10.0km'),
                DetailResult(title: '칼로리', content: '305'),
                DetailResult(title: '걸음 수', content: '7056'),
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
