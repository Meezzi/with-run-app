import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/widgets/chat_list_overlay.dart';
import 'package:with_run_app/ui/pages/map/widgets/chat_room_info_window.dart';
import 'package:with_run_app/ui/pages/map/widgets/create_chat_room_dialog.dart';

class MapViewModel extends StateNotifier<bool> {
  final Ref _ref;
  OverlayEntry? _infoWindowOverlay;
  OverlayEntry? _chatListOverlay;
  bool _isInitialized = false;

  MapViewModel(this._ref) : super(false);

  void initialize(BuildContext context) {
    if (!_isInitialized) {
      _isInitialized = true;
      // 위젯 트리 구축 후에 콜백 설정 지연
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ref.read(mapProvider.notifier).setOnChatRoomMarkerTapCallback((chatRoomId) {
          _showChatRoomInfoWindow(context, chatRoomId);
        });
        _ref.read(mapProvider.notifier).setOnTemporaryMarkerTapCallback((position) {
          debugPrint('임시 마커 탭됨: $position');
          // 임시 마커 클릭 시 다이얼로그 표시
          _showCreateChatRoomConfirmDialog(context, position);
        });
        
        // 초기화 시 디버그 정보 출력
        _ref.read(mapProvider.notifier).printDebugInfo();
      });
    }
  }

  void _showChatRoomInfoWindow(BuildContext context, String chatRoomId) {
    _closeOverlays();
    _infoWindowOverlay = OverlayEntry(
      builder: (context) => ChatRoomInfoWindow(
        chatRoomId: chatRoomId,
        onDismiss: () {
          _infoWindowOverlay?.remove();
          _infoWindowOverlay = null;
        },
      ),
    );
    if (context.mounted) {
      Overlay.of(context).insert(_infoWindowOverlay!);
    }
  }

  void _showCreateChatRoomConfirmDialog(BuildContext context, LatLng position) {
    _closeOverlays(); // 기존 오버레이 닫기
    debugPrint('다이얼로그 표시 시도: $position');
    
    // 다이얼로그 표시
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
    _chatListOverlay?.remove();
    _chatListOverlay = null;
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
    debugPrint('내 위치로 이동 요청');
    final locationState = _ref.read(locationProvider);
    if (locationState.currentPosition == null) {
      _showSnackBar(context, "위치 정보를 가져오는 중입니다...");
      await _ref.read(locationProvider.notifier).refreshLocation();
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
    
    try {
      await _ref.read(mapProvider.notifier).moveToCurrentLocation();
      if (!context.mounted) return;
      _showSnackBar(context, "현재 위치로 이동했습니다");
    } catch (e) {
      debugPrint("카메라 이동 실패: $e");
      if (!context.mounted) return;
      _showSnackBar(context, "위치로 이동하는데 실패했습니다", isError: true);
    }
  }

  Future<void> startChatRoomCreationMode(BuildContext context) async {
    debugPrint('채팅방 생성 모드 시작');
    if (FirebaseAuth.instance.currentUser == null) {
      _showSnackBar(context, '로그인이 필요합니다.', isError: true);
      debugPrint('로그인되지 않음');
      return;
    }
    
    final chatRoomVm = _ref.read(chatRoomViewModel.notifier);
    try {
      final hasCreatedRoom = await chatRoomVm.userHasCreatedRoom();
      debugPrint('이미 생성된 채팅방 여부: $hasCreatedRoom');
      
      if (!context.mounted) return;
      
      if (hasCreatedRoom) {
        _showSnackBar(context, '이미 생성한 채팅방이 있습니다. 한 번에 하나의 채팅방만 만들 수 있습니다.', isError: true);
        return;
      }
      
      final isInAnyRoom = await chatRoomVm.isUserInAnyRoom();
      debugPrint('다른 채팅방 참여 여부: $isInAnyRoom');
      
      if (!context.mounted) return;
      
      if (isInAnyRoom) {
        _showSnackBar(context, '이미 참여 중인 채팅방이 있습니다. 채팅방에서 나간 후 새로운 채팅방을 만들어주세요.', isError: true);
        return;
      }
      
      // 처리 지연 - 위젯 생명주기 밖에서 상태 변경
      Future.microtask(() {
        if (!context.mounted) return;
        
        final mapState = _ref.read(mapProvider);
        debugPrint('선택된 위치: ${mapState.selectedPosition}');
        
        // 이미 초록색 마커가 있는 경우(selectedPosition이 있는 경우)
        if (mapState.selectedPosition != null) {
          // 이미 마커가 있으면 바로 채팅방 생성 페이지로 이동
          debugPrint('선택된 위치가 있음. 채팅방 생성 페이지로 바로 이동');
          _navigateToChatCreatePage(context);
        } else {
          // 아직 위치를 선택하지 않은 경우, 위치 선택 다이얼로그 표시
          debugPrint('선택된 위치가 없음. 위치 선택 안내 표시');
          // 채팅방 생성 모드 활성화
          _ref.read(mapProvider.notifier).setCreatingChatRoom(true);
          // 위치 선택 안내 표시
          _showLocationSelectionDialog(context);
        }
      });
    } catch (e) {
      debugPrint('채팅방 생성 모드 시작 오류: $e');
      if (context.mounted) {
        _showSnackBar(context, '채팅방 생성 모드 시작 실패: $e', isError: true);
      }
    }
  }

  void _navigateToChatCreatePage(BuildContext context) {
    // 채팅방 생성 페이지로 이동하기 전 로그 출력
    debugPrint('=== 채팅방 생성 페이지로 이동 ===');
    debugPrint('생성 모드: ${_ref.read(mapProvider).isCreatingChatRoom}');
    debugPrint('선택된 위치: ${_ref.read(mapProvider).selectedPosition}');
    
    // Navigate는 위젯 생명주기가 끝난 후에 실행하는 것이 안전
    Future.microtask(() {
      if (context.mounted) {
        // 생성 모드 활성화 확인
        _ref.read(mapProvider.notifier).setCreatingChatRoom(true);
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatCreatePage()),
        ).then((_) {
          // 페이지에서 돌아온 후 디버그 정보 출력
          debugPrint('채팅방 생성 페이지에서 돌아옴');
          _ref.read(mapProvider.notifier).printDebugInfo();
        });
      }
    });
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

  void showChatListOverlay(BuildContext context) {
    _closeOverlays();
    
    // 오버레이 표시는 위젯 생명주기 후에 지연 처리
    Future.microtask(() {
      if (context.mounted) {
        _chatListOverlay = OverlayEntry(
          builder: (context) => ChatListOverlay(
            onDismiss: () {
              _chatListOverlay?.remove();
              _chatListOverlay = null;
            },
          ),
        );
        
        final overlay = Overlay.of(context);
        overlay.insert(_chatListOverlay!);
        
        // 추가 지연으로 안정성 확보
        Future.microtask(() {
          if (_chatListOverlay != null) {
            _chatListOverlay!.markNeedsBuild();
          }
        });
      }
    });
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