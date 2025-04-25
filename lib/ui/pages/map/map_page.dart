import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:with_run_app/models/chat_room.dart';
import 'package:with_run_app/services/chat_service.dart';
import 'package:with_run_app/ui/pages/chat/chat_room_page.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final ChatService _chatService = ChatService();
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  OverlayEntry? _chatListOverlay;
  OverlayEntry? _infoWindowOverlay;
  bool _isCreatingChatRoom = false;
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) _showSnackBar('위치 서비스를 활성화해주세요.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) _showSnackBar('위치 권한이 거부되었습니다.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSnackBar('위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해주세요.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
      _moveToCurrentLocation();
      _addCurrentLocationMarker();
    } catch (e) {
      debugPrint('위치 가져오기 오류: $e');
      if (mounted) _showSnackBar('위치 정보를 가져오는데 실패했습니다.');
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_currentPosition != null && _mapController.isCompleted) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('myLocation'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: '내 위치'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }
  }

  Stream<List<ChatRoom>> _loadNearbyChatRooms() {
    if (_currentPosition == null) return Stream.value([]);
    return _chatService.getNearbyRooms(
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
    );
  }

  void _addChatRoomMarker(ChatRoom chatRoom) {
    _markers.add(
      Marker(
        markerId: MarkerId('chatRoom_${chatRoom.id}'),
        position: LatLng(chatRoom.latitude, chatRoom.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: () {
          debugPrint('마커 클릭됨: chatRoom_${chatRoom.id}');
          _showChatRoomInfoWindow(chatRoom);
        },
      ),
    );
  }

  void _addTemporaryMarker(LatLng position) {
    const markerId = MarkerId('temporaryMarker');
    setState(() {
      _selectedPosition = position;
      _markers.removeWhere((marker) => marker.markerId == markerId);
      _markers.add(
        Marker(
          markerId: markerId,
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: '새 채팅방 위치'),
          onTap: () {
            _showSnackBar('새 채팅방 만들기 버튼을 눌러 채팅방을 생성해주세요!');
          },
        ),
      );
    });
  }

  Future<String> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.country ?? ''}'.trim();
      }
      return '주소를 가져올 수 없습니다';
    } catch (e) {
      debugPrint('Geocoding 오류: $e');
      return '주소 변환 실패';
    }
  }

  void _showChatRoomInfoWindow(ChatRoom chatRoom) async {
    if (!mounted) return;
    debugPrint('정보 창 표시: chatRoom_${chatRoom.id}');
    _infoWindowOverlay?.remove();
    _infoWindowOverlay = null;

    final address = await _getAddressFromLatLng(chatRoom.latitude, chatRoom.longitude);

    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;
    const infoWindowWidth = 250.0;
    const infoWindowHeight = 490.0;

    final left = (screenSize.width - infoWindowWidth) / 2;
    final top = (screenSize.height - infoWindowHeight) / 2;

    _infoWindowOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: Consumer<AppThemeProvider>(
          builder: (context, themeProvider, child) => Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => _joinChatRoom(chatRoom),
              child: Container(
                width: infoWindowWidth,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatRoom.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (chatRoom.description != null)
                      Text(
                        chatRoom.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey,
                        ),
                      ),
                    Text(
                      '위치: $address',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _joinChatRoom(chatRoom),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.isDarkMode ? Colors.blue[400] : const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('채팅방 참여'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (mounted) Overlay.of(context).insert(_infoWindowOverlay!);
  }

  Future<void> _joinChatRoom(ChatRoom chatRoom) async {
    try {
      _infoWindowOverlay?.remove();
      _infoWindowOverlay = null;
      final result = await _chatService.joinChatRoom(chatRoom.id);
      if (!mounted) return;
      if (result) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatRoomPage(chatRoom: chatRoom)),
        );
      } else {
        _showSnackBar('채팅방 참여에 실패했습니다.');
      }
    } catch (e) {
      debugPrint('채팅방 참여 오류: $e');
      if (mounted) _showSnackBar('오류 발생: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF00E676),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        elevation: 4,
      ),
    );
  }

  void _showChatListOverlay() async {
    if (!mounted) return;
    _chatListOverlay?.remove();
    _chatListOverlay = null;

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('로그인이 필요합니다.', isError: true);
      return;
    }

    final rooms = await _chatService.getJoinedChatRooms(userId);
    if (!mounted) return;

    final appBarHeight = AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

    _chatListOverlay = OverlayEntry(
      builder: (context) => Consumer<AppThemeProvider>(
        builder: (context, themeProvider, child) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _chatListOverlay?.remove();
                    _chatListOverlay = null;
                  },
                  child: Container(color: const Color(0x80000000)),
                ),
              ),
              Positioned(
                top: appBarHeight,
                right: 16,
                width: 250,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: themeProvider.isDarkMode
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
                                Icon(
                                  Icons.forum_rounded,
                                  color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '내 채팅방',
                                  style: TextStyle(
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 20,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                _chatListOverlay?.remove();
                                _chatListOverlay = null;
                              },
                            ),
                          ],
                        ),
                      ),
                      if (rooms.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 48,
                                color: themeProvider.isDarkMode ? Colors.grey[600] : const Color(0xFFBDBDBD),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '참여 중인 채팅방이 없습니다.',
                                style: TextStyle(
                                  color: themeProvider.isDarkMode ? Colors.grey[400] : const Color(0xFF757575),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: rooms.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                            itemBuilder: (context, index) {
                              final room = rooms[index];
                              return ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: themeProvider.isDarkMode
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
                                    color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF212121),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '참여자: 0명',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: themeProvider.isDarkMode ? Colors.grey[400] : const Color(0xFF757575),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: themeProvider.isDarkMode ? Colors.grey[400] : const Color(0xFF9E9E9E),
                                ),
                                onTap: () {
                                  _chatListOverlay?.remove();
                                  _chatListOverlay = null;
                                  _joinChatRoom(room);
                                },
                                dense: true,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (mounted) Overlay.of(context).insert(_chatListOverlay!);
  }

  void _showCreateChatRoomDialog() {
    if (!mounted) return;
    _isCreatingChatRoom = true;
    _showSnackBar('생성할 위치를 지정해주세요!');
  }

  void _showCreateChatRoomAtLocationDialog(LatLng position) {
    if (!mounted) return;

    final roomNameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierColor: const Color(0x80000000),
      builder: (context) => Consumer<AppThemeProvider>(
        builder: (context, themeProvider, child) => StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 10,
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '선택한 위치에 채팅방 만들기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? Colors.white : const Color(0xFF212121),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: themeProvider.isDarkMode ? Colors.grey[400] : const Color(0xFF757575),
                          ),
                          onPressed: () {
                            setState(() {
                              _markers.removeWhere(
                                  (marker) => marker.markerId == const MarkerId('temporaryMarker'));
                            });
                            Navigator.of(context).pop();
                            _isCreatingChatRoom = false;
                            _selectedPosition = null;
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.grey[800] : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: themeProvider.isDarkMode ? Colors.blue[400] : const Color(0xFF2196F3),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '선택한 위치',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[300]
                                      : const Color(0xFF616161),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '위도: ${position.latitude.toStringAsFixed(6)}\n경도: ${position.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[400]
                                      : const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: roomNameController,
                    decoration: InputDecoration(
                      labelText: '채팅방 이름',
                      hintText: '채팅방 이름을 입력하세요',
                      prefixIcon: Icon(
                        Icons.chat_bubble_outline,
                        color: themeProvider.isDarkMode ? Colors.blue[400] : const Color(0xFF2196F3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: themeProvider.isDarkMode ? Colors.grey[700]! : const Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: themeProvider.isDarkMode ? Colors.blue[400]! : const Color(0xFF2196F3),
                          width: 2,
                        ),
                      ),
                      errorText: errorMessage,
                      filled: true,
                      fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      labelStyle: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.grey[400] : const Color(0xFF757575),
                      ),
                    ),
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                    autofocus: true,
                    onChanged: (value) {
                      if (errorMessage != null && value.trim().isNotEmpty) {
                        setState(() => errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: '설명 (선택사항)',
                      hintText: '채팅방 설명을 입력하세요',
                      prefixIcon: Icon(
                        Icons.description_outlined,
                        color: themeProvider.isDarkMode ? Colors.blue[400] : const Color(0xFF2196F3),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: themeProvider.isDarkMode ? Colors.grey[700]! : const Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: themeProvider.isDarkMode ? Colors.blue[400]! : const Color(0xFF2196F3),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      labelStyle: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.grey[400] : const Color(0xFF757575),
                      ),
                    ),
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _markers.removeWhere(
                                  (marker) => marker.markerId == const MarkerId('temporaryMarker'));
                            });
                            Navigator.of(context).pop();
                            _isCreatingChatRoom = false;
                            _selectedPosition = null;
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                themeProvider.isDarkMode ? Colors.grey[400] : const Color(0xFF757575),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[700]!
                                      : const Color(0xFFE0E0E0)),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final roomName = roomNameController.text.trim();
                            if (roomName.isEmpty) {
                              setState(() => errorMessage = '채팅방 이름을 입력해주세요.');
                              return;
                            }
                            Navigator.of(context).pop();
                            _isCreatingChatRoom = false;
                            _selectedPosition = null;
                            _createChatRoom(
                              latitude: position.latitude,
                              longitude: position.longitude,
                              title: roomName,
                              description: descriptionController.text.trim().isNotEmpty
                                  ? descriptionController.text.trim()
                                  : null,
                              removeTemporaryMarker: true,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                themeProvider.isDarkMode ? Colors.green[400] : const Color(0xFF00E676),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            '만들기',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createChatRoom({
    required double latitude,
    required double longitude,
    required String title,
    String? description,
    bool removeTemporaryMarker = false,
  }) async {
    try {
      final chatRoom = await _chatService.createChatRoom(
        latitude: latitude,
        longitude: longitude,
        title: title,
        description: description,
      );
      if (!mounted) return;
      if (chatRoom != null) {
        _addChatRoomMarker(chatRoom);
        _showSnackBar('채팅방이 생성되었습니다!');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatRoomPage(chatRoom: chatRoom)),
        );
      } else {
        _showSnackBar('채팅방 생성 실패', isError: true);
      }
      if (removeTemporaryMarker) {
        setState(() {
          _markers.removeWhere((marker) => marker.markerId == const MarkerId('temporaryMarker'));
        });
      }
    } catch (e) {
      debugPrint('채팅방 생성 오류: $e');
      if (mounted) _showSnackBar('오류 발생: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _chatListOverlay?.remove();
    _infoWindowOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _currentPosition != null
        ? CameraPosition(target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude), zoom: 15)
        : const CameraPosition(target: LatLng(37.5665, 126.9780), zoom: 11);

    return Consumer<AppThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: GestureDetector(
              onTap: () {
                themeProvider.toggleTheme();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      color: themeProvider.isDarkMode ? Colors.green[600] : const Color(0xFF00E676),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "WithRun",
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.black : const Color(0xFF212121),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
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
                  icon: Icon(
                    Icons.forum_outlined,
                    color: themeProvider.isDarkMode ? Colors.blue[600] : const Color(0xFF2196F3),
                  ),
                  tooltip: '채팅 목록',
                  onPressed: _showChatListOverlay,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              StreamBuilder<List<ChatRoom>>(
                stream: _loadNearbyChatRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('채팅방 로드 실패: ${snapshot.error}'));
                  }

                  final chatRooms = snapshot.data ?? [];
                  _markers.removeWhere((marker) => marker.markerId.value.startsWith('chatRoom_'));
                  for (var chatRoom in chatRooms) {
                    _addChatRoomMarker(chatRoom);
                  }

                  return GoogleMap(
                    initialCameraPosition: initialPosition,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                    compassEnabled: false,
                    onMapCreated: (controller) => _mapController.complete(controller),
                    onTap: (position) {
                      _infoWindowOverlay?.remove();
                      _infoWindowOverlay = null;
                      if (_isCreatingChatRoom) {
                        _addTemporaryMarker(position);
                      }
                    },
                    style: themeProvider.isDarkMode
                        ? themeProvider.darkMapStyle
                        : themeProvider.lightMapStyle,
                  );
                },
              ),
              Positioned(
                right: 16,
                bottom: 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.my_location,
                      color: themeProvider.isDarkMode ? Colors.blue[600] : const Color(0xFF2196F3),
                    ),
                    tooltip: '내 위치로 이동',
                    onPressed: () async {
                      if (_currentPosition != null && _mapController.isCompleted) {
                        final controller = await _mapController.future;
                        controller.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              zoom: 15,
                            ),
                          ),
                        );
                      } else if (_currentPosition == null) {
                        _showSnackBar("현재 위치를 찾을 수 없습니다.", isError: true);
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 220,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: themeProvider.isDarkMode
                            ? [Colors.blue[400]!, Colors.green[400]!]
                            : [const Color(0xFF2196F3), const Color(0xFF00E676)],
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(28)),
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
                        borderRadius: BorderRadius.circular(28),
                        onTap: () {
                          if (_selectedPosition != null) {
                            _showCreateChatRoomAtLocationDialog(_selectedPosition!);
                          } else {
                            _showCreateChatRoomDialog();
                          }
                        },
                        splashColor: const Color(0x33FFFFFF),
                        highlightColor: const Color(0x22FFFFFF),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  themeProvider.isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Colors.white,
                              radius: 14,
                              child: Icon(
                                Icons.add_comment_outlined,
                                color: themeProvider.isDarkMode
                                    ? Colors.blue[600]
                                    : const Color(0xFF2196F3),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '새 채팅방 만들기',
                              style: TextStyle(
                                color: themeProvider.isDarkMode ? Colors.white : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
      },
    );
  }
}