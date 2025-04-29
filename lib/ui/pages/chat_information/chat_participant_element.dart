import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:with_run_app/data/model/user.dart';

class ChatParticipantElement extends StatelessWidget {
  const ChatParticipantElement({
    required this.participant,
    super.key,
    this.isCreator = false,
  });
  final User participant;
  final bool isCreator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.network(participant.profileImageUrl!),
            ),
          ),
          SizedBox(width: 20),
          Text(participant.nickname ?? '', style: TextStyle(fontSize: 20)),
          Spacer(),
          isCreator
              ? SvgPicture.asset(
                'assets/icons/crown.svg',
                width: 30,
                height: 30,
              )
              : Icon(Icons.person, size: 40),
        ],
      ),
    );
  }
}
