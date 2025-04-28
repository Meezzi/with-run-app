import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:provider/provider.dart' as provider;

class ChatListOverlay extends ConsumerWidget {
  final VoidCallback onDismiss;

  const ChatListOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

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
                  colors: themeProvider.isDarkMode
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
              // child: chatListState.when(
              //   data: (rooms) => Column(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       _buildHeader(themeProvider),
              //       if (rooms.isEmpty)
              //         _buildEmptyView(themeProvider)
              //       else
              //         _buildRoomsList(context, themeProvider, rooms, ref),
              //     ],
              //   ),
              //   loading: () => const Center(child: CircularProgressIndicator()),
              //   error: (error, stack) => Center(child: Text('오류: $error')),
              // ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: themeProvider.isDarkMode
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
    WidgetRef ref,
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
          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
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
              // ref.read(chatListViewModelProvider.notifier).joinChatRoom(context, room);
            },
            dense: true,
          );
        },
      ),
    );
  }
}