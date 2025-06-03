import 'package:flutter/material.dart';

class ChatRoomJoinButton extends StatelessWidget {
  const ChatRoomJoinButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // TODO: 채팅방 참여하기
            },
            child: const Text(
              '참여하기',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
