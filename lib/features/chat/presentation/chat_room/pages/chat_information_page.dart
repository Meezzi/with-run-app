import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/widgets/chat_participant_list.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/viewmodels/chat_room_view_model.dart';

class ChatInformationPage extends ConsumerWidget {
  const ChatInformationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatRoom = ref.watch(chatRoomViewModel);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('${chatRoom?.title ?? ''}'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: ChatParticipantList(
            participants: chatRoom?.participants ?? [],
            creator: chatRoom!.creator,
          ),
        ),
      ),
    );
  }
}
