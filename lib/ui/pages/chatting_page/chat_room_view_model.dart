import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/repository/chat_room_firebase_repository.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:with_run_app/data/model/user.dart' as app_user;

class ChatRoomViewModel extends Notifier<ChatRoomModel?>{
  final repository = ChatRoomFirebaseRepository();
  
  Future<ChatRoomModel?> enterChatRoom(String roomId) async{
    try {
      ChatRoomModel result = await repository.get(roomId);
      state = result;
      return result;
    } catch (e) {
      debugPrint('채팅방 입장 오류: $e');
      return null;
    }
  }

  Future<void> addParticipant(String chatRoomId) async {
    if (chatRoomId.isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final appUser = app_user.User(
        uid: user.uid,
        nickname: user.displayName ?? '사용자',
        profileImageUrl: user.photoURL ?? '',
      );
      
      await repository.addParticipant(appUser, chatRoomId);
    } catch (e) {
      debugPrint('참가자 추가 오류: $e');
    }
  }

  void leaveChatRoom(){
    state = null;
  }
  
  @override
  ChatRoomModel? build() {
    return null;
  }
}

final chatRoomRepositoryProvider = Provider<ChatRoomRepository>((ref) {
  return ChatRoomFirebaseRepository();
});

final chatRoomViewModel = NotifierProvider<ChatRoomViewModel, ChatRoomModel?>(() {
  return ChatRoomViewModel();
});