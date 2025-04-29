import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String senderId;
  final String myUserId;
  final String text;
  final String time;
  final String nickname;
  final String profileImageUrl;

  const ChatBubble({
    super.key,
    required this.senderId,
    required this.myUserId,
    required this.text,
    required this.time,
    required this.nickname,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isMyMessage = senderId == myUserId;
    
    // 시스템 메시지인 경우 (입장, 퇴장 메시지)
    if (senderId == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(profileImageUrl.isNotEmpty
                  ? profileImageUrl
                  : 'https://via.placeholder.com/150'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // 닉네임 표시
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    nickname.isNotEmpty ? nickname : '알 수 없음',
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
                    color: isMyMessage 
                        ? Colors.blue[100] 
                        : Colors.grey[300],
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
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(profileImageUrl.isNotEmpty
                  ? profileImageUrl
                  : 'https://via.placeholder.com/150'),
            ),
          ],
        ],
      ),
    );
  }
}