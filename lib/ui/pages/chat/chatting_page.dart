import 'package:flutter/material.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomName;
  final String location;
  final String adminNickname;

  const ChatRoomScreen({
    super.key,
    required this.roomName,
    required this.location,
    required this.adminNickname,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 예시 메시지 데이터
  List<Map<String, dynamic>> messages = [
    {
      'text': '뜁시다',
      'time': '오후 3:40',
      'nickname': '청국장',
      'profileUrl': 'https://ibb.co/t0w29M9',
      'isMe': false,
    },
    {
      'text': 'ㄱㄱ',
      'time': '오후 3:42',
      'nickname': '된찌',
      'profileUrl': 'https://example.com/profile2.jpg',
      'isMe': false,
    },
    {
      'text': '기기',
      'time': '오후 3:45',
      'nickname': '제육',
      'profileUrl': 'https://example.com/profile3.jpg',
      'isMe': false,
    },
  ];

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.insert(0, {
        'text': text,
        'time': '오후 3:50',
        'nickname': '나',
        'profileUrl': 'https://example.com/myprofile.jpg',
        'isMe': true,
      });
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName, style: TextStyle(fontWeight: FontWeight.bold)),
            Text("${widget.location}",
                style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatBubble(
                  isMe: msg['isMe'],
                  text: msg['text'],
                  time: msg['time'],
                  profileUrl: msg['profileUrl'],
                  nickname: msg['nickname'],
                );
              },
            ),
          ),
          ChatInputField(
            controller: _controller,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final bool isMe;
  final String text;
  final String time;
  final String profileUrl;
  final String nickname;

  const ChatBubble({
    super.key,
    required this.isMe,
    required this.text,
    required this.time,
    required this.profileUrl,
    required this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          CircleAvatar(radius: 16, backgroundImage: NetworkImage(profileUrl)),
          SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(nickname,
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue[100] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(text),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        if (isMe) SizedBox(width: 8),
      ],
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
      padding: EdgeInsets.all(8),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}