import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/features/chat/presentation/chat_room_create/chat_create_page.dart';
import 'package:with_run_app/features/map/presentation/view_models/map_provider.dart';

class CreateChatRoomDialogViewModel extends StateNotifier<bool> {
  final Ref _ref;
  final LatLng position;

  CreateChatRoomDialogViewModel(this._ref, this.position) : super(false);

  void onCancel() {
    _ref.read(mapProvider.notifier).removeTemporaryMarker();
  }

  void onConfirm(BuildContext context) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatCreatePage()),
    );
  }
}

final createChatRoomDialogViewModelProvider =
    StateNotifierProvider.family<CreateChatRoomDialogViewModel, bool, LatLng>((
      ref,
      position,
    ) {
      return CreateChatRoomDialogViewModel(ref, position);
    });
