import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:with_run_app/ui/pages/chatting_page/chatting_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart'; // 맵 프로바이더 추가

class ChatRoomInfoWindow extends ConsumerStatefulWidget {
  final String chatRoomId;
  final VoidCallback onDismiss;

  const ChatRoomInfoWindow({
    super.key,
    required this.chatRoomId,
    required this.onDismiss,
  });

  @override
  ConsumerState<ChatRoomInfoWindow> createState() => _ChatRoomInfoWindowState();
}

class _ChatRoomInfoWindowState extends ConsumerState<ChatRoomInfoWindow> {
  String address = '주소 불러오는 중...';
  bool isLoading = true;
  ChatRoomModel? chatRoom;
  bool isInRoom = false;
  bool isCreator = false;
  bool isJoiningRoom = false; // 채팅방 참여 중인지 여부
  bool isDeleting = false; // 채팅방 삭제 중인지 여부

  @override
  void initState() {
    super.initState();
    _loadChatRoom();
  }

  Future<void> _loadChatRoom() async {
    try {
      // 채팅방 정보만 로드 (참여는 하지 않음)
      final result = await ref.read(chatRoomViewModel.notifier).getChatRoomInfo(widget.chatRoomId);
      
      if (result != null) {
        if (!mounted) return;
        
        setState(() {
          chatRoom = result;
        });
        
        // 현재 사용자가 방장인지 확인
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null && result.creator?.uid == currentUserId) {
          setState(() {
            isCreator = true;
            // 방장은 자동으로 참가자이기도 함
            isInRoom = true;
          });
        } else {
          // 사용자가 이미 이 채팅방에 참여 중인지 확인
          await _checkIfUserInThisRoom();
        }
        
        _loadAddress(result);
      }
    } catch (e) {
      debugPrint('채팅방 정보 로드 오류: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          address = '채팅방 정보를 불러올 수 없습니다';
        });
      }
    }
  }
  
  // 현재 사용자가 이 특정 채팅방에 참여 중인지 확인
  Future<void> _checkIfUserInThisRoom() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    try {
      final participantDoc = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('participants')
          .doc(currentUserId)
          .get();
      
      if (!mounted) return;
      
      setState(() {
        isInRoom = participantDoc.exists;
      });
    } catch (e) {
      debugPrint('참여 확인 오류: $e');
    }
  }

  Future<void> _loadAddress(ChatRoomModel room) async {
    if (!mounted) return;
    
    try {
      setState(() {
        isLoading = true;
      });
      
      final location = room.location;
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude, 
        location.longitude
      );
      
      if (!mounted) return;
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String addressText = '${place.street ?? ''}, ${place.thoroughfare ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
        
        setState(() {
          address = addressText.isNotEmpty
              ? addressText
              : '${location.latitude}, ${location.longitude}';
          isLoading = false;
        });
      } else {
        setState(() {
          address = '${location.latitude}, ${location.longitude}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        address = '주소를 불러올 수 없습니다';
        isLoading = false;
      });
      debugPrint('주소 로드 오류: $e');
    }
  }
  
  // 채팅방 입장 처리
  Future<void> _enterChatRoom() async {
    // 이미 처리 중이면 중복 실행 방지
    if (isJoiningRoom) return;
    
    try {
      setState(() {
        isJoiningRoom = true;
      });
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('로그인이 필요합니다.', isError: true);
        return;
      }
      
      // 사용자가 아직 참여하지 않은 경우 참가자로 추가
      if (!isInRoom) {
        // 참가자 정보가 있는지 확인하고 추가
        try {
          // 사용자 정보 가져오기
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (!mounted) return;
          
          final userData = userDoc.exists 
              ? userDoc.data() as Map<String, dynamic> 
              : {
                  'nickname': user.displayName ?? '사용자',
                  'profileImageUrl': user.photoURL ?? '',
                };
          
          // 참가자로 추가
          await FirebaseFirestore.instance
              .collection('chatRooms')
              .doc(widget.chatRoomId)
              .collection('participants')
              .doc(user.uid)
              .set({
                'nickname': userData['nickname'] ?? '사용자',
                'profileImageUrl': userData['profileImageUrl'] ?? '',
              });
              
          debugPrint('참가자로 추가됨: ${user.uid}');
          
          // 채팅방 모델에도 참가자 업데이트
          final chatRoomVm = ref.read(chatRoomViewModel.notifier);
          await chatRoomVm.enterChatRoom(widget.chatRoomId);
        } catch (e) {
          debugPrint('참가자 추가 오류: $e');
          if (!mounted) return;
          _showSnackBar('참가자 추가 실패: $e', isError: true);
          return;
        }
      }
      
      if (!mounted) return;
      
      // 인포 윈도우 닫기
      widget.onDismiss();
      
      // 채팅방으로 이동
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChattingPage(
              chatRoomId: widget.chatRoomId,
              myUserId: user.uid,
              roomName: chatRoom?.title ?? '채팅방',
              location: address,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('채팅방 입장 오류: $e');
      if (!mounted) return;
      _showSnackBar('채팅방 입장에 실패했습니다: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isJoiningRoom = false;
        });
      }
    }
  }
  
  // 채팅방 삭제 처리 (방장인 경우만)
  Future<void> _deleteChatRoom() async {
    if (!isCreator || isDeleting) return;
    
    try {
      setState(() {
        isDeleting = true;
      });
      
      debugPrint('채팅방 삭제 시작...');
      
      // 먼저 인포 윈도우 닫기
      widget.onDismiss();
      
      // 채팅방 삭제 - 채팅방 뷰모델의 leaveRoom 함수 호출
      final chatRoomVm = ref.read(chatRoomViewModel.notifier);
      final success = await chatRoomVm.leaveRoom();
      
      // 성공 또는 실패 메시지 표시
      if (mounted) {
        _showSnackBar(
          success ? '채팅방이 삭제되었습니다.' : '채팅방 삭제에 실패했습니다.',
          isError: !success
        );
      }
      
      // 맵 새로고침
      await ref.read(mapProvider.notifier).refreshMap();
      debugPrint('맵 새로고침 완료');
      
      // 맵 초기화 (녹색 마커 생성 모드 비활성화)
      ref.read(mapProvider.notifier).setCreatingChatRoom(false);
      ref.read(mapProvider.notifier).removeTemporaryMarker();
      debugPrint('맵 초기화 완료');
      
    } catch (e) {
      debugPrint('채팅방 삭제 오류: $e');
      if (mounted) {
        _showSnackBar('채팅방 삭제에 실패했습니다: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
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
  
  // 확인 다이얼로그 표시
  void _showDeleteConfirmDialog() {
    // 다이얼로그 표시 전 인포 윈도우를 닫아 UI가 겹치지 않게 함
    widget.onDismiss();
    
    // 다이얼로그 표시 - Future.microtask를 사용하여 함수 호출 스택 이후에 표시되도록 함
    Future.microtask(() {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true, // 배경 터치로 닫기 가능
          barrierColor: Colors.black54, // 배경색 어둡게
          builder: (dialogContext) => AlertDialog(
            title: const Text('채팅방 삭제'),
            content: const Text('정말로 이 채팅방을 삭제하시겠습니까?\n모든 참가자가 나가게 되며, 이 작업은 되돌릴 수 없습니다.'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 24, // 그림자 강화
            backgroundColor: Theme.of(context).cardColor, // 배경색 지정
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _deleteChatRoom();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: isDeleting 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                      ) 
                    : const Text('삭제'),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(appThemeProvider);
    final screenSize = MediaQuery.of(context).size;
    const infoWindowWidth = 350.0;
    const infoWindowHeight = 250.0;

    final left = (screenSize.width - infoWindowWidth) / 2;
    final top = (screenSize.height - infoWindowHeight) / 2 - 150;

    if (isLoading) {
      return Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: infoWindowWidth,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeState.isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }
    
    if (chatRoom == null) {
      return Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: infoWindowWidth,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeState.isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('채팅방 정보를 불러올 수 없습니다'),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: widget.onDismiss,
                  child: const Text('닫기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 배경 레이어 - 투명한 영역을 탭하면 창이 닫히게 함
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Container(color: Colors.transparent),
              ),
            ),
            // 채팅방 정보 창
            Container(
              width: infoWindowWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeState.isDarkMode
                      ? [Colors.grey[800]!, Colors.grey[850]!]
                      : [Colors.white, Colors.grey[100]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: themeState.isDarkMode
                                ? [Colors.blue[400]!, Colors.green[400]!]
                                : [const Color(0xFF2196F3), const Color(0xFF00E676)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          chatRoom!.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: themeState.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (chatRoom!.description != null) ...[
                    Text(
                      chatRoom!.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: themeState.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeState.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: themeState.isDarkMode ? Colors.blue[300] : Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize: 12,
                              color: themeState.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      isCreator 
                          ? TextButton(
                              onPressed: isDeleting ? null : _showDeleteConfirmDialog,
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: isDeleting
                                  ? const SizedBox(
                                      width: 16, 
                                      height: 16, 
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                    )
                                  : const Text('채팅방 삭제'),
                            )
                          : TextButton(
                              onPressed: widget.onDismiss,
                              child: const Text('닫기'),
                            ),
                      ElevatedButton(
                        onPressed: isJoiningRoom ? null : _enterChatRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeState.isDarkMode
                              ? Colors.blue[400]
                              : const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: isJoiningRoom
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                          isInRoom ? '채팅방 입장하기' : '채팅방 참여하기',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}