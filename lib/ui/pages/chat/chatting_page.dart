import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChattingPage extends StatefulWidget {
  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  final List<Map<String, dynamic>> dummyMessages = [ // 예시
    {
      'messageId': '1',
      'chatRoomId': 'room1',
      'senderId': '지온',
      'text': 'ㄱㄱ?',
      'timestamp': DateTime.now().subtract(Duration(minutes: 10)),
      'isMe': false,
    },
    {
      'messageId': '2',
      'chatRoomId': 'room1',
      'senderId': '나',
      'text': 'ㄱㄱ',
      'timestamp': DateTime.now().subtract(Duration(minutes: 9)),
      'isMe': true,
    },
    {
      'messageId': '3',
      'chatRoomId': 'room1',
      'senderId': '민수',
      'text': '먼저감',
      'timestamp': DateTime.now().subtract(Duration(minutes: 7)),
      'isMe': false,
    },
    {
      'messageId': '4',
      'chatRoomId': 'room1',
      'senderId': '정대',
      'text': '꼴찌 아이스크림사기',
      'timestamp': DateTime.now().subtract(Duration(minutes: 6)),
      'isMe': false,
    },
  ];

  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final newMessage = {
      'messageId': DateTime.now().toString(),
      'chatRoomId': 'room1',
      'senderId': '나',
      'text': _controller.text,
      'timestamp': DateTime.now(),
      'isMe': true,
    };

    setState(() {
      dummyMessages.add(newMessage);
      _controller.clear(); // 입력창 비우기
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("런닝클럽"),
        backgroundColor: Color(0xFF036FF4),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 12),
              itemCount: dummyMessages.length,
              itemBuilder: (context, index) {
                final msg = dummyMessages[index];
                return GroupChatBubble(
                  text: msg['text'],
                  sender: msg['senderId'],
                  time: DateFormat('HH:mm').format(msg['timestamp']),
                  isMe: msg['isMe'],
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

class GroupChatBubble extends StatelessWidget {
  final String text;
  final String sender;
  final String time;
  final bool isMe;

  const GroupChatBubble({
    required this.text,
    required this.sender,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      backgroundColor: Colors.deepPurpleAccent,
      child: Text(sender[0]),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) avatar, // 내가 보낸 메시지가 아니면 아바타 표시
          if (!isMe) SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Text(
                    sender,
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                Container(
                  margin: EdgeInsets.only(top: 2),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue[200] : Colors.grey,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(text),
                    ],
                  ),
                ),
                // 시간 부분
                SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (isMe) SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Text("나"[0]),
            ),
        ],
      ),
    );
  }
}

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final Function onSend;

  const ChatInputField({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "메시지를 입력하세요...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  onSend();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
