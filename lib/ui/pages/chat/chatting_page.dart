import 'package:flutter/material.dart';
import 'package:with_run_app/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/message_provider.dart'; // message_provider.dart import

// 채팅방 화면을 정의하는 ConsumerWidget
class ChatRoomPage extends ConsumerWidget {
  final String roomName; // 채팅방 이름
  final String location; // 채팅방 위치 정보
  final String adminNickname; // 채팅방 관리자 닉네임

  const ChatRoomPage({
    super.key,
    required this.roomName,
    required this.location,
    required this.adminNickname,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // messageProvider에서 메시지 리스트 가져오기
    final messages = ref.watch(messageProvider);
    // 메시지 전송을 위해 notifier 가져오기
    final notifier = ref.read(messageProvider.notifier);
    // 텍스트 입력 필드 컨트롤러
    final TextEditingController _controller = TextEditingController();
    // ListView 스크롤 컨트롤러
    final ScrollController _scrollController = ScrollController();

    return Scaffold(
      // 상단 앱바
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(roomName, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(location, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      // 화면 본문
      body: Column(
        children: [
          // 메시지 목록을 표시하는 ListView
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, // 최신 메시지가 아래에 표시
              padding: EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return ChatBubble(
                  isMe: msg.isMe,
                  text: msg.text,
                  time: msg.time,
                  profileUrl: msg.profileUrl,
                  nickname: msg.nickname,
                );
              },
            ),
          ),
          // 메시지 입력 필드
          ChatInputField(
            controller: _controller,
            onSend: () {
              final text = _controller.text.trim();
              if (text.isNotEmpty) {
                notifier.sendMessage(text); // notifier를 통해 메시지 전송
                _controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}

// 개별 메시지 버블을 표시하는 StatelessWidget
class ChatBubble extends StatelessWidget {
  final bool isMe; // 내가 보낸 메시지인지 여부
  final String text; // 메시지 내용
  final String time; // 전송 시간
  final String profileUrl; // 프로필 이미지 URL
  final String nickname; // 보낸 사람 닉네임

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
      // 내가 보낸 메시지는 오른쪽, 다른 사람 메시지는 왼쪽 정렬
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 내가 보낸 메시지가 아니면 프로필 이미지와 간격 표시
        if (!isMe) ...[
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(profileUrl),
          ),
          SizedBox(width: 8),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // 내가 보낸 메시지가 아니면 닉네임 표시
              if (!isMe)
                Text(
                  nickname,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              // 메시지 내용이 담긴 컨테이너
              Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue[100] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(text),
              ),
              // 메시지 전송 시간
              Text(
                time,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        // 내가 보낸 메시지면 오른쪽에 간격 추가
        if (isMe) SizedBox(width: 8),
      ],
    );
  }
}

// 메시지 입력 필드와 전송 버튼을 포함하는 StatelessWidget
class ChatInputField extends StatelessWidget {
  final TextEditingController controller; // 텍스트 입력 컨트롤러
  final VoidCallback onSend; // 전송 버튼 클릭 시 호출되는 콜백

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
          // 텍스트 입력 필드
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(), // 엔터 키로도 전송 가능
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
          // 전송 버튼
          IconButton(
            icon: Icon(Icons.send),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}