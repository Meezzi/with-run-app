import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/services/chat_service.dart';


class ChatListViewModel extends StateNotifier<AsyncValue<List<ChatRoom>>> {
 
  final ChatService _chatService = ChatService();

  ChatListViewModel() : super(const AsyncValue.loading()) {
    loadJoinedChatRooms();
  }

  Future<void> loadJoinedChatRooms() async {
    state = const AsyncValue.loading();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final dynamicRooms = userId != null
          ? await _chatService.getJoinedChatRooms(userId)
          : [];
      final rooms = dynamicRooms
          .map((room) => room as ChatRoom)
          .toList();
      state = AsyncValue.data(rooms);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> joinChatRoom(BuildContext context, ChatRoom chatRoom) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar(context, '로그인이 필요합니다.', isError: true);
      return;
    }

    // try {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => ChatRoomPage(
    //         chatRoom: chatRoom,
    //         onRoomDeleted: () => _ref.read(mapProvider.notifier).refreshMapAfterRoomDeletion(chatRoom.id),
    //       ),
    //     ),
    //   );
    // } catch (e) {
    //   debugPrint('채팅방 참여 오류: $e');
    //   _showSnackBar(context, '오류 발생: $e', isError: true);
    // }
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
    StateNotifierProvider<ChatListViewModel, AsyncValue<List<ChatRoom>>>((ref) {
  return ChatListViewModel();
});