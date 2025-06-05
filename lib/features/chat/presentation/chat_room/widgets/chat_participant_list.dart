import 'package:flutter/material.dart';
import 'package:with_run_app/features/auth/presentation/login/models/login_model.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/widgets/chat_participant_element.dart';

class ChatParticipantList extends StatelessWidget {
  const ChatParticipantList({
    required this.participants,
    required this.creator,
    super.key,
  });
  
  final List<UserModel> participants;
  final UserModel creator;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (context, index) {
        return ChatParticipantElement(
          participant: participants[index].toEntity(),
          isCreator: creator.id == participants[index].id,
        );
      },
    );
  }
}
