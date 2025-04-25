import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/services/chat_service.dart';
import 'package:with_run_app/ui/pages/chat/chat_room_page.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';

class ChatRoomInfoWindow extends ConsumerWidget {
  final ChatRoom chatRoom;
  final VoidCallback onDismiss;
  final Function(String, {bool isError}) onShowSnackBar;

  const ChatRoomInfoWindow({
     super.key,
    required this.chatRoom,
    required this.onDismiss,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(Provider<AppThemeProvider>((ref) => AppThemeProvider()));
    final screenSize = MediaQuery.of(context).size;
    const infoWindowWidth = 350.0;
    const infoWindowHeight = 250.0;

    final left = (screenSize.width - infoWindowWidth) / 2;
    final top = (screenSize.height - infoWindowHeight) / 2 - 150;

    return FutureBuilder<String>(
      future: _getAddressFromLatLng(chatRoom.latitude, chatRoom.longitude),
      builder: (context, snapshot) {
        final address = snapshot.data ?? '주소를 가져오는 중...';

        return Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => _joinChatRoom(context, ref),
              child: Container(
                width: infoWindowWidth,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: themeProvider.isDarkMode
                        ? [Colors.grey[800]!, Colors.grey[850]!]
                        : [Colors.white, Colors.grey[100]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: themeProvider.isDarkMode
                                  ? [Colors.blue[400]!, Colors.green[400]!]
                                  : [const Color(0xFF2196F3), const Color(0xFF00E676)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            chatRoom.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (chatRoom.description != null) ...[
                      Text(
                        chatRoom.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[700]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: themeProvider.isDarkMode
                                ? Colors.blue[300]
                                : Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _joinChatRoom(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.isDarkMode
                              ? Colors.blue[400]
                              : const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '채팅방 참여',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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

  Future<void> _joinChatRoom(BuildContext context, WidgetRef ref) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      onShowSnackBar('로그인이 필요합니다.', isError: true);
      onDismiss();
      return;
    }

    // 사용자가 채팅방 생성자인 경우는 참여 가능
    if (chatRoom.creatorId == userId) {
      try {
        onDismiss();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoom: chatRoom,
              onRoomDeleted: () => ref.read(mapProvider.notifier).refreshMapAfterRoomDeletion(chatRoom.id),
            ),
          ),
        );
      } catch (e) {
        debugPrint('채팅방 참여 오류: $e');
        onShowSnackBar('오류 발생: $e', isError: true);
      }
      return;
    }

    // 채팅방 참여 제한 확인
    final chatService = ChatService();
    final hasJoinedRoom = await _checkUserHasJoinedRoom(chatService, userId);
    if (!context.mounted) return;
    
    if (hasJoinedRoom) {
      onShowSnackBar('이미 참여 중인 채팅방이 있습니다. 한 번에 하나의 채팅방에만 참여할 수 있습니다.', isError: true);
      onDismiss();
      return;
    }

    try {
      onDismiss();
      final result = await chatService.joinChatRoom(chatRoom.id);
      if (!context.mounted) return;
      if (result) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoom: chatRoom,
              onRoomDeleted: () => ref.read(mapProvider.notifier).refreshMapAfterRoomDeletion(chatRoom.id),
            ),
          ),
        );
      } else {
        onShowSnackBar('채팅방 참여에 실패했습니다.', isError: true);
      }
    } catch (e) {
      debugPrint('채팅방 참여 오류: $e');
      onShowSnackBar('오류 발생: $e', isError: true);
    }
  }

  Future<bool> _checkUserHasJoinedRoom(ChatService chatService, String userId) async {
    try {
      final rooms = await chatService.getJoinedChatRooms(userId);
      return rooms.isNotEmpty;
    } catch (e) {
      debugPrint('사용자 참여 채팅방 확인 오류: $e');
      return false;
    }
  }
}