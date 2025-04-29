import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/data/model/user.dart';

class ChatListViewModel extends StateNotifier<AsyncValue<List<ChatRoomModel>>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _roomsSubscription;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ChatListViewModel() : super(const AsyncValue.loading()) {
    // 생성자에서 실시간 구독 시작
    _subscribeToJoinedChatRooms();
  }

  // 사용자가 참여한 채팅방을 실시간으로 구독
  void _subscribeToJoinedChatRooms() {
    // 로딩 상태로 변경
    state = const AsyncValue.loading();
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    
    try {
      // 참가자 컬렉션에서 현재 사용자 ID를 포함하는 채팅방 ID 목록을 가져오는 쿼리
      _roomsSubscription = _firestore
          .collection('chatRooms')
          .snapshots()
          .listen(_handleChatRoomsSnapshot, onError: _handleError);
    } catch (e) {
      _handleError(e);
    }
  }

  // 채팅방 스냅샷 처리 메서드
  Future<void> _handleChatRoomsSnapshot(QuerySnapshot snapshot) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        state = const AsyncValue.data([]);
        return;
      }

      List<ChatRoomModel> rooms = [];
      
      for (var doc in snapshot.docs) {
        try {
          // 참가자 확인을 위해 서브컬렉션 확인
          final participantsSnapshot = await _firestore
              .collection('chatRooms')
              .doc(doc.id)
              .collection('participants')
              .doc(userId)
              .get();
              
          // 현재 사용자가 참가자인 경우에만 추가
          if (participantsSnapshot.exists) {
            // 모든 참가자 정보 가져오기
            final allParticipantsSnapshot = await _firestore
                .collection('chatRooms')
                .doc(doc.id)
                .collection('participants')
                .get();
            
            final participants = allParticipantsSnapshot.docs.map((e) {
              final userData = e.data();
              final user = User(
                uid: e.id,
                nickname: userData['nickname'],
                profileImageUrl: userData['profileImageUrl'],
              );
              return user;
            }).toList();
            
            rooms.add(ChatRoomModel.fromFirestore(doc, participants));
          }
        } catch (e) {
          debugPrint('채팅방 데이터 처리 오류 (${doc.id}): $e');
        }
      }
      
      state = AsyncValue.data(rooms);
    } catch (e) {
      _handleError(e);
    }
  }

  // 오류 처리 메서드
  void _handleError(dynamic error) {
    debugPrint('채팅방 목록 로드 오류: $error');
    state = AsyncValue.error(error, StackTrace.current);
  }

  // 수동 새로고침 메서드 (필요 시 호출)
  Future<void> refreshChatRooms() async {
    // 현재 구독 취소 후 다시 구독
    await _roomsSubscription?.cancel();
    _subscribeToJoinedChatRooms();
  }

  // 채팅방 참여 메서드
  Future<void> joinChatRoom(BuildContext context, ChatRoomModel chatRoom) async {
    if (!context.mounted) return;
    
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(context, '로그인이 필요합니다.', isError: true);
      return;
    }

    try {
      // 사용자 정보 가져오기
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!context.mounted) return;
      
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
      
      if (!context.mounted) return;
      
      _showSnackBar(context, '채팅방에 참여했습니다.');
      
      // 참여 후 목록 새로고침 - 실시간 구독 중이므로 자동으로 업데이트됨
    } catch (e) {
      debugPrint('채팅방 참여 오류: $e');
      if (context.mounted) {
        _showSnackBar(context, '오류 발생: $e', isError: true);
      }
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
  
  @override
  void dispose() {
    // 구독 취소
    _roomsSubscription?.cancel();
    super.dispose();
  }
}

final chatListViewModelProvider =
    StateNotifierProvider<ChatListViewModel, AsyncValue<List<ChatRoomModel>>>((ref) {
  return ChatListViewModel();
});