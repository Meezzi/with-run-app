import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomInfoViewModel extends StateNotifier<AsyncValue<String>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatRoomModel chatRoom;

  ChatRoomInfoViewModel(this.chatRoom) : super(const AsyncValue.loading()) {
    _getAddress();
  }

  Future<void> _getAddress() async {
    state = const AsyncValue.loading();
    try {
      final address = await _getAddressFromLatLng(
          chatRoom.location.latitude, chatRoom.location.longitude);
      state = AsyncValue.data(address);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<String> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
      }
      return '주소를 가져올 수 없습니다';
    } catch (e) {
      debugPrint('Geocoding 오류: $e');
      return '주소 변환 실패';
    }
  }

  Future<void> joinChatRoom(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(context, '로그인이 필요합니다.', isError: true);
      return;
    }

    // 사용자가 채팅방 생성자인 경우는 참여 가능
    if (chatRoom.creator?.uid == userId) {
      _navigateToChatRoom(context);
      return;
    }

    // 채팅방 참여 제한 확인
    final hasJoinedRoom = await _checkUserHasJoinedRoom(userId);
    if (!context.mounted) return;

    if (hasJoinedRoom) {
      _showSnackBar(context, '이미 참여 중인 채팅방이 있습니다. 한 번에 하나의 채팅방에만 참여할 수 있습니다.', isError: true);
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
      
      if (!context.mounted) return;
      
      _showSnackBar(context, '채팅방에 참여했습니다.');
      _navigateToChatRoom(context);
    } catch (e) {
      debugPrint('채팅방 참여 오류: $e');
      if (context.mounted) {
        _showSnackBar(context, '오류 발생: $e', isError: true);
      }
    }
  }

  Future<bool> _checkUserHasJoinedRoom(String userId) async {
    try {
      final rooms = await _firestore
          .collection('chatRooms')
          .where('participants', arrayContains: userId)
          .limit(1)
          .get();
      return rooms.docs.isNotEmpty;
    } catch (e) {
      debugPrint('사용자 참여 채팅방 확인 오류: $e');
      return false;
    }
  }

  void _navigateToChatRoom(BuildContext context) {
    // 채팅방 화면 이동 로직 구현
    // 예: Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomPage(chatRoom: chatRoom)));
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

final chatRoomInfoViewModelProvider = StateNotifierProvider.family<ChatRoomInfoViewModel, AsyncValue<String>, ChatRoomModel>(
  (ref, chatRoom) => ChatRoomInfoViewModel(chatRoom),
);