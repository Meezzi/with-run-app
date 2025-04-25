import 'package:flutter/material.dart';
import 'package:with_run_app/ui/pages/chat_information/chat_participant_list.dart';

class ChatInformationPage extends StatelessWidget {
  const ChatInformationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('채팅방 이름'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: ChatParticipantList()
      ),
    );
  }
}