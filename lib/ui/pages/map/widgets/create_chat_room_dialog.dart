import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:with_run_app/ui/pages/chat/chat_room_page.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:provider/provider.dart' as provider;

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
  final roomNameController = TextEditingController();
  final descriptionController = TextEditingController();
  String? errorMessage;
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    roomNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: themeProvider.isDarkMode
                ? [Colors.grey[800]!, Colors.grey[850]!]
                : [Colors.white, Colors.grey[100]!],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(51),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(themeProvider),
            const SizedBox(height: 16),
            _buildLocationInfo(themeProvider),
            const SizedBox(height: 24),
            _buildRoomNameField(themeProvider),
            const SizedBox(height: 16),
            _buildDescriptionField(themeProvider),
            const SizedBox(height: 32),
            _buildActionButtons(themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeProvider themeProvider) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: themeProvider.isDarkMode
                  ? Colors.greenAccent
                  : const Color(0xFF00E676),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '새 채팅방 만들기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: themeProvider.isDarkMode
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: Icon(
              Icons.close,
              color: themeProvider.isDarkMode
                  ? Colors.grey[300]
                  : Colors.grey[700],
              size: 20,
            ),
            onPressed: () {
              ref.read(mapProvider.notifier).removeTemporaryMarker();
              widget.onDismiss();
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(AppThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode
            ? Colors.grey[700]
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 5,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: themeProvider.isDarkMode
                ? Colors.blue[300]
                : const Color(0xFF2196F3),
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선택한 위치',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[200]
                        : const Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '위도: ${widget.position.latitude.toStringAsFixed(6)}\n경도: ${widget.position.longitude.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[300]
                        : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomNameField(AppThemeProvider themeProvider) {
    return TextField(
      controller: roomNameController,
      decoration: InputDecoration(
        labelText: '채팅방 이름',
        hintText: '채팅방 이름을 입력하세요',
        prefixIcon: Icon(
          Icons.chat_bubble_outline,
          color: themeProvider.isDarkMode
              ? Colors.blue[300]
              : const Color(0xFF2196F3),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: themeProvider.isDarkMode
                ? Colors.grey[600]!
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: themeProvider.isDarkMode
                ? Colors.greenAccent
                : const Color(0xFF00E676),
            width: 2,
          ),
        ),
        errorText: errorMessage,
        filled: true,
        fillColor: themeProvider.isDarkMode
            ? Colors.grey[700]
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: themeProvider.isDarkMode
              ? Colors.grey[300]
              : const Color(0xFF757575),
        ),
        hintStyle: TextStyle(
          color: themeProvider.isDarkMode
              ? Colors.grey[500]
              : Colors.grey[400],
          fontSize: 14,
        ),
      ),
      style: TextStyle(
        color: themeProvider.isDarkMode
            ? Colors.white
            : Colors.black87,
        fontSize: 15,
      ),
      autofocus: true,
      onChanged: (value) {
        if (errorMessage != null && value.trim().isNotEmpty) {
          setState(() => errorMessage = null);
        }
      },
    );
  }

  Widget _buildDescriptionField(AppThemeProvider themeProvider) {
    return TextField(
      controller: descriptionController,
      decoration: InputDecoration(
        labelText: '설명 (선택사항)',
        hintText: '채팅방 설명을 입력하세요',
        prefixIcon: Icon(
          Icons.description_outlined,
          color: themeProvider.isDarkMode
              ? Colors.blue[300]
              : const Color(0xFF2196F3),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: themeProvider.isDarkMode
                ? Colors.grey[600]!
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: themeProvider.isDarkMode
                ? Colors.greenAccent
                : const Color(0xFF00E676),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: themeProvider.isDarkMode
            ? Colors.grey[700]
            : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: TextStyle(
          color: themeProvider.isDarkMode
              ? Colors.grey[300]
              : const Color(0xFF757575),
        ),
        hintStyle: TextStyle(
          color: themeProvider.isDarkMode
              ? Colors.grey[500]
              : Colors.grey[400],
          fontSize: 14,
        ),
      ),
      style: TextStyle(
        color: themeProvider.isDarkMode
            ? Colors.white
            : Colors.black87,
        fontSize: 15,
      ),
      maxLines: 2,
      minLines: 2,
    );
  }

  Widget _buildActionButtons(AppThemeProvider themeProvider) {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              ref.read(mapProvider.notifier).removeTemporaryMarker();
              widget.onDismiss();
            },
            style: TextButton.styleFrom(
              foregroundColor: themeProvider.isDarkMode
                  ? Colors.grey[300]
                  : const Color(0xFF757575),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[600]!
                      : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              '취소',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _createChatRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.isDarkMode
                  ? Colors.greenAccent
                  : const Color(0xFF00E676),
              foregroundColor: themeProvider.isDarkMode
                  ? Colors.black87
                  : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              '만들기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createChatRoom() async {
    final roomName = roomNameController.text.trim();
    if (roomName.isEmpty) {
      setState(() => errorMessage = '채팅방 이름을 입력해주세요.');
      return;
    }

    // 채팅방 생성 제한 확인
    final hasCreatedRoom = await _checkUserHasCreatedRoom();
    if (!mounted) return; // mounted 체크

    if (hasCreatedRoom) {
      widget.onShowSnackBar(
        '이미 개설한 채팅방이 있습니다. 한 사용자당 하나의 채팅방만 개설할 수 있습니다.',
        isError: true,
      );
      return;
    }

    widget.onDismiss();

    try {
      final chatRoom = await _chatService.createChatRoom(
        latitude: widget.position.latitude,
        longitude: widget.position.longitude,
        title: roomName,
        description: descriptionController.text.trim().isNotEmpty
            ? descriptionController.text.trim()
            : null,
      );
      
      if (!mounted) return; // mounted 체크 추가

      ref.read(mapProvider.notifier).removeTemporaryMarker();
      
      if (chatRoom != null) {
        widget.onShowSnackBar('채팅방이 생성되었습니다!');
        
        // 지도 새로고침 - public 메서드로 수정
        await ref.read(mapProvider.notifier).loadNearbyChatRooms();
        
        // mounted 체크 추가
        if (!mounted) return;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoom: chatRoom,
              onRoomDeleted: () => ref.read(mapProvider.notifier).refreshMapAfterRoomDeletion(chatRoom.id),
            ),
          ),
        );
      } else {
        if (mounted) {  // mounted 체크 추가
          widget.onShowSnackBar('채팅방 생성 실패', isError: true);
        }
      }
    } catch (e) {
      debugPrint('채팅방 생성 오류: $e');
      if (mounted) {  // mounted 체크 추가
        widget.onShowSnackBar('오류 발생: $e', isError: true);
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
}