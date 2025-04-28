import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/ui/pages/map/viewmodels/create_chat_room_dialog_viewmodel.dart';

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
    final viewModel = ref.read(createChatRoomDialogViewModelProvider(position).notifier);

    return CupertinoAlertDialog(
      title: const Text('새 채팅방 위치'),
      content: const Padding(
        padding: EdgeInsets.only(top: 4),
        child: Text('이 위치에 채팅방을 생성하시겠습니까?'),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            viewModel.onCancel();
            onDismiss();
          },
          child: const Text('아니요'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () {
            onDismiss();
            viewModel.onConfirm(context);
          },
          child: const Text('예'),
        ),
      ],
    );
  }
}