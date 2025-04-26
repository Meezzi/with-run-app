import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/services/chat_service.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:with_run_app/ui/pages/map/widgets/chat_list_overlay.dart';
import 'package:with_run_app/ui/pages/map/widgets/chat_room_info_window.dart';
import 'package:with_run_app/ui/pages/map/widgets/create_chat_room_dialog.dart';
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';
import 'package:with_run_app/ui/pages/setting/setting_page.dart';
import 'package:provider/provider.dart' as provider;



class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  OverlayEntry? _chatListOverlay;
  OverlayEntry? _infoWindowOverlay;
  bool _isInitialized = false;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isInitialized) {
        _isInitialized = true;
        ref
            .read(mapProvider.notifier)
            .setOnChatRoomMarkerTapCallback(showChatRoomInfoWindow);
        ref
            .read(mapProvider.notifier)
            .setOnTemporaryMarkerTapCallback(_showCreateChatRoomConfirmDialog);
      }
    });
  }

  @override
  void dispose() {
    _closeOverlays();
    super.dispose();
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

  void _showChatListOverlay() {
    _closeOverlays();
    _chatListOverlay = OverlayEntry(
      builder:
          (context) => ChatListOverlay(
            onShowSnackBar: _showSnackBar,
            onDismiss: () {
              _chatListOverlay?.remove();
              _chatListOverlay = null;
            },
          ),
    );
    if (mounted) Overlay.of(context).insert(_chatListOverlay!);
  }

  void _closeOverlays() {
    _chatListOverlay?.remove();
    _infoWindowOverlay?.remove();
    _chatListOverlay = null;
    _infoWindowOverlay = null;
  }

  void showChatRoomInfoWindow(ChatRoom chatRoom) {
    if (!mounted) return;
    _closeOverlays();
    _infoWindowOverlay = OverlayEntry(
      builder:
          (context) => ChatRoomInfoWindow(
            chatRoom: chatRoom,
            onDismiss: () {
              _infoWindowOverlay?.remove();
              _infoWindowOverlay = null;
            },
            onShowSnackBar: _showSnackBar,
          ),
    );
    Overlay.of(context).insert(_infoWindowOverlay!);
  }

  void _showCreateChatRoomConfirmDialog(LatLng position) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Transform.translate(
            offset: const Offset(0, -160),
            child: Align(
              alignment: Alignment.topCenter,
              child: CreateChatRoomDialog(
                position: position,
                onShowSnackBar: _showSnackBar,
                onDismiss: () => Navigator.of(context).pop(),
              ),
            ),
          ),
    );
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

  void _startChatRoomCreationMode() {
    if (!mounted) return;
    if (FirebaseAuth.instance.currentUser == null) {
      _showSnackBar('로그인이 필요합니다.', isError: true);
      return;
    }
    final mapState = ref.read(mapProvider);
    if (mapState.selectedPosition != null) {
      _navigateToChatCreatePage();
    } else {
      _checkUserHasCreatedRoom().then((hasCreatedRoom) {
        if (hasCreatedRoom) {
          _showSnackBar(
            '이미 개설한 채팅방이 있습니다. 한 사용자당 하나의 채팅방만 개설할 수 있습니다.',
            isError: true,
          );
        } else {
          ref.read(mapProvider.notifier).setCreatingChatRoom(true);
          _showLocationSelectionDialog();
        }
      });
    }
  }

  void _navigateToChatCreatePage() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatCreatePage()),
    );
  }

  void _showLocationSelectionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, size: 40, color: Colors.blue),
                  const SizedBox(height: 8),
                  const Text(
                    '지도에서 채팅방을 개설할 위치를 선택해주세요',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _moveToCurrentLocation() {
    if (!mounted) return;
    final locationState = ref.read(locationProvider);
    if (locationState.currentPosition != null) {
      ref.read(mapProvider.notifier).moveToCurrentLocation();
    } else if (locationState.error != null) {
      _showSnackBar(locationState.error!, isError: true);
    } else {
      _showSnackBar("위치 정보를 가져오는 중입니다...");
      ref.read(locationProvider.notifier).refreshLocation();
    }
  }

  Widget _buildAppTitle(AppThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_run,
              color:
                  themeProvider.isDarkMode
                      ? Colors.green[600]
                      : const Color(0xFF00E676),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "WithRun",
              style: TextStyle(
                color:
                    themeProvider.isDarkMode
                        ? Colors.black
                        : const Color(0xFF212121),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.white : Colors.grey[300],
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);
    final locationState = ref.watch(locationProvider);
    final mapState = ref.watch(mapProvider);

    final initialPosition =
        locationState.currentPosition != null
            ? CameraPosition(
              target: LatLng(
                locationState.currentPosition!.latitude,
                locationState.currentPosition!.longitude,
              ),
              zoom: 15,
            )
            : const CameraPosition(target: LatLng(37.5665, 126.9780), zoom: 11);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? Colors.white : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.menu,
              color:
                  themeProvider.isDarkMode
                      ? Colors.blue[600]!
                      : const Color(0xFF2196F3),
            ),
            tooltip: '설정',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingPage()),
              );
            },
          ),
        ),
        title: _buildAppTitle(themeProvider),
        centerTitle: true,
        actions: [
          _buildActionButton(
            icon: Icons.my_location,
            iconColor:
                themeProvider.isDarkMode
                    ? Colors.blue[600]!
                    : const Color(0xFF2196F3),
            onPressed: _moveToCurrentLocation,
            tooltip: '내 위치로 이동',
          ),
          _buildActionButton(
            icon: Icons.forum_outlined,
            iconColor:
                themeProvider.isDarkMode
                    ? Colors.blue[600]!
                    : const Color(0xFF2196F3),
            onPressed: _showChatListOverlay,
            tooltip: '채팅 목록',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            markers: mapState.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: false,
            onMapCreated:
                (controller) =>
                    ref.read(mapProvider.notifier).setMapController(controller),
            onTap: (position) {
              _closeOverlays();
              if (mapState.isCreatingChatRoom) {
                _checkUserHasCreatedRoom().then((hasCreatedRoom) {
                  if (hasCreatedRoom) {
                    _showSnackBar(
                      '이미 개설한 채팅방이 있습니다. 한 사용자당 하나의 채팅방만 개설할 수 있습니다.',
                      isError: true,
                    );
                    ref.read(mapProvider.notifier).setCreatingChatRoom(false);
                  } else {
                    ref.read(mapProvider.notifier).onMapTap(position);
                  }
                });
              }
            },
            mapType: MapType.normal,
            liteModeEnabled: false,
            style: themeProvider.isDarkMode ? themeProvider.darkMapStyle : themeProvider.lightMapStyle,
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 240,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        themeProvider.isDarkMode
                            ? [Colors.blue[400]!, Colors.green[400]!]
                            : [
                              const Color(0xFF2196F3),
                              const Color(0xFF00E676),
                            ],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _startChatRoomCreationMode,
                    splashColor: const Color(0x33FFFFFF),
                    highlightColor: const Color(0x22FFFFFF),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 16,
                          child: Icon(
                            Icons.add_comment_outlined,
                            color:
                                themeProvider.isDarkMode
                                    ? Colors.green[600]
                                    : const Color(0xFF2196F3),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '새 채팅방 만들기',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}