import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:with_run_app/ui/pages/chatting_page/chatting_page.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:with_run_app/ui/pages/map/viewmodels/chat_list_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';

class ChatListOverlay extends ConsumerStatefulWidget {
  final VoidCallback onDismiss;

  const ChatListOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  ConsumerState<ChatListOverlay> createState() => _ChatListOverlayState();
}

class _ChatListOverlayState extends ConsumerState<ChatListOverlay> {
  bool _isJoiningRoom = false;
  String? _processingRoomId;
  
  @override
  void initState() {
    super.initState();
    debugPrint('채팅방 목록 오버레이 초기화');
    // 맵 정보 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mapProvider.notifier).printDebugInfo();
        // 목록을 최신으로 갱신
        ref.read(chatListViewModelProvider.notifier).refreshChatRooms();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(appThemeProvider);
    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;
    final chatListState = ref.watch(chatListViewModelProvider);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 투명한 배경 클릭 시 오버레이 닫기
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(color: const Color(0x80000000)),
            ),
          ),
          Positioned(
            top: appBarHeight,
            right: 16,
            width: 280, // 약간 넓게 조정
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7, // 더 많은 채팅방 표시
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeState.isDarkMode
                      ? [Colors.grey[800]!, Colors.grey[850]!]
                      : [Colors.white, Colors.grey[100]!],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(themeState, ref),
                  chatListState.when(
                    data: (rooms) => rooms.isEmpty
                        ? _buildEmptyView(themeState)
                        : _buildRoomsList(context, themeState, rooms),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text('오류: $error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(chatListViewModelProvider.notifier).refreshChatRooms();
                              },
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppThemeState themeState, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: themeState.isDarkMode
              ? [Colors.blue[400]!, Colors.green[400]!]
              : [const Color(0xFF2196F3), const Color(0xFF00E676)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.forum_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '내 채팅방',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // 새로고침 버튼 추가
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  size: 20,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  debugPrint('채팅방 목록 새로고침 요청');
                  // 채팅방 목록 수동 새로고침
                  ref.read(chatListViewModelProvider.notifier).refreshChatRooms();
                  
                  // 맵 상태도 새로고침 - 많은 문제가 맵 상태 불일치로 발생함
                  ref.read(mapProvider.notifier).refreshMap();
                },
                tooltip: '채팅방 목록 새로고침',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(AppThemeState themeState) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 48,
            color: themeState.isDarkMode
                ? Colors.grey[500]
                : const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 16),
          Text(
            '참여 중인 채팅방이 없습니다.',
            style: TextStyle(
              color: themeState.isDarkMode
                  ? Colors.grey[300]
                  : const Color(0xFF757575),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '지도 하단의 \'새 채팅방 만들기\' 버튼을 눌러\n새로운 채팅방을 만들어보세요!',
            style: TextStyle(
              color: themeState.isDarkMode
                  ? Colors.grey[400]
                  : const Color(0xFF9E9E9E),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRoomsList(
    BuildContext context,
    AppThemeState themeState,
    List<ChatRoomModel> rooms,
  ) {
    return Flexible(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: rooms.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: themeState.isDarkMode ? Colors.grey[700] : Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final room = rooms[index];
          final isProcessing = _isJoiningRoom && _processingRoomId == room.id;
          
          return ListTile(
            leading: Container(
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
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              room.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeState.isDarkMode
                    ? Colors.white
                    : const Color(0xFF212121),
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '참여자: ${room.participants?.length ?? 0}명',
              style: TextStyle(
                fontSize: 12,
                color: themeState.isDarkMode
                    ? Colors.grey[400]
                    : const Color(0xFF757575),
              ),
            ),
            trailing: isProcessing
                ? const SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: themeState.isDarkMode 
                          ? Colors.blue[700] 
                          : Colors.blue[600],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '입장',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            onTap: isProcessing ? null : () => _enterChatRoom(room),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        },
      ),
    );
  }
  
  Future<void> _enterChatRoom(ChatRoomModel room) async {
    if (_isJoiningRoom) return; // 이미 처리 중이면 중복 실행 방지
    
    setState(() {
      _isJoiningRoom = true;
      _processingRoomId = room.id;
    });
    
    try {
      debugPrint('채팅방 입장 시작: ${room.id}');
      
      // 채팅방 입장
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 채팅방 정보 가져오기
        final chatRoomVm = ref.read(chatRoomViewModel.notifier);
        final result = await chatRoomVm.enterChatRoom(room.id ?? '');
        
        debugPrint('채팅방 입장 결과: $result');
        
        if (result != null) {
          debugPrint('채팅방 입장 성공: ${room.id}, 화면 전환 시작');
          
          // 먼저 오버레이 닫기
          widget.onDismiss();
          
          // 딜레이 없이 바로 채팅방 페이지로 이동
          if (mounted) {
            debugPrint('ChattingPage로 즉시 이동 시작');
            
            // 직접 Navigator를 통해 화면 이동
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => ChattingPage(
                  chatRoomId: room.id ?? '',
                  myUserId: user.uid,
                  roomName: room.title,
                  location: '${room.location.latitude}, ${room.location.longitude}',
                ),
              ),
            );
          }
        } else {
          debugPrint('채팅방 입장 실패 - 결과가 null: ${room.id}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('채팅방 정보를 불러올 수 없습니다'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('채팅방 입장 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('채팅방 입장 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoiningRoom = false;
          _processingRoomId = null;
        });
      }
    }
  }
}