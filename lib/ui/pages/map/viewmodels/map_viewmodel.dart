import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';
import 'package:with_run_app/ui/pages/chat_information/chat_information_page.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/widgets/create_chat_room_dialog.dart';

class MapViewModel extends StateNotifier<bool> {
  final Ref _ref;
  OverlayEntry? _infoWindowOverlay;
  bool _isInitialized = false;

  MapViewModel(this._ref) : super(false);

  void initialize(BuildContext context) {
    if (!_isInitialized) {
      _isInitialized = true;
      _ref.read(mapProvider.notifier).setOnChatRoomMarkerTapCallback((chatRoomId) {
        _showChatRoomInfo(context, chatRoomId);
      });
      _ref.read(mapProvider.notifier).setOnTemporaryMarkerTapCallback((position) {
        _showCreateChatRoomConfirmDialog(context, position);
      });
    }
  }

  Future<void> _showChatRoomInfo(BuildContext context, String chatRoomId) async {
    _closeOverlays();
    
    try {
      // 채팅방 정보 로드
      final result = await _ref.read(chatRoomViewModel.notifier).enterChatRoom(chatRoomId);
      
      // 채팅방 정보 페이지로 이동
      if (context.mounted && result != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatInformationPage(),
          ),
        );
      } else if (context.mounted) {
        _showSnackBar(context, '채팅방 정보를 불러올 수 없습니다.', isError: true);
      }
    } catch (e) {
      debugPrint('채팅방 정보 로드 오류: $e');
      if (context.mounted) {
        _showSnackBar(context, '채팅방 정보를 불러올 수 없습니다.', isError: true);
      }
    }
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

  void _closeOverlays() {
    _infoWindowOverlay?.remove();
    _infoWindowOverlay = null;
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    
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

  Future<void> moveToCurrentLocation(BuildContext context) async {
    final locationState = _ref.read(locationProvider);
    
    // 위치 정보가 없으면 새로고침
    if (locationState.currentPosition == null) {
      _showSnackBar(context, "위치 정보를 가져오는 중입니다...");
      await _ref.read(locationProvider.notifier).refreshLocation();
      
      // 위치 정보를 다시 확인
      final updatedLocationState = _ref.read(locationProvider);
      if (!context.mounted) return;
      
      if (updatedLocationState.currentPosition == null) {
        if (updatedLocationState.error != null) {
          _showSnackBar(context, updatedLocationState.error!, isError: true);
        } else {
          _showSnackBar(context, "위치 정보를 가져올 수 없습니다.", isError: true);
        }
        return;
      }
    }
    
    // 실제 지도 이동 로직
    try {
      await _ref.read(mapProvider.notifier).moveToCurrentLocation();
      
      if (context.mounted) {
        _showSnackBar(context, "현재 위치로 이동했습니다");
      }
    } catch (e) {
      debugPrint("카메라 이동 실패: $e");
      if (context.mounted) {
        _showSnackBar(context, "위치로 이동하는데 실패했습니다", isError: true);
      }
    }
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
      _ref.read(mapProvider.notifier).setCreatingChatRoom(true);
      _showLocationSelectionDialog(context);
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

  Future<void> showChatListOverlay(BuildContext context) async {
    // 채팅 목록 오버레이 표시 기능은 나중에 구현
    _showSnackBar(context, "채팅 목록 기능은 준비 중입니다.");
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