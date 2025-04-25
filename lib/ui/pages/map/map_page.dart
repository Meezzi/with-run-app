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
import 'package:with_run_app/ui/pages/chat_create/chat_create_page.dart';

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
  StreamSubscription<Position>? _positionStream;
  List<ChatRoom>? _cachedChatRooms;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    if (_currentPosition != null) {
      _loadNearbyChatRooms().first.then((rooms) {
        if (mounted) {
          setState(() {
            _cachedChatRooms = rooms;
            for (var room in rooms) {
              _addChatRoomMarker(room);
            }
          });
        }
      });
    }
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
      _moveToCurrentLocation();
      _addCurrentLocationMarker();

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _updateCurrentLocationMarker();
        });
      });

      _loadNearbyChatRooms().first.then((rooms) {
        if (mounted) {
          setState(() {
            _cachedChatRooms = rooms;
            for (var room in rooms) {
              _addChatRoomMarker(room);
            }
          });
        }
      });
    } catch (e) {
      debugPrint('위치 가져오기 오류: $e');
      if (mounted) _showSnackBar('위치 정보를 가져오는데 실패했습니다.');
    }
  }

  void _updateCurrentLocationMarker() {
    if (_currentPosition != null) {
      setState(() {
        _markers.removeWhere(
          (marker) => marker.markerId == const MarkerId('myLocation'),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('myLocation'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(title: '내 위치'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      });
    }
  }

  Future<void> _moveToCurrentLocation() async {
    if (_currentPosition != null && _mapController.isCompleted) {
      final controller = await _mapController.future;
      try {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 15.0,
            ),
          ),
        );
      } catch (e) {
        debugPrint("Failed to animate camera: $e");
      }
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('myLocation'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
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

  Future<void> _refreshMapAfterRoomDeletion(String roomId) async {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId == MarkerId('chatRoom_$roomId'),
      );
      if (_cachedChatRooms != null) {
        _cachedChatRooms!.removeWhere((room) => room.id == roomId);
      }
    });

    if (_currentPosition != null) {
      final newRooms = await _loadNearbyChatRooms().first;
      if (mounted) {
        setState(() {
          _cachedChatRooms = newRooms;
          _markers.removeWhere(
            (marker) => marker.markerId.value.startsWith('chatRoom_'),
          );
          for (var room in newRooms) {
            _addChatRoomMarker(room);
          }
        });
      }
    }
  }

  Future<bool> _checkUserHasCreatedRoom() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final hasCreatedRoom = await _chatService.hasUserCreatedRoom(userId);
      return hasCreatedRoom;
    } catch (e) {
      debugPrint('사용자 채팅방 확인 오류: $e');
      return false;
    }
  }

  Future<bool> _checkUserHasJoinedRoom() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false;

    try {
      final rooms = await _chatService.getJoinedChatRooms(userId);
      return rooms.isNotEmpty;
    } catch (e) {
      debugPrint('사용자 참여 채팅방 확인 오류: $e');
      return false;
    }
  }

  void _addChatRoomMarker(ChatRoom chatRoom) {
    if (!_markers.any(
      (marker) => marker.markerId == MarkerId('chatRoom_${chatRoom.id}'),
    )) {
      _markers.add(
        Marker(
          markerId: MarkerId('chatRoom_${chatRoom.id}'),
          position: LatLng(chatRoom.latitude, chatRoom.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          onTap: () {
            debugPrint('마커 클릭됨: chatRoom_${chatRoom.id}');
            _showChatRoomInfoWindow(chatRoom);
          },
        ),
      );
    }
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: '새 채팅방 위치'),
          onTap: () {
            _showMarkerConfirmationDialog(position);
          },
        ),
      );
    });

    _mapController.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

  void _showMarkerConfirmationDialog(LatLng position) {
    showDialog(
      context: context,
      builder: (context) => Consumer<AppThemeProvider>(
        builder: (context, themeProvider, child) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: themeProvider.isDarkMode
                    ? [Colors.grey[800]!, Colors.grey[850]!]
                    : [Colors.white, Colors.grey[100]!],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: themeProvider.isDarkMode
                      ? Colors.greenAccent
                      : const Color(0xFF00E676),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  '새 채팅방 위치',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '이 위치에 채팅방을 생성하시겠습니까?',
                  style: TextStyle(
                    fontSize: 16,
                    color: themeProvider.isDarkMode
                        ? Colors.grey[300]
                        : Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _removeTemporaryMarker();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: themeProvider.isDarkMode
                              ? Colors.grey[300]
                              : Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: themeProvider.isDarkMode
                                  ? Colors.grey[600]!
                                  : Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Text(
                          '아니요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showCreateChatRoomAtLocationDialog(position);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.isDarkMode
                              ? Colors.greenAccent
                              : const Color(0xFF00E676),
                          foregroundColor: themeProvider.isDarkMode
                              ? Colors.black87
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '예',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  void _removeTemporaryMarker() {
    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId == const MarkerId('temporaryMarker'),
      );
      _selectedPosition = null;
      _isCreatingChatRoom = false;
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
    const infoWindowWidth = 350.0;
    const infoWindowHeight = 250.0;

    final left = (screenSize.width - infoWindowWidth) / 2;
    final top = (screenSize.height - infoWindowHeight) / 2 - 150;

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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: themeProvider.isDarkMode
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
                              colors: themeProvider.isDarkMode
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
                            chatRoom.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (chatRoom.description != null) ...[
                      Text(
                        chatRoom.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: themeProvider.isDarkMode ? Colors.blue[300] : Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                fontSize: 12,
                                color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _joinChatRoom(chatRoom),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.isDarkMode
                              ? Colors.blue[400]
                              : const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '채팅방 참여',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('로그인이 필요합니다.', isError: true);
      return;
    }

    if (chatRoom.creatorId == userId) {
      try {
        _infoWindowOverlay?.remove();
        _infoWindowOverlay = null;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoom: chatRoom,
              onRoomDeleted: () => _refreshMapAfterRoomDeletion(chatRoom.id),
            ),
          ),
        );
      } catch (e) {
        debugPrint('채팅방 참여 오류: $e');
        if (mounted) _showSnackBar('오류 발생: $e');
      }
      return;
    }

    final hasJoinedRoom = await _checkUserHasJoinedRoom();
    if (!mounted) return;

    if (hasJoinedRoom) {
      _showSnackBar('이미 참여 중인 채팅방이 있습니다. 한 번에 하나의 채팅방에만 참여할 수 있습니다.', isError: true);
      return;
    }

    try {
      _infoWindowOverlay?.remove();
      _infoWindowOverlay = null;
      final result = await _chatService.joinChatRoom(chatRoom.id);
      if (!mounted) return;
      if (result) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              chatRoom: chatRoom,
              onRoomDeleted: () => _refreshMapAfterRoomDeletion(chatRoom.id),
            ),
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 130),
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: themeProvider.isDarkMode
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
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
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[500]
                                    : const Color(0xFFBDBDBD),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '참여 중인 채팅방이 없습니다.',
                                style: TextStyle(
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[300]
                                      : const Color(0xFF757575),
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
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            ),
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
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : const Color(0xFF212121),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '참여자: ${room.participants?.length ?? 0}명',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[400]
                                        : const Color(0xFF757575),
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[400]
                                      : const Color(0xFF9E9E9E),
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

  Future<void> _onNewChatRoomButtonTap() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showSnackBar('로그인이 필요합니다.', isError: true);
      return;
    }

    final hasCreatedRoom = await _checkUserHasCreatedRoom();
    if (hasCreatedRoom) {
      _showSnackBar(
        '이미 개설한 채팅방이 있습니다. 한 사용자당 하나의 채팅방만 개설할 수 있습니다.',
        isError: true,
      );
      return;
    }

    final hasJoinedRoom = await _checkUserHasJoinedRoom();
    if (hasJoinedRoom) {
      _showSnackBar(
        '이미 참여 중인 채팅방이 있습니다. 한 번에 하나의 채팅방에만 참여할 수 있습니다.',
        isError: true,
      );
      return;
    }

    if (_selectedPosition != null) {
      _navigateToChatCreatePage();
    } else {
      _showCreateChatRoomDialog();
    }
  }

  void _showCreateChatRoomDialog() {
    if (!mounted) return;
    _isCreatingChatRoom = true;
    _showSnackBar('생성할 위치를 지정해주세요!');
  }

  void _navigateToChatCreatePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatCreatePage(),
      ),
    ).then((_) {
      // ChatCreatePage에서 돌아온 후 임시 마커 제거
      _removeTemporaryMarker();
    });
  }

  void _showCreateChatRoomAtLocationDialog(LatLng position) {
    if (!mounted) return;
    _navigateToChatCreatePage();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _chatListOverlay?.remove();
    _infoWindowOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _currentPosition != null
        ? CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          )
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
                      color: themeProvider.isDarkMode
                          ? Colors.green[600]
                          : const Color(0xFF00E676),
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
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
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
              _buildGoogleMap(initialPosition, themeProvider),
              Positioned(
                bottom: 80,
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
                        onTap: _onNewChatRoomButtonTap,
                        splashColor: const Color(0x33FFFFFF),
                        highlightColor: const Color(0x22FFFFFF),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: themeProvider.isDarkMode
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : Colors.white,
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

  Widget _buildGoogleMap(CameraPosition initialPosition, AppThemeProvider themeProvider) {
    return FutureBuilder<List<ChatRoom>>(
      future: _cachedChatRooms != null ? Future.value(_cachedChatRooms) : _loadNearbyChatRooms().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _cachedChatRooms == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && _cachedChatRooms == null) {
          _cachedChatRooms = snapshot.data;
          if (_cachedChatRooms != null) {
            for (var chatRoom in _cachedChatRooms!) {
              _addChatRoomMarker(chatRoom);
            }
          }
        }

        if (snapshot.hasError) {
          return Center(child: Text('채팅방 로드 실패: ${snapshot.error}'));
        }

        return GoogleMap(
          initialCameraPosition: initialPosition,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          compassEnabled: false,
          onMapCreated: (controller) {
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
            }
          },
          onTap: (position) {
            _infoWindowOverlay?.remove();
            _infoWindowOverlay = null;
            if (_isCreatingChatRoom) {
              _addTemporaryMarker(position);
            }
          },
          style: themeProvider.isDarkMode ? _customDarkMapStyle : themeProvider.lightMapStyle,
          liteModeEnabled: false,
        );
      },
    );
  }

  final String _customDarkMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#242f3e"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#ffffff"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
    {"featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [{"color": "#d0d0ff"}]},
    {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#b4e0b4"}]},
    {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#263c3f"}]},
    {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#6cff6c"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#38414e"}]},
    {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
    {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#c5c5ff"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#505ea1"}]},
    {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#1f2835"}]},
    {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#f2f2ff"}]},
    {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]},
    {"featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [{"color": "#e0e0ff"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]},
    {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#80dfff"}]}
  ]
  ''';
}