import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class CreateChatRoomButtonViewModel extends StateNotifier<bool> {
  CreateChatRoomButtonViewModel(this._showSnackBar) : super(false);

  final void Function(String message, {bool isError}) _showSnackBar;

  Future<void> onNewChatRoomButtonTap(BuildContext context, void Function() onCreateButtonTap) async {
    state = true; // 로딩 상태 시작
    try {
      // 채팅방 생성 로직 (예시)
      await Future.delayed(const Duration(seconds: 1)); // 비동기 작업 시뮬레이션
      _showSnackBar('채팅방이 생성되었습니다!', isError: false);
      onCreateButtonTap(); // 콜백 실행
    } catch (e) {
      // debugPrint를 전역 함수로 직접 호출
      debugPrint('사용자 참여 채팅방 확인 오류: $e');
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