import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/services/chat_service.dart';
// import 'package:with_run_app/ui/pages/chat/chat_room_page.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';


class ChatRoomInfoViewModel extends StateNotifier<AsyncValue<String>> {
  final Ref _ref;
  final ChatService _chatService = ChatService();
  final ChatRoom chatRoom;

  ChatRoomInfoViewModel(this._ref, this.chatRoom) : super(const AsyncValue.loading()) {
    _getAddress();
  }

  Future<void> _getAddress() async {
    state = const AsyncValue.loading();
    try {
      final address = await _getAddressFromLatLng(chatRoom.location.latitude, chatRoom.location.longitude);
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
      debugPrint('Geocoding 오류: $e'); // 전역 함수로 호출
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
    if (chatRoom.creatorId == userId) {
    }

    // 채팅방 참여 제한 확인
    final hasJoinedRoom = await _checkUserHasJoinedRoom(userId);
    if (!context.mounted) return;

    if (hasJoinedRoom) {
      _showSnackBar(context, '이미 참여 중인 채팅방이 있습니다. 한 번에 하나의 채팅방에만 참여할 수 있습니다.', isError: true);
      return;
    }

    // try {
    //   final result = await _chatService.joinChatRoom(chatRoom.id);
    //   if (!context.mounted) return;
    //   if (result) {
    //     Navigator.push(
    //       context,
    //       MaterialPageRoute(
    //         builder: (context) => ChatRoomPage(
    //           chatRoom: chatRoom,
    //           onRoomDeleted: () => _ref.read(mapProvider.notifier).refreshMapAfterRoomDeletion(chatRoom.id),
    //         ),
    //       ),
    //     );
    //   } else {
    //     _showSnackBar(context, '채팅방 참여에 실패했습니다.', isError: true);
    //   }
    // } catch (e) {
    //   debugPrint('채팅방 참여 오류: $e'); // 전역 함수로 호출
    //   _showSnackBar(context, '오류 발생: $e', isError: true);
    // }
  }

  Future<bool> _checkUserHasJoinedRoom(String userId) async {
    try {
      final rooms = await _chatService.getJoinedChatRooms(userId);
      return rooms.isNotEmpty;
    } catch (e) {
      debugPrint('사용자 참여 채팅방 확인 오류: $e'); // 전역 함수로 호출
      return false;
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

final chatRoomInfoViewModelProvider = StateNotifierProvider.family<ChatRoomInfoViewModel, AsyncValue<String>, ChatRoom>(
  (ref, chatRoom) => ChatRoomInfoViewModel(ref, chatRoom),
);