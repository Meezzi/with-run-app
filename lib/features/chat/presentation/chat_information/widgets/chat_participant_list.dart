import 'package:flutter/material.dart';
import 'package:with_run_app/features/auth/data/user.dart';
import 'package:with_run_app/features/chat/presentation/chat_information/widgets/chat_participant_element.dart';

class ChatParticipantList extends StatelessWidget {
  const ChatParticipantList({required this.participants, required this.creator, super.key});
  final List<User> participants;
  final User creator;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return ChatParticipantElement(participant: participants[index], isCreator: creator.uid == participants[index].uid,);
      },
    );
  }
}