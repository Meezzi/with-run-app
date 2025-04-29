import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/ui/pages/chat_information/chat_participant_list.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';

class ChatInformationPage extends ConsumerWidget {
  const ChatInformationPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoom = ref.read(chatRoomViewModel);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${chatRoom?.title ?? ''}'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: ChatParticipantList()
      ),
    );
  }
}