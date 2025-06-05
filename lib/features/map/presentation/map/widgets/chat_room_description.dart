import 'package:flutter/material.dart';

class ChatRoomDescription extends StatelessWidget {
  final String description;

  const ChatRoomDescription(this.description, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
