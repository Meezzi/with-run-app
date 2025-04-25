import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/services/chat_service.dart';
import 'package:with_run_app/ui/pages/chat/chat_room_page.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as provider;

class ChatListOverlay extends ConsumerWidget {
  final Function(String, {bool isError}) onShowSnackBar;
  final VoidCallback onDismiss;

  const ChatListOverlay({
    super.key,
    required this.onShowSnackBar,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final chatService = ChatService();

    return FutureBuilder<List<ChatRoom>>(
      future: userId != null ? chatService.getJoinedChatRooms(userId) : Future.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms = snapshot.data ?? [];
        
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: onDismiss,
                  child: Container(color: const Color(0x80000000)),
                ),
              ),
              Positioned(
                top: appBarHeight,
                right: 16,
                width: 250,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          themeProvider.isDarkMode
                              ? [Colors.grey[800]!, Colors.grey[850]!]
                              : [Colors.white, Colors.grey[100]!],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(themeProvider),
                      if (rooms.isEmpty)
                        _buildEmptyView(themeProvider)
                      else
                        _buildRoomsList(context, themeProvider, rooms, ref),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              themeProvider.isDarkMode
                  ? [Colors.blue[400]!, Colors.green[400]!]
                  : [const Color(0xFF2196F3), const Color(0xFF00E676)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.forum_rounded,
                color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '내 채팅방',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 20,
              color: themeProvider.isDarkMode ? Colors.white : Colors.white,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(AppThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: themeProvider.isDarkMode
                ? Colors.grey[500]
                : const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 16),
          Text(
            '참여 중인 채팅방이 없습니다.',
            style: TextStyle(
              color: themeProvider.isDarkMode
                  ? Colors.grey[300]
                  : const Color(0xFF757575),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRoomsList(
    BuildContext context, 
    AppThemeProvider themeProvider, 
    List<ChatRoom> rooms,
    WidgetRef ref
  ) {
    return Flexible(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: rooms.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: themeProvider.isDarkMode
              ? Colors.grey[700]
              : Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final room = rooms[index];
          return ListTile(
            leading: Container(
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
                 // chat_list_overlay.dart (계속)
                  Icons.chat_bubble_outline_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              room.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : const Color(0xFF212121),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '참여자: ${room.participants?.length ?? 0}명',
              style: TextStyle(
                fontSize: 12,
                color: themeProvider.isDarkMode
                    ? Colors.grey[400]
                    : const Color(0xFF757575),
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: themeProvider.isDarkMode
                  ? Colors.grey[400]
                  : const Color(0xFF9E9E9E),
            ),
            onTap: () {
              onDismiss();
              _joinChatRoom(context, room, ref);
            },
            dense: true,
          );
        },
      ),
    );
  }

  Future<void> _joinChatRoom(BuildContext context, ChatRoom chatRoom, WidgetRef ref) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      onShowSnackBar('로그인이 필요합니다.', isError: true);
      return;
    }

    try {
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
  }
}


