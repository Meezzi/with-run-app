import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/data/repository/chat_room_firebase_repository.dart';
import 'package:with_run_app/data/repository/chat_room_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:with_run_app/data/model/user.dart' as app_user;
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';

class ChatRoomViewModel extends Notifier<ChatRoomModel?>{
  final repository = ChatRoomFirebaseRepository();
  late final Ref _ref;
  
  Future<ChatRoomModel?> enterChatRoom(String roomId) async {
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

  // 사용자가 이미 다른 채팅방에 참여 중인지 확인
  Future<bool> isUserInAnyRoom() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final userId = user.uid;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chatRooms')
          .get();
      
      for (var doc in querySnapshot.docs) {
        final participantsQuery = await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(doc.id)
            .collection('participants')
            .doc(userId)
            .get();
        
        if (participantsQuery.exists) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('채팅방 참여 여부 확인 오류: $e');
      return false;
    }
  }

  // 사용자가 생성한 채팅방이 있는지 확인
  Future<bool> userHasCreatedRoom() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final userId = user.uid;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chatRooms')
          .where('creator.uid', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('채팅방 생성 여부 확인 오류: $e');
      return false;
    }
  }
  
  // 사용자가 채팅방에서 나가기
  Future<bool> leaveRoom() async {
    if (state == null) return false;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    try {
      // 사용자가 방장인지 확인
      final isCreator = state!.creator?.uid == user.uid;
      
      if (isCreator) {
        // 방장이면 채팅방 삭제 (서브컬렉션까지 모두 삭제)
        await _deleteRoom(state!.id!);
      } else {
        // 일반 참여자면 참가자 목록에서 제거
        await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(state!.id)
            .collection('participants')
            .doc(user.uid)
            .delete();
      }
      
      // 상태 초기화
      state = null;
      
      // 맵 새로고침
      await refreshMap();
      
      return true;
    } catch (e) {
      debugPrint('채팅방 나가기 오류: $e');
      return false;
    }
  }
  
  // 채팅방과 관련된 모든 데이터 삭제
  Future<void> _deleteRoom(String chatRoomId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final db = FirebaseFirestore.instance;
      
      // 1. 참가자 컬렉션 삭제
      final participantsSnapshot = await db
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('participants')
          .get();
          
      for (var doc in participantsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // 2. 메시지 컬렉션 삭제
      final messagesSnapshot = await db
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .get();
          
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // 배치 작업 커밋
      await batch.commit();
      
      // 3. 마지막으로 채팅방 문서 삭제
      await db.collection('chatRooms').doc(chatRoomId).delete();
      
      debugPrint('채팅방 $chatRoomId 삭제 완료');
    } catch (e) {
      debugPrint('채팅방 삭제 오류: $e');
      throw e; // 에러를 상위로 전파
    }
  }

  void leaveChatRoom(){
    state = null;
  }
  
  // 맵 새로고침 기능
  Future<void> refreshMap() async {
    try {
      await _ref.read(mapProvider.notifier).refreshMap();
    } catch (e) {
      debugPrint('맵 새로고침 오류: $e');
    }
  }
  
  @override
  ChatRoomModel? build() {
    _ref = ref;
    return null;
  }
}

final chatRoomRepositoryProvider = Provider<ChatRoomRepository>((ref) {
  return ChatRoomFirebaseRepository();
});

final chatRoomViewModel = NotifierProvider<ChatRoomViewModel, ChatRoomModel?>(() {
  return ChatRoomViewModel();
});