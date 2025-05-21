import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/chat/data/chat_room.dart';
import 'package:with_run_app/features/map/presentation/theme_provider.dart';
import 'package:with_run_app/features/map/presentation/view_models/chat_room_info_viewmodel.dart';

class ChatRoomInfoWindow extends ConsumerWidget {
  final ChatRoom chatRoom;
  final VoidCallback onDismiss;

  const ChatRoomInfoWindow({
    super.key,
    required this.chatRoom,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(appThemeProvider);
    final addressState = ref.watch(chatRoomInfoViewModelProvider(chatRoom));
    final screenSize = MediaQuery.of(context).size;
    const infoWindowWidth = 350.0;
    const infoWindowHeight = 250.0;

    final left = (screenSize.width - infoWindowWidth) / 2;
    final top = (screenSize.height - infoWindowHeight) / 2 - 150;

    return addressState.when(
      data: (address) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              onDismiss();
              ref.read(chatRoomInfoViewModelProvider(chatRoom).notifier).joinChatRoom(context);
            },
            child: Container(
              width: infoWindowWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeState.isDarkMode
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
                            colors: themeState.isDarkMode
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
                            color: themeState.isDarkMode ? Colors.white : Colors.black87,
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
                        color: themeState.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeState.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: themeState.isDarkMode ? Colors.blue[300] : Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeState.isDarkMode ? Colors.grey[300] : Colors.grey[700],
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
                      onPressed: () {
                        onDismiss();
                        ref.read(chatRoomInfoViewModelProvider(chatRoom).notifier).joinChatRoom(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeState.isDarkMode
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
      ),
      loading: () => Positioned(
        left: left,
        top: top,
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Positioned(
        left: left,
        top: top,
        child: Center(child: Text('오류: $error')),
      ),
    );
  }
}