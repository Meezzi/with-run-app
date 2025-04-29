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
  bool _isProcessing = false; // 중복 처리 방지 플래그
  
  // 채팅방 입장 및 채팅방 정보 가져오기
  Future<ChatRoomModel?> enterChatRoom(String roomId) async {
    if (_isProcessing) {
      debugPrint('이미 처리 중입니다. 중복 요청 무시');
      return null;
    }
    
    _isProcessing = true;
    
    try {
      debugPrint('채팅방 입장 시작: $roomId');
      
      // 채팅방 정보 가져오기
      ChatRoomModel result = await repository.get(roomId);
      
      // 사용자가 아직 참가자가 아니면 참가자로 추가
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        bool isAlreadyParticipant = false;
        
        // 참가자 목록 확인
        if (result.participants != null) {
          isAlreadyParticipant = result.participants!.any((p) => p.uid == user.uid);
        }
        
        // 아직 참가자가 아니면 추가
        if (!isAlreadyParticipant) {
          await _ensureUserIsParticipant(roomId, user.uid);
        }
      }
      
      // 최신 정보 다시 가져오기
      result = await repository.get(roomId);
      
      // 상태 업데이트
      state = result;
      
      debugPrint('채팅방 입장 성공: $roomId');
      _isProcessing = false;
      return result;
    } catch (e) {
      debugPrint('채팅방 입장 오류: $e');
      _isProcessing = false;
      return null;
    }
  }
  
  // 사용자가 참가자인지 확인하고 아니면 참가자로 추가
  Future<void> _ensureUserIsParticipant(String chatRoomId, String userId) async {
    try {
      // 먼저 사용자 정보 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      String nickname = '사용자';
      String profileImageUrl = '';
      
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        nickname = userData['nickname'] ?? '사용자';
        profileImageUrl = userData['profileImageUrl'] ?? '';
      } else {
        // users 컬렉션에 없으면 Firebase Auth에서 가져오기
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null) {
          nickname = authUser.displayName ?? '사용자';
          profileImageUrl = authUser.photoURL ?? '';
        }
      }
      
      // 참가자로 추가
      final appUser = app_user.User(
        uid: userId,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
      );
      
      await repository.addParticipant(appUser, chatRoomId);
      debugPrint('사용자 $nickname을(를) 채팅방 $chatRoomId의 참가자로 추가했습니다.');
    } catch (e) {
      debugPrint('참가자 추가 오류: $e');
    }
  }
  
  // 채팅방 정보만 가져오는 메서드 (상태 변경 없음)
  Future<ChatRoomModel?> getChatRoomInfo(String roomId) async {
    try {
      ChatRoomModel result = await repository.get(roomId);
      return result;
    } catch (e) {
      debugPrint('채팅방 정보 조회 오류: $e');
      return null;
    }
  }

  // 참가자 추가
  Future<void> addParticipant(String chatRoomId) async {
    if (chatRoomId.isEmpty) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // 먼저 사용자 정보 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      String nickname = user.displayName ?? '사용자';
      String profileImageUrl = user.photoURL ?? '';
      
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        nickname = userData['nickname'] ?? nickname;
        profileImageUrl = userData['profileImageUrl'] ?? profileImageUrl;
      }
      
      final appUser = app_user.User(
        uid: user.uid,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
      );
      
      await repository.addParticipant(appUser, chatRoomId);
      debugPrint('참가자 추가 완료: $nickname');
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
      
      // 현재 입장하려는 채팅방에도 이미 참여 중인지 확인하기 위해
      // participants 서브컬렉션을 직접 검색
      final chatRooms = await FirebaseFirestore.instance
          .collection('chatRooms')
          .get();
      
      for (var doc in chatRooms.docs) {
        final participantDoc = await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(doc.id)
            .collection('participants')
            .doc(userId)
            .get();
        
        if (participantDoc.exists) {
          debugPrint('사용자가 이미 채팅방 ${doc.id}에 참여 중입니다.');
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
    if (_isProcessing) {
      debugPrint('이미 처리 중입니다. 중복 요청 무시');
      return false;
    }
    
    _isProcessing = true;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isProcessing = false;
      return false;
    }
    
    final roomId = state!.id;
    final isCreator = state!.creator?.uid == user.uid;
    
    try {
      debugPrint('채팅방 나가기 시작: $roomId, 방장여부: $isCreator');
      
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
      
      // 상태 초기화 - 명시적으로 null로 설정
      state = null;
      
      // 맵 새로고침
      await refreshMap();
      
      _isProcessing = false;
      debugPrint('채팅방 나가기 성공: $roomId');
      return true;
    } catch (e) {
      debugPrint('채팅방 나가기 오류: $e');
      _isProcessing = false;
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
      rethrow; // throw e 대신 rethrow 사용
    }
  }

  // 상태 리셋 (채팅방 나가기)
  void leaveChatRoom(){
    debugPrint('채팅방 상태 리셋');
    state = null;
  }
  
  // 맵 새로고침 기능
  Future<void> refreshMap() async {
    try {
      debugPrint('맵 새로고침 시도');
      await _ref.read(mapProvider.notifier).refreshMap();
      debugPrint('맵 새로고침 성공');
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