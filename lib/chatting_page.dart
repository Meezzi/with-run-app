import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:with_run_app/message_provider.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String myUserId;
  final String roomName;
  final String location;
  final String adminNickname;

  const ChatRoomPage({
    super.key,
    required this.chatRoomId,
    required this.myUserId,
    required this.roomName,
    required this.location,
    required this.adminNickname,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
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

    print('Building UI with ${messages.length} messages');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.location, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return ChatBubble(
                        senderId: msg.senderId,
                        myUserId: widget.myUserId,
                        text: msg.text,
                        time: DateFormat('a h:mm', 'ko_KR').format(msg.timestamp),
                      );
                    },
                  ),
          ),
          ChatInputField(
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
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String senderId;
  final String myUserId;
  final String text;
  final String time;

  const ChatBubble({
    super.key,
    required this.senderId,
    required this.myUserId,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final isMyMessage = senderId == myUserId; // senderId와 myUserId 비교
    print('senderId: $senderId, myUserId: $myUserId, isMyMessage: $isMyMessage');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage) // 상대방 메시지에만 닉네임(senderId) 표시
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      senderId, // senderId를 닉네임처럼 표시
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isMyMessage ? Colors.blue[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(text),
                ),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: "메시지를 입력해주세요...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}