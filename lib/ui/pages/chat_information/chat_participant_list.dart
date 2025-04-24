import 'package:flutter/material.dart';
import 'package:with_run_app/ui/pages/chat_information/chat_participant_element.dart';

class ChatParticipantList extends StatelessWidget {
  const ChatParticipantList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ChatParticipantElement();
      },
    );
  }
}