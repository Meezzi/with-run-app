import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/ui/pages/chat_information/chat_participant_list.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';
import 'package:with_run_app/ui/pages/chatting_page/chatting_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';

class ChatInformationPage extends ConsumerStatefulWidget {
  const ChatInformationPage({super.key});
  
  @override
  ConsumerState<ChatInformationPage> createState() => _ChatInformationPageState();
}

class _ChatInformationPageState extends ConsumerState<ChatInformationPage> {
  String address = '주소 불러오는 중...';
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddress();
    });
  }
  
  Future<void> _loadAddress() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final chatRoom = ref.read(chatRoomViewModel);
      
      if (chatRoom != null && chatRoom.location != null) {
        final location = chatRoom.location;
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude, 
          location.longitude
        );
        
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
      } else {
        setState(() {
          address = '위치 정보가 없습니다';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        address = '주소를 불러올 수 없습니다';
        isLoading = false;
      });
      debugPrint('주소 로드 오류: $e');
    }
  }
  
  void _enterChatRoom() {
    final chatRoom = ref.read(chatRoomViewModel);
    if (chatRoom == null) return;
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChattingPage(
          chatRoomId: chatRoom.id ?? '',
          myUserId: userId,
          roomName: chatRoom.title,
          location: address,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final chatRoom = ref.watch(chatRoomViewModel);
    
    if (chatRoom == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('채팅방 정보'),
        ),
        body: const Center(
          child: Text('채팅방 정보를 불러올 수 없습니다'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(chatRoom.title),
      ),
      body: Column(
        children: [
          _buildChatInfo(chatRoom),
          Expanded(
            child: ChatParticipantList(
              participants: chatRoom.participants ?? [],
              creator: chatRoom.creator!,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enterChatRoom,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('채팅방 입장하기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatInfo(ChatRoomModel chatRoom) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chatRoom.description != null && chatRoom.description!.isNotEmpty) ...[
              const Text(
                '설명',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(chatRoom.description!),
              const SizedBox(height: 12),
            ],
            
            const Text(
              '위치',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            isLoading
                ? const CircularProgressIndicator()
                : Text(address),
            const SizedBox(height: 12),
            
            const Text(
              '일정',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${chatRoom.startTime.year}/${chatRoom.startTime.month}/${chatRoom.startTime.day}'
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${chatRoom.startTime.hour.toString().padLeft(2, '0')}:${chatRoom.startTime.minute.toString().padLeft(2, '0')} ~ ${chatRoom.endTime.hour.toString().padLeft(2, '0')}:${chatRoom.endTime.minute.toString().padLeft(2, '0')}'
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}