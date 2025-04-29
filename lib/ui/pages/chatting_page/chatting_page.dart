import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:with_run_app/ui/pages/chatting_page/message_provider.dart';
import 'package:with_run_app/ui/pages/chatting_page/widgets/chat_bubble.dart';
import 'package:with_run_app/ui/pages/chatting_page/widgets/chat_input_field.dart';
import 'package:with_run_app/ui/pages/chatting_page/participant_provider.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:with_run_app/ui/pages/running/running_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChattingPage extends ConsumerStatefulWidget {
  final String chatRoomId;
  final String myUserId;
  final String roomName;
  final String location;

  const ChattingPage({
    super.key,
    required this.chatRoomId,
    required this.myUserId,
    required this.roomName,
    required this.location,
  });

  @override
  ConsumerState<ChattingPage> createState() => _ChattingPageState();
}

class _ChattingPageState extends ConsumerState<ChattingPage> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;
  late final MessageProviderArgs _args;
  bool _isCreator = false;
  bool _isLoading = true;
  bool _isLeavingRoom = false; // 중복 나가기 방지
  Map<String, Participant>? _participants;
  bool _hasJoined = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController();
    _args = MessageProviderArgs(
      chatRoomId: widget.chatRoomId,
      myUserId: widget.myUserId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatRoomData();
    });
  }
  
  // 채팅방 데이터 로드하는 메서드 개선
  Future<void> _loadChatRoomData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // 1. 채팅방 입장 - 채팅방 정보를 로드
      final chatRoomVm = ref.read(chatRoomViewModel.notifier);
      final result = await chatRoomVm.enterChatRoom(widget.chatRoomId);
      
      if (!mounted) return;
      
      // 2. 참가자 정보 미리 로드
      final participantsSnapshot = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('participants')
          .get();
      
      final participants = {
        for (var doc in participantsSnapshot.docs)
          doc.id: Participant.fromMap(doc.data())
      };
      
      // 3. 내가 이미 참가자인지 확인
      final isAlreadyParticipant = participants.containsKey(widget.myUserId);
      
      if (!isAlreadyParticipant) {
        // 새 참가자라면 정보 추가
        await _addUserAsParticipant();
        
        // 입장 메시지 전송
        await _sendSystemMessage("${_getUserNickname()} 님이 입장하셨습니다.");
        
        _hasJoined = true;
      }
      
      if (result != null && result.creator != null) {
        setState(() {
          _isCreator = result.creator!.uid == FirebaseAuth.instance.currentUser?.uid;
          _participants = participants;
          _isLoading = false;
        });
      } else {
        setState(() {
          _participants = participants;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('채팅방 데이터 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 데이터 로드 실패: $e')),
        );
      }
    }
  }
  
  // 참가자로 사용자 추가
  Future<void> _addUserAsParticipant() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // 사용자 정보 가져오기 (Firestore users 컬렉션)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      String nickname = user.displayName ?? '사용자';
      String profileImageUrl = user.photoURL ?? '';
      
      // Firestore에 저장된 정보가 있으면 그것 사용
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          nickname = userData['nickname'] ?? nickname;
          profileImageUrl = userData['profileImageUrl'] ?? profileImageUrl;
        }
      }
      
      // 참가자로 추가
      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('participants')
          .doc(user.uid)
          .set({
            'nickname': nickname,
            'profileImageUrl': profileImageUrl,
          });
      
      // 로컬 참가자 목록에도 추가
      setState(() {
        _participants ??= {};
        _participants![user.uid] = Participant(
          nickname: nickname,
          profileImageUrl: profileImageUrl,
        );
      });
    } catch (e) {
      debugPrint('참가자 추가 오류: $e');
    }
  }
  
  // 시스템 메시지 전송 (입장, 퇴장 등)
  Future<void> _sendSystemMessage(String text) async {
    try {
      final newMessage = {
        'chatRoomId': widget.chatRoomId,
        'senderId': 'system',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'senderNickname': '시스템',
        'senderProfileImageUrl': '',
      };

      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add(newMessage);
    } catch (e) {
      debugPrint('시스템 메시지 전송 오류: $e');
    }
  }
  
  // 현재 사용자의 닉네임 가져오기
  String _getUserNickname() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '사용자';
    
    if (_participants != null && _participants!.containsKey(user.uid)) {
      return _participants![user.uid]!.nickname;
    }
    
    return user.displayName ?? '사용자';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 채팅방 나가기 함수
  Future<void> _leaveRoom() async {
    // 중복 실행 방지
    if (_isLeavingRoom) return;
    _isLeavingRoom = true;
    
    try {
      // 로딩 표시
      setState(() {
        _isLoading = true;
      });
      
      // 퇴장 메시지 전송 (방장이 삭제하는 경우 제외)
      if (!_isCreator && _hasJoined) {
        await _sendSystemMessage("${_getUserNickname()} 님이 퇴장하셨습니다.");
      }
      
      // 채팅방 나가기 처리
      await ref.read(chatRoomViewModel.notifier).leaveRoom();
      
      // 로딩 숨김
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // 맵 페이지로 이동
      if (mounted) {
        // 맵으로 돌아가기 전 채팅방 상태 초기화
        ref.read(chatRoomViewModel.notifier).leaveChatRoom();
        
        // 스택의 모든 화면을 제거하고 맵 페이지로 이동
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const MapPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('채팅방 나가기 오류: $e');
      
      // 오류 발생해도 로딩 숨김
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 나가기 실패: $e')),
        );
        
        // 오류가 발생해도 맵 페이지로 강제 이동
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const MapPage()),
          (route) => false,
        );
      }
    } finally {
      _isLeavingRoom = false;
    }
  }

  // 러닝 페이지로 이동
  void _navigateToRunningPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunningPage(
          chatRoomId: widget.chatRoomId,
          userId: widget.myUserId,
          isCreator: _isCreator,
        ),
      ),
    );
  }

  // 참여자 목록 다이얼로그 표시
  void _showParticipantsDialog() {
    final participantsAsync = ref.read(participantProvider(widget.chatRoomId));
    
    participantsAsync.when(
      data: (participants) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '참여자 목록',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (participants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('참가자가 없습니다')),
                    )
                  else
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final userId = participants.keys.elementAt(index);
                          final participant = participants[userId]!;
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                participant.profileImageUrl.isNotEmpty
                                    ? participant.profileImageUrl
                                    : 'https://via.placeholder.com/150',
                              ),
                            ),
                            title: Text(
                              participant.nickname,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('참가자 정보를 불러오는데 실패했습니다: $e')),
      ),
    );
  }
  
  // 메시지 전송 처리
  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    // MessageProvider의 sendMessage 호출
    ref.read(messageProvider(_args).notifier).sendMessage(text);
    
    // 컨트롤러 초기화
    _controller.clear();
    
    // 스크롤 최상단으로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messageProvider(_args));
    final participantsAsync = ref.watch(participantProvider(widget.chatRoomId));

    // 로딩 상태 추가
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.roomName),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.roomName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                // 러닝 버튼 
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  width: 44,
                  height: 44, 
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/run_time.svg',
                      height: 36,  // 아이콘만 크기 증가
                      width: 36,   // 아이콘만 크기 증가
                      colorFilter: ColorFilter.mode(Colors.blue.shade700, BlendMode.srcIn),
                    ),
                    tooltip: '러닝',
                    padding: EdgeInsets.zero, // 패딩 제거하여 아이콘을 더 크게 표시
                    onPressed: _navigateToRunningPage,
                  ),
                ),
                
                // 참여자 목록 버튼
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  width: 44,
                  height: 44,
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/user_list.svg',
                      height: 36,  // 아이콘만 크기 증가 
                      width: 36,   // 아이콘만 크기 증가
                      colorFilter: ColorFilter.mode(Colors.blue.shade700, BlendMode.srcIn),
                    ),
                    tooltip: '참여자 목록',
                    padding: EdgeInsets.zero, // 패딩 제거하여 아이콘을 더 크게 표시
                    onPressed: _showParticipantsDialog,
                  ),
                ),
                
                // 나가기 버튼
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  width: 44,
                  height: 44,
                  child: IconButton(
                    icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 36), // 아이콘만 크기 증가
                    tooltip: _isCreator ? '채팅방 삭제' : '채팅방 나가기',
                    padding: EdgeInsets.zero, // 패딩 제거하여 아이콘을 더 크게 표시
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierColor: Colors.black54, // 배경 어둡게
                        builder: (dialogContext) => AlertDialog(
                          title: Text(_isCreator ? '채팅방 삭제' : '채팅방 나가기'),
                          content: Text(_isCreator 
                            ? '채팅방을 삭제하시겠습니까? 모든 참가자가 나가게 됩니다.' 
                            : '정말 채팅방을 나가시겠습니까?'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 24, // 그림자 강화
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _leaveRoom();
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: Text(
                                _isCreator ? '삭제' : '나가기',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        titleSpacing: 8, // 타이틀 간격 줄임
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('참가자 정보를 가져오는 중 오류 발생!')),
        data: (participants) {
          // 로컬에 저장된 참가자 정보 업데이트
          if (_participants == null || _participants!.isEmpty) {
            setState(() {
              _participants = participants;
            });
          }
          
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('대화를 시작해 보세요!'))
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          
                          // 시스템 메시지 처리 (입장, 퇴장 메시지)
                          if (msg.senderId == 'system') {
                            return Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  msg.text,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          // 일반 메시지 처리
                          final participant = participants[msg.senderId];
                          
                          return ChatBubble(
                            senderId: msg.senderId,
                            myUserId: widget.myUserId,
                            text: msg.text,
                            time: DateFormat('a h:mm', 'ko_KR').format(msg.timestamp),
                            nickname: participant?.nickname ?? msg.senderNickname,
                            profileImageUrl: participant?.profileImageUrl ?? msg.senderProfileImageUrl,
                          );
                        },
                      ),
              ),
              SafeArea(
                child: ChatInputField(
                  controller: _controller,
                  onSend: _handleSendMessage,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}