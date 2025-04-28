import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 메시지 데이터를 나타내는 클래스
class Message {
  final bool isMe; // 내가 보낸 메시지인지 여부
  final String text; // 메시지 내용
  final String time; // 전송 시간
  final String profileUrl; // 프로필 이미지 URL
  final String nickname; // 보낸 사람 닉네임

  Message({
    required this.isMe,
    required this.text,
    required this.time,
    required this.profileUrl,
    required this.nickname,
  });

  // Map에서 Message 객체로 변환
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      isMe: map['isMe'] ?? false,
      text: map['text'] ?? '',
      time: map['time'] ?? '',
      profileUrl: map['profileUrl'] ?? '',
      nickname: map['nickname'] ?? '',
    );
  }

  // Message 객체를 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'isMe': isMe,
      'text': text,
      'time': time,
      'profileUrl': profileUrl,
      'nickname': nickname,
    };
  }
}

// 메시지 상태를 관리하는 StateNotifier
class MessageNotifier extends StateNotifier<List<Message>> {
  MessageNotifier()
      : super([
          // 초기 예시 메시지 데이터
          Message(
            isMe: false,
            text: '뜁시다',
            time: '오후 3:40',
            nickname: '청국장',
            profileUrl: 'https://ibb.co/t0w29M9',
          ),
          Message(
            isMe: false,
            text: 'ㄱㄱ',
            time: '오후 3:42',
            nickname: '된찌',
            profileUrl: 'https://example.com/profile2.jpg',
          ),
          Message(
            isMe: false,
            text: '기기',
            time: '오후 3:45',
            nickname: '제육',
            profileUrl: 'https://example.com/profile3.jpg',
          ),
        ]);

  // 새 메시지를 추가하는 함수
  void sendMessage(String text) {
    state = [
      Message(
        isMe: true,
        text: text,
        time: '오후 3:50', // 하드코딩된 시간 (실제로는 현재 시간 사용 권장)
        nickname: '나',
        profileUrl: 'https://example.com/myprofile.jpg',
      ),
      ...state,
    ];
  }
}

// 메시지 상태를 제공하는 Provider
final messageProvider = StateNotifierProvider<MessageNotifier, List<Message>>(
  (ref) => MessageNotifier(),
);