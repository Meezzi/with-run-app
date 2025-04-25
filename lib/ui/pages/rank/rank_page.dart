import 'package:flutter/material.dart';
import 'package:with_run_app/ui/pages/rank/widgets/my_result_summary_card.dart';
import 'package:with_run_app/ui/pages/rank/widgets/top_runner_summary_card.dart';

class RankPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFF036FF4), foregroundColor: Colors.white,),
      backgroundColor: Color(0xFF036FF4),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ListView(
          children: [
            MyResultSummaryCard(),
            SizedBox(height: 16),
            TopRunnerSummaryCard(),
          ],
        ),
      ),
    );
  }
}
