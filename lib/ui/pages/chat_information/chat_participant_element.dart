import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatParticipantElement extends StatelessWidget {
  const ChatParticipantElement({super.key});

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
          ),
          SizedBox(width: 20,),
          Text('닉네임', style: TextStyle(fontSize: 20)),
          Spacer(),
          SvgPicture.asset('assets/icons/crown.svg', width: 30, height: 30,),
        ],
      ),
    );
  }
}
