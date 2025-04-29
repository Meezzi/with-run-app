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
      _checkIfCreator();
    });
  }

  // 사용자가 방장인지 확인
  Future<void> _checkIfCreator() async {
    final chatRoom = ref.read(chatRoomViewModel);
    if (chatRoom != null && chatRoom.creator != null) {
      setState(() {
        _isCreator = chatRoom.creator!.uid == FirebaseAuth.instance.currentUser?.uid;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 채팅방 나가기 함수
  Future<void> _leaveRoom() async {
    try {
      final success = await ref.read(chatRoomViewModel.notifier).leaveRoom();
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (context) => const MapPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('채팅방 나가기 실패: $e')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messageProvider(_args));
    final notifier = ref.read(messageProvider(_args).notifier);
    final participantsAsync = ref.watch(participantProvider(widget.chatRoomId));

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
              //    Text(
              //      widget.location,
              //      style: const TextStyle(fontSize: 12),
              //      overflow: TextOverflow.ellipsis,
              //    ),
                ],
              ),
            ),
            Row(
              children: [
                // 러닝 버튼
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/run_time.svg',
                    height: 24,
                    width: 24, 
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  ),
                  onPressed: _navigateToRunningPage,
                ),
                // 참여자 목록 버튼
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/user_list.svg',
                    height: 24,
                    width: 24,
                    colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  ),
                  onPressed: _showParticipantsDialog,
                ),
                // 나가기 버튼
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(_isCreator ? '채팅방 삭제' : '채팅방 나가기'),
                        content: Text(_isCreator 
                          ? '채팅방을 삭제하시겠습니까? 모든 참가자가 나가게 됩니다.' 
                          : '정말 채팅방을 나가시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _leaveRoom();
                            },
                            child: Text(
                              _isCreator ? '삭제' : '나가기',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: participantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('참가자 정보를 가져오는 중 오류 발생!')),
        data: (participants) {
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
                          final participant = participants[msg.senderId];

                          return ChatBubble(
                            senderId: msg.senderId,
                            myUserId: widget.myUserId,
                            text: msg.text,
                            time: DateFormat('a h:mm', 'ko_KR').format(msg.timestamp),
                            nickname: participant?.nickname ?? '알 수 없음',
                            profileImageUrl: participant?.profileImageUrl ?? '',
                          );
                        },
                      ),
              ),
              SafeArea(
                child: ChatInputField(
                  controller: _controller,
                  onSend: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      notifier.sendMessage(text);
                      _controller.clear();
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
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}