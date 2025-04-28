import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/models/message.dart';
import 'package:with_run_app/services/chat_service.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:provider/provider.dart';

class ChatRoomPage extends StatefulWidget {
  final ChatRoom chatRoom;
  final VoidCallback? onRoomDeleted;

  const ChatRoomPage({
    super.key,  // super 키워드 사용
    required this.chatRoom,
    this.onRoomDeleted,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isComposing = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) => Scaffold(
        appBar: AppBar(
          backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
          elevation: 0,
          title: Text(
            widget.chatRoom.title,
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
              ),
              onPressed: _showMoreOptions,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: _buildMessageList(themeProvider),
            ),
            _buildMessageComposer(themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(AppThemeProvider themeProvider) {
    final currentUserId = _auth.currentUser?.uid;
    return StreamBuilder<List<Message>>(
      stream: _chatService.getMessages(widget.chatRoom.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final messages = snapshot.data ?? [];
        
        // 메시지가 로드되면 스크롤을 아래로 이동
        if (messages.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  '아직 메시지가 없습니다.\n첫 메시지를 보내보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isCurrentUser = message.senderId == currentUserId;
            
            // 날짜 표시 형식
            final formattedDate = DateFormat('MMM d, HH:mm').format(message.timestamp);
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment:
                    isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isCurrentUser) ...[
                    CircleAvatar(
                      backgroundColor: _getAvatarColor(message.senderId),
                      radius: 16,
                      child: Text(
                        _getInitials(message.senderName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Column(
                    crossAxisAlignment:
                        isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!isCurrentUser)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            message.senderName,
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? (themeProvider.isDarkMode ? Colors.blue[700] : Colors.blue[500])
                              : (themeProvider.isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: isCurrentUser
                                ? Colors.white
                                : (themeProvider.isDarkMode ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                        child: Text(
                          formattedDate,
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageComposer(AppThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
                ? Colors.black.withAlpha(100) 
                : Colors.grey.withAlpha(50),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                onChanged: (text) {
                  setState(() {
                    _isComposing = text.isNotEmpty;
                  });
                },
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  hintStyle: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send,
                color: _isComposing
                    ? (themeProvider.isDarkMode ? Colors.blue[400] : Colors.blue[600])
                    : (themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[400]),
              ),
              onPressed: _isComposing
                  ? () {
                      _sendMessage();
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        widget.chatRoom.id,
        _messageController.text.trim(),
      );
      setState(() {
        _messageController.clear();
        _isComposing = false;
      });
      _scrollToBottom();
    }
  }

  Color _getAvatarColor(String userId) {
    // 사용자 ID를 기반으로 고유한 색상 생성
    final int hash = userId.hashCode;
    final int r = ((hash & 0xFF0000) >> 16);
    final int g = ((hash & 0x00FF00) >> 8);
    final int b = (hash & 0x0000FF);
    
    // 너무 밝거나 어두운 색상 방지
    final double brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    if (brightness < 0.3 || brightness > 0.7) {
      return Colors.blue[700]!;
    }
    
    return Color.fromARGB(255, r, g, b);
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  // 채팅방 더보기 메뉴에 삭제/나가기 옵션 추가
  void _showMoreOptions() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = userId != null && widget.chatRoom.creatorId == userId;
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          if (isCreator) // 생성자인 경우만 삭제 옵션 표시
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('채팅방 삭제'),
              onTap: () {
                Navigator.pop(context); // 바텀시트 닫기
                _showDeleteConfirmDialog();
              },
            )
          else // 참여자인 경우 나가기 옵션 표시
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.orange),
              title: const Text('채팅방 나가기'),
              onTap: () {
                Navigator.pop(context); // 바텀시트 닫기
                _showLeaveConfirmDialog();
              },
            ),
        ],
      ),
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅방 삭제'),
        content: const Text('정말로 이 채팅방을 삭제하시겠습니까? 모든 대화 내용이 영구적으로 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteChatRoom();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 나가기 확인 다이얼로그
  void _showLeaveConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅방 나가기'),
        content: const Text('정말로 이 채팅방을 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _leaveChatRoom();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  // 채팅방 삭제 함수
  Future<void> _deleteChatRoom() async {
    try {
      final chatService = ChatService();
      final success = await chatService.deleteChatRoom(widget.chatRoom.id);
      
      if (success) {
        // 채팅방 삭제 성공 시 콜백 호출
        if (widget.onRoomDeleted != null) {
          widget.onRoomDeleted!();
        }
        
        if (mounted) {
          Navigator.of(context).pop(); // 채팅방 화면 종료
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('채팅방이 삭제되었습니다.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('채팅방 삭제 실패')),
          );
        }
      }
    } catch (e) {
      debugPrint('채팅방 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    }
  }

  // 채팅방 나가기 함수
  Future<void> _leaveChatRoom() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      
      final chatService = ChatService();
      final success = await chatService.leaveChatRoom(widget.chatRoom.id, userId);
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop(); // 채팅방 화면 종료
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('채팅방을 나갔습니다.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('채팅방 나가기 실패')),
          );
        }
      }
    } catch (e) {
      debugPrint('채팅방 나가기 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류 발생: $e')),
        );
      }
    }
  }
}