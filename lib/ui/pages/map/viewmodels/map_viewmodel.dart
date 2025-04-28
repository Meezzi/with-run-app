import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/services/chat_service.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/widgets/chat_list_overlay.dart';
import 'package:with_run_app/ui/pages/map/widgets/chat_room_info_window.dart';
import 'package:with_run_app/ui/pages/map/widgets/create_chat_room_dialog.dart';

class MapViewModel extends StateNotifier<bool> {
  final Ref _ref;
  final ChatService _chatService = ChatService();
  OverlayEntry? _chatListOverlay;
  OverlayEntry? _infoWindowOverlay;
  bool _isInitialized = false;

  MapViewModel(this._ref) : super(false);

  void initialize(BuildContext context) {
    if (!_isInitialized) {
      _isInitialized = true;
      _ref.read(mapProvider.notifier).setOnChatRoomMarkerTapCallback((chatRoom) {
        showChatRoomInfoWindow(context, chatRoom);
      });
      _ref.read(mapProvider.notifier).setOnTemporaryMarkerTapCallback((position) {
        _showCreateChatRoomConfirmDialog(context, position);
      });
    }
  }

  void showChatRoomInfoWindow(BuildContext context, ChatRoom chatRoom) {
    _closeOverlays();
    _infoWindowOverlay = OverlayEntry(
      builder: (context) => ChatRoomInfoWindow(
        chatRoom: chatRoom,
        onDismiss: () {
          _infoWindowOverlay?.remove();
          _infoWindowOverlay = null;
        },
      ),
    );
    Overlay.of(context).insert(_infoWindowOverlay!);
  }

  void _showCreateChatRoomConfirmDialog(BuildContext context, LatLng position) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Transform.translate(
        offset: const Offset(0, -160),
        child: Align(
          alignment: Alignment.topCenter,
          child: CreateChatRoomDialog(
            position: position,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void showChatListOverlay(BuildContext context) {
    _closeOverlays();
    _chatListOverlay = OverlayEntry(
      builder: (context) => ChatListOverlay(
        onDismiss: () {
          _chatListOverlay?.remove();
          _chatListOverlay = null;
        },
      ),
    );
    Overlay.of(context).insert(_chatListOverlay!);
  }

  void _closeOverlays() {
    _chatListOverlay?.remove();
    _infoWindowOverlay?.remove();
    _chatListOverlay = null;
    _infoWindowOverlay = null;
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
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

  Future<void> startChatRoomCreationMode(BuildContext context) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showSnackBar(context, '로그인이 필요합니다.', isError: true);
      return;
    }
    final mapState = _ref.read(mapProvider);
    if (mapState.selectedPosition != null) {
      _navigateToChatCreatePage(context);
    } else {
      final hasCreatedRoom = await _checkUserHasCreatedRoom();
      if (!context.mounted) return; // 비동기 후 BuildContext 사용 시 mounted 확인
      if (hasCreatedRoom) {
        _showSnackBar(
          context,
          '이미 개설한 채팅방이 있습니다. 한 사용자당 하나의 채팅방만 개설할 수 있습니다.',
          isError: true,
        );
      } else {
        _ref.read(mapProvider.notifier).setCreatingChatRoom(true);
        _showLocationSelectionDialog(context);
      }
    }
  }

  Future<bool> _checkUserHasCreatedRoom() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;
    try {
      return await _chatService.hasUserCreatedRoom(userId);
    } catch (e) {
      debugPrint('사용자 채팅방 확인 오류: $e');
      return false;
    }
  }

  void _navigateToChatCreatePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatCreatePage()),
    );
  }

  void _showLocationSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, size: 40, color: Colors.blue),
              const SizedBox(height: 8),
              const Text(
                '지도에서 채팅방을 개설할 위치를 선택해주세요',
                style: TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> moveToCurrentLocation(BuildContext context) async {
    final locationState = _ref.read(locationProvider);
    if (locationState.currentPosition != null) {
      _ref.read(mapProvider.notifier).moveToCurrentLocation();
    } else if (locationState.error != null) {
      _showSnackBar(context, locationState.error!, isError: true);
    } else {
      _showSnackBar(context, "위치 정보를 가져오는 중입니다...");
      await _ref.read(locationProvider.notifier).refreshLocation();
    }
  }

  @override
  void dispose() {
    _closeOverlays();
    super.dispose();
  }
}

final mapViewModelProvider = StateNotifierProvider<MapViewModel, bool>((ref) {
  return MapViewModel(ref);
});