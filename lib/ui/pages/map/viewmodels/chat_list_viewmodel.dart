import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatListViewModel extends StateNotifier<AsyncValue<List<ChatRoomModel>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ChatListViewModel() : super(const AsyncValue.loading()) {
    loadJoinedChatRooms();
  }

  Future<void> loadJoinedChatRooms() async {
    state = const AsyncValue.loading();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        state = AsyncValue.data([]);
        return;
      }
      
      final snapshot = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .get();
          
      // 참여 중인 채팅방 목록
      List<ChatRoomModel> rooms = [];
      
      for (var doc in snapshot.docs) {
        try {
          // 참가자 목록 가져오기
          final participantsSnapshot = await _firestore
              .collection('chatRooms')
              .doc(doc.id)
              .collection('participants')
              .get();
              
          final participants = participantsSnapshot.docs.map((e) {
            return e.data();
          }).toList();
          
          // 채팅방 데이터를 ChatRoomModel로 변환
          // 이 부분은 필요에 따라 실제 데이터 구조에 맞게 수정해야 함
          final room = await _firestore
              .collection('chatRooms')
              .doc(doc.id)
              .get();
          
          if (room.exists) {
            rooms.add(ChatRoomModel.fromFirestore(room, []));
          }
        } catch (e) {
          debugPrint('채팅방 데이터 변환 오류: $e');
        }
      }
      
      state = AsyncValue.data(rooms);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> joinChatRoom(BuildContext context, ChatRoomModel chatRoom) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(context, '로그인이 필요합니다.', isError: true);
      return;
    }

    try {
      // 사용자 정보 가져오기
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        _showSnackBar(context, '사용자 정보를 찾을 수 없습니다.', isError: true);
        return;
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // 참가자로 추가
      await _firestore
          .collection('chatRooms')
          .doc(chatRoom.id)
          .collection('participants')
          .doc(userId)
          .set({
            'nickname': userData['nickname'] ?? '사용자',
            'profileImageUrl': userData['profileImageUrl'] ?? '',
          });
      
      _showSnackBar(context, '채팅방에 참여했습니다.');
    } catch (e) {
      debugPrint('채팅방 참여 오류: $e');
      _showSnackBar(context, '오류 발생: $e', isError: true);
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 130),
        elevation: 4,
      ),
    );
  }
}

final chatListViewModelProvider =
    StateNotifierProvider<ChatListViewModel, AsyncValue<List<ChatRoomModel>>>((ref) {
  return ChatListViewModel();
});