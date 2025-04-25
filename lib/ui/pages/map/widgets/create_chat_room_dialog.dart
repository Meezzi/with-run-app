import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';

class CreateChatRoomDialog extends ConsumerStatefulWidget {
  final LatLng position;
  final Function(String, {bool isError}) onShowSnackBar;
  final VoidCallback onDismiss;

  const CreateChatRoomDialog({
    super.key,
    required this.position,
    required this.onShowSnackBar,
    required this.onDismiss,
  });

  @override
  ConsumerState<CreateChatRoomDialog> createState() => _CreateChatRoomDialogState();
}

class _CreateChatRoomDialogState extends ConsumerState<CreateChatRoomDialog> {
  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('새 채팅방 위치'),
      content: const Text('이 위치에 채팅방을 생성하시겠습니까?'),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            ref.read(mapProvider.notifier).removeTemporaryMarker();
            widget.onDismiss();
          },
          child: const Text('아니요'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _navigateToChatCreatePage,
          child: const Text('예'),
        ),
      ],
    );
  }

  void _navigateToChatCreatePage() {
    widget.onDismiss();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatCreatePage(),
      ),
    );
  }
}