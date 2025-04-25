import 'package:flutter_riverpod/flutter_riverpod.dart';

class Message {
  final String text;
  final String time;
  final String nickname;
  final String profileUrl;
  final bool isMe;

  Message({
    required this.text,
    required this.time,
    required this.nickname,
    required this.profileUrl,
    required this.isMe,
  });
}

class MessageNotifier extends StateNotifier<List<Message>> {
  MessageNotifier() : super([
    Message(
      text: '뜁시다',
      time: '오후 3:40',
      nickname: '청국장',
      profileUrl: 'https://ibb.co/t0w29M9',
      isMe: false,
    ),
    Message(
      text: 'ㄱㄱ',
      time: '오후 3:42',
      nickname: '된찌',
      profileUrl: 'https://example.com/profile2.jpg',
      isMe: false,
    ),
    Message(
      text: '기기',
      time: '오후 3:45',
      nickname: '제육',
      profileUrl: 'https://example.com/profile3.jpg',
      isMe: false,
    ),
  ]);

  void sendMessage(String text) {
    final newMessage = Message(
      text: text,
      time: '오후 3:50', // 실제 앱이면 현재 시간 포맷팅 필요
      nickname: '나',
      profileUrl: 'https://example.com/myprofile.jpg',
      isMe: true,
    );
    state = [newMessage, ...state];
  }
}

final messageProvider =
    StateNotifierProvider<MessageNotifier, List<Message>>((ref) {
  return MessageNotifier();
});