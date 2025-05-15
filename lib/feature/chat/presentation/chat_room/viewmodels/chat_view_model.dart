import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ChatState 클래스
class ChatState {
  final String chatRoomName;
  final String adminNickname;
  final String location;

  ChatState({
    required this.chatRoomName,
    required this.adminNickname,
    required this.location,
  });

  ChatState copyWith({
    String? chatRoomName,
    String? adminNickname,
    String? location,
  }) {
    return ChatState(
      chatRoomName: chatRoomName ?? this.chatRoomName,
      adminNickname: adminNickname ?? this.adminNickname,
      location: location ?? this.location,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatRoomName': chatRoomName,
      'adminNickname': adminNickname,
      'location': location,
    };
  }

  factory ChatState.fromMap(Map<String, dynamic> map) {
    return ChatState(
      chatRoomName: map['chatRoomName'] ?? '',
      adminNickname: map['adminNickname'] ?? '',
      location: map['location'] ?? '',
    );
  }
}

// ChatViewModel 클래스
class ChatViewModel extends Notifier<ChatState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  ChatState build() => ChatState(chatRoomName: '', adminNickname: '', location: '');

  // Firestore에서 채팅방 데이터 가져오기
  Stream<ChatState> streamChatRoom(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) => ChatState.fromMap(snapshot.data() ?? {}));
  }

  // 채팅방 데이터 업데이트
  Future<void> updateChatRoom(String chatRoomId, ChatState newState) async {
    await _firestore.collection('chatRooms').doc(chatRoomId).set(newState.toMap());
    state = newState;
  }

  // 채팅방 이름 업데이트
  void updateChatRoomName(String name) {
    state = state.copyWith(chatRoomName: name);
  }

  // 방장 닉네임 업데이트
  void updateAdminNickname(String nickname) {
    state = state.copyWith(adminNickname: nickname);
  }

  // 위치 업데이트
  void updateLocation(String loc) {
    state = state.copyWith(location: loc);
  }
}

// Provider 정의
final chatViewModelProvider = NotifierProvider<ChatViewModel, ChatState>(() {
  return ChatViewModel();
});

// Firestore 스트림 Provider
final chatRoomStreamProvider = StreamProvider.family<ChatState, String>((ref, chatRoomId) {
  return ref.read(chatViewModelProvider.notifier).streamChatRoom(chatRoomId);
});