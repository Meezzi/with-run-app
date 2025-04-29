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
    // 다이얼로그 표시 전에 선택된 위치 확인 및 갱신
    final mapState = ref.read(mapProvider);
    if (mapState.selectedPosition == null) {
      debugPrint('다이얼로그 표시 전 선택된 위치 없음, 자동 설정: $position');
      // 이 시점에서 임시 마커 추가 및 선택 위치 설정
      ref.read(mapProvider.notifier).addTemporaryMarker(position);
    } else {
      debugPrint('다이얼로그 표시 - 선택된 위치 확인: ${mapState.selectedPosition}');
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('새 채팅방 위치', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('이 위치에 채팅방을 생성하시겠습니까?'),
          const SizedBox(height: 12),
          // 선택한 위치 표시
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '위치: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // 취소 시 임시 마커 제거 및 채팅방 생성 모드 비활성화
            debugPrint('채팅방 생성 취소, 상태 초기화');
            ref.read(mapProvider.notifier).removeTemporaryMarker();
            ref.read(mapProvider.notifier).setCreatingChatRoom(false);
            onDismiss();
          },
          child: const Text('아니요'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            // 현재 선택된 위치 확인
            final currentState = ref.read(mapProvider);
            if (currentState.selectedPosition == null) {
              debugPrint('경고: 채팅방 생성 확인 시 선택된 위치가 없음');
              // 없는 경우 다시 설정
              ref.read(mapProvider.notifier).addTemporaryMarker(position);
            }
            
            onDismiss();
            debugPrint('채팅방 생성 확인, 생성 페이지로 이동');
            _navigateToChatCreate(context, ref);
          },
          child: const Text('예'),
        ),
      ],
    );
  }

  void _navigateToChatCreate(BuildContext context, WidgetRef ref) {
    // 채팅방 생성 페이지로 이동하기 전 현재 상태 확인
    final mapState = ref.read(mapProvider);
    debugPrint('채팅방 생성 페이지로 이동 - 현재 상태: 생성 모드=${mapState.isCreatingChatRoom}, 선택 위치=${mapState.selectedPosition}');
    
    // 채팅방 생성 모드로 명시적 설정
    if (!mapState.isCreatingChatRoom) {
      debugPrint('채팅방 생성 모드 활성화');
      ref.read(mapProvider.notifier).setCreatingChatRoom(true);
    }
    
    // 선택된 위치가 없으면 수동으로 설정
    if (mapState.selectedPosition == null) {
      debugPrint('선택된 위치 수동 설정: $position');
      ref.read(mapProvider.notifier).addTemporaryMarker(position);
    }
    
    // 다시 한번 상태 확인
    final updatedState = ref.read(mapProvider);
    debugPrint('최종 이동 전 상태: 생성 모드=${updatedState.isCreatingChatRoom}, 선택 위치=${updatedState.selectedPosition}');
    
    // 채팅방 생성 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatCreatePage(),
      ),
    ).then((_) {
      // 페이지에서 돌아온 후 디버그 정보 출력
      debugPrint('채팅방 생성 페이지에서 돌아옴');
      ref.read(mapProvider.notifier).printDebugInfo();
    });
  }
}