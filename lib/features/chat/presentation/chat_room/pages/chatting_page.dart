import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/viewmodels/message_provider.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/viewmodels/participant_provider.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/widgets/chatting/chat_bubble.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/widgets/chatting/chat_input_field.dart';
import 'package:with_run_app/features/chat/presentation/chat_room/widgets/chatting/icon_button.dart';

class ChattingPage extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String myUserId;
  final String roomName;
  final String location;

  const ChattingPage({
    super.key,
    required this.chatRoomId,
    required this.myUserId,
    required this.roomName,
    required this.location,
  });

  @override
  ConsumerState<ChattingPage> createState() => _ChattingPageState();
}

class _ChattingPageState extends ConsumerState<ChattingPage> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late final MessageProviderArgs _args;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _args = MessageProviderArgs(
      chatRoomId: widget.chatRoomId,
      myUserId: widget.myUserId,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messageProvider(_args));
    final notifier = ref.read(messageProvider(_args).notifier);
    final participantsAsync = ref.watch(participantProvider(widget.chatRoomId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(widget.location, style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              children: [
                iconButton('assets/icons/run_time.svg', Colors.black),
                iconButton('assets/icons/user_list.svg', Colors.black),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  color: Colors.black,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('참가자 정보를 가져오는 중 오류 발생!')),
        data: (participants) {
          return Column(
            children: [
              Expanded(
                child:
                    messages.isEmpty
                        ? const Center(child: Text('대화를 시작해 보세요!'))
                        : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(8),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final participant = participants[msg.senderId];

                            return ChatBubble(
                              senderId: msg.senderId,
                              myUserId: widget.myUserId,
                              text: msg.text,
                              time: DateFormat(
                                'a h:mm',
                                'ko_KR',
                              ).format(msg.timestamp),
                              nickname: participant?.nickname ?? '알 수 없음',
                              profileImageUrl:
                                  participant?.profileImageUrl ?? '',
                            );
                          },
                        ),
              ),
              SafeArea(
                child: ChatInputField(
                  controller: _controller,
                  onSend: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      notifier.sendMessage(text);
                      _controller.clear();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.minScrollExtent,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
