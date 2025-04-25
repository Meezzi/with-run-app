import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:with_run_app/ui/pages/map/widgets/chat_list_overlay.dart';
import 'package:with_run_app/ui/pages/map/widgets/chat_room_info_window.dart';
import 'package:with_run_app/ui/pages/map/widgets/create_chat_room_button.dart';
import 'package:with_run_app/ui/pages/map/widgets/create_chat_room_dialog.dart';
import 'package:provider/provider.dart' as provider;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  OverlayEntry? _chatListOverlay;
  OverlayEntry? _infoWindowOverlay;

  @override
  void initState() {
    super.initState();
    // 맵 마커 클릭 콜백 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapProvider.notifier).setOnChatRoomMarkerTapCallback(showChatRoomInfoWindow);
    });
  }

  @override
  void dispose() {
    _chatListOverlay?.remove();
    _infoWindowOverlay?.remove();
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
      builder: (context) => ChatListOverlay(
        onShowSnackBar: _showSnackBar,
        onDismiss: () {
          _chatListOverlay?.remove();
          _chatListOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_chatListOverlay!);
  }

  void _closeOverlays() {
    _chatListOverlay?.remove();
    _infoWindowOverlay?.remove();
    _chatListOverlay = null;
    _infoWindowOverlay = null;
  }

  void showChatRoomInfoWindow(ChatRoom chatRoom) {
    _closeOverlays();

    _infoWindowOverlay = OverlayEntry(
      builder: (context) => ChatRoomInfoWindow(
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

  void _showCreateChatRoomDialog() {
    final mapState = ref.read(mapProvider);
    if (mapState.selectedPosition != null) {
      showDialog(
        context: context,
        barrierColor: const Color(0x80000000),
        builder: (context) => CreateChatRoomDialog(
          position: mapState.selectedPosition!,
          onShowSnackBar: _showSnackBar,
          onDismiss: () {
            Navigator.of(context).pop();
            ref.read(mapProvider.notifier).setCreatingChatRoom(false);
          },
        ),
      );
    }
  }

  void _moveToCurrentLocation() {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run, 
                color: themeProvider.isDarkMode ? Colors.green[600] : const Color(0xFF00E676), 
                size: 20),
            const SizedBox(width: 8),
            Text("WithRun",
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.black : const Color(0xFF212121),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required Color iconColor, 
    required VoidCallback onPressed, 
    required String tooltip
  }) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.white : Colors.grey[300],
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
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

    // 초기 카메라 위치 설정
    final initialPosition = locationState.currentPosition != null
        ? CameraPosition(
            target: LatLng(
              locationState.currentPosition!.latitude,
              locationState.currentPosition!.longitude,
            ),
            zoom: 10,
          )
        : const CameraPosition(target: LatLng(37.5665, 126.9780), zoom: 10);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildAppTitle(themeProvider),
        centerTitle: true,
        actions: [
          // 내 위치 버튼
          _buildActionButton(
            icon: Icons.my_location,
            iconColor: themeProvider.isDarkMode ? Colors.blue[600]! : const Color(0xFF2196F3),
            onPressed: _moveToCurrentLocation,
            tooltip: '내 위치로 이동',
          ),
          
          // 채팅 목록 버튼
          _buildActionButton(
            icon: Icons.forum_outlined,
            iconColor: themeProvider.isDarkMode ? Colors.blue[600]! : const Color(0xFF2196F3),
            onPressed: _showChatListOverlay,
            tooltip: '채팅 목록',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 구글 맵
          GoogleMap(
            initialCameraPosition: initialPosition,
            markers: mapState.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: false,
            onMapCreated: (controller) {
              ref.read(mapProvider.notifier).setMapController(controller);
            },
            onTap: (position) {
              // 열려있는 오버레이 닫기
              _closeOverlays();

              // 채팅방 생성 모드라면 임시 마커 추가
              if (mapState.isCreatingChatRoom) {
                ref.read(mapProvider.notifier).onMapTap(position);
              }
            },
            mapType: MapType.normal,
            liteModeEnabled: false,
          ),
          
          // 새 채팅방 버튼
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: CreateChatRoomButton(
              onShowSnackBar: _showSnackBar,
              onCreateButtonTap: _showCreateChatRoomDialog,
            ),
          ),
        ],
      ),
    );
  }
}