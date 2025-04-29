import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';

class CreateChatRoomButtonViewModel extends StateNotifier<bool> {
  CreateChatRoomButtonViewModel(this._showSnackBar) : super(false);

  final void Function(String message, {bool isError}) _showSnackBar;

  Future<void> onNewChatRoomButtonTap(BuildContext context, void Function() onCreateButtonTap) async {
    state = true; // 로딩 상태 시작
    try {
      // 먼저 마커 설정 및 생성 모드 설정을 위한 콜백 실행
      onCreateButtonTap();
      
      // 맵 상태가 초기화되고 임시 마커가 생성된 후에 채팅방 생성 페이지로 이동
      // 약간의 딜레이 후 채팅방 생성 페이지로 이동
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatCreatePage()),
        );
      }
    } catch (e) {
      debugPrint('채팅방 생성 버튼 처리 오류: $e');
      _showSnackBar('채팅방 생성에 실패했습니다.', isError: true);
    } finally {
      state = false; // 로딩 상태 종료
    }
  }
}

// Provider 정의
final createChatRoomButtonViewModelProvider = StateNotifierProvider.family<
    CreateChatRoomButtonViewModel, bool, void Function(String, {bool isError})>(
  (ref, showSnackBar) => CreateChatRoomButtonViewModel(showSnackBar),
);