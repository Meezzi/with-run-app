import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/data/model/chat_room_model.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:with_run_app/ui/pages/chat_information/chat_information_page.dart';
import 'package:with_run_app/ui/pages/chatting_page/chat_room_view_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadChatRoom();
  }

  Future<void> _loadChatRoom() async {
    try {
      // 채팅방 정보 로드
      final result = await ref.read(chatRoomViewModel.notifier).enterChatRoom(widget.chatRoomId);
      
      if (result != null) {
        setState(() {
          chatRoom = result;
        });
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
      
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          address = '주소를 불러올 수 없습니다';
          isLoading = false;
        });
      }
      debugPrint('주소 로드 오류: $e');
    }
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
        child: Container(
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
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: const Text('닫기'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      widget.onDismiss();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatInformationPage(),
                        ),
                      );
                    },
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
                    child: const Text(
                      '채팅방 보기',
                      style: TextStyle(
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
      ),
    );
  }
}