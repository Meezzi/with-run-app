import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/map/presentation/theme_provider.dart';
import 'package:with_run_app/features/map/presentation/view_models/create_chat_room_button_viewmodel.dart';

class CreateChatRoomButton extends ConsumerStatefulWidget {
  final VoidCallback onCreateButtonTap;

  const CreateChatRoomButton({
    super.key,
    required this.onCreateButtonTap,
  });

  @override
  ConsumerState<CreateChatRoomButton> createState() => _CreateChatRoomButtonState();
}

class _CreateChatRoomButtonState extends ConsumerState<CreateChatRoomButton> {
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
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
  Widget build(BuildContext context) {
    final themeState = ref.watch(appThemeProvider);

    return Center(
      child: Container(
        width: 220,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeState.isDarkMode
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
            onTap: () => ref
                .read(createChatRoomButtonViewModelProvider(_showSnackBar).notifier)
                .onNewChatRoomButtonTap(context, widget.onCreateButtonTap),
            splashColor: const Color(0x33FFFFFF),
            highlightColor: const Color(0x22FFFFFF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: themeState.isDarkMode
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : Colors.white,
                  radius: 14,
                  child: Icon(
                    Icons.add_comment_outlined,
                    color: themeState.isDarkMode
                        ? Colors.blue[600]
                        : const Color(0xFF2196F3),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '새 채팅방 만들기',
                  style: TextStyle(
                    color: themeState.isDarkMode ? Colors.white : Colors.white,
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
}