import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:provider/provider.dart' as provider;

class CreateChatRoomButton extends ConsumerWidget {
  final Function(String, {bool isError}) onShowSnackBar;
  final VoidCallback onCreateButtonTap;

  const CreateChatRoomButton({
    super.key,
    required this.onShowSnackBar,
    required this.onCreateButtonTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);

    return Center(
      child: Container(
        width: 220,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeProvider.isDarkMode
                ? [Colors.blue[400]!, Colors.green[400]!]
                : [const Color(0xFF2196F3), const Color(0xFF00E676)],
          ),
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _onNewChatRoomButtonTap(ref),
            splashColor: const Color(0x33FFFFFF),
            highlightColor: const Color(0x22FFFFFF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: themeProvider.isDarkMode
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : Colors.white,
                  radius: 14,
                  child: Icon(
                    Icons.add_comment_outlined,
                    color: themeProvider.isDarkMode
                        ? Colors.blue[600]
                        : const Color(0xFF2196F3),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '새 채팅방 만들기',
                  style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onNewChatRoomButtonTap(WidgetRef ref) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      onShowSnackBar('로그인이 필요합니다.', isError: true);
      return;
    }

    final chatService = ChatService();

    // 채팅방 생성 제한 확인
    final hasCreatedRoom = await chatService.hasUserCreatedRoom(userId);
    if (hasCreatedRoom) {
      onShowSnackBar(
        '이미 개설한 채팅방이 있습니다. 한 사용자당 하나의 채팅방만 개설할 수 있습니다.',
        isError: true,
      );
      return;
    }

    // 채팅방 참여 제한 확인
    final hasJoinedRoom = await _checkUserHasJoinedRoom(chatService, userId);
    if (hasJoinedRoom) {
      onShowSnackBar(
        '이미 참여 중인 채팅방이 있습니다. 한 번에 하나의 채팅방에만 참여할 수 있습니다.',
        isError: true,
      );
      return;
    }

    final mapState = ref.read(mapProvider);
    if (mapState.selectedPosition != null) {
      onCreateButtonTap();
    } else {
      onShowSnackBar('생성할 위치를 지정해주세요!');
      ref.read(mapProvider.notifier).setCreatingChatRoom(true);
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

