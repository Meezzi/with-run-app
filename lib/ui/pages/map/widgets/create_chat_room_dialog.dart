import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';

class CreateChatRoomDialog extends ConsumerWidget {
  final LatLng position;
  final VoidCallback onDismiss;

  const CreateChatRoomDialog({
    super.key,
    required this.position,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoAlertDialog(
      title: const Text('새 채팅방 위치'),
      content: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('이 위치에 채팅방을 생성하시겠습니까?'),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            // 취소 시 임시 마커 제거 및 채팅방 생성 모드 비활성화
            ref.read(mapProvider.notifier).removeTemporaryMarker();
            ref.read(mapProvider.notifier).setCreatingChatRoom(false);
            onDismiss();
          },
          child: const Text('아니요'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            onDismiss();
            _navigateToChatCreate(context);
          },
          child: const Text('예'),
        ),
      ],
    );
  }

  void _navigateToChatCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatCreatePage(),
      ),
    );
  }
}