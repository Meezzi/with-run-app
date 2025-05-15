import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/features/chat/data/chat_room.dart';
import 'package:with_run_app/features/chat/data/chat_service.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';

// 맵에 표시될 채팅방 마커를 클릭했을 때의 콜백 함수 타입
typedef OnChatRoomMarkerTapCallback = void Function(ChatRoom chatRoom);
typedef OnTemporaryMarkerTapCallback = void Function(LatLng position);

class MapState {
  final Completer<GoogleMapController> mapController;
  final Set<Marker> markers;
  final List<ChatRoom> nearbyRooms;
  final LatLng? selectedPosition;
  final bool isCreatingChatRoom;
  
  MapState({
    Completer<GoogleMapController>? mapController,
    Set<Marker>? markers,
    List<ChatRoom>? nearbyRooms,
    this.selectedPosition,
    this.isCreatingChatRoom = false,
  }) : 
    mapController = mapController ?? Completer<GoogleMapController>(),
    markers = markers ?? {},
    nearbyRooms = nearbyRooms ?? [];

  MapState copyWith({
    Set<Marker>? markers,
    List<ChatRoom>? nearbyRooms,
    LatLng? selectedPosition,
    bool? isCreatingChatRoom,
  }) {
    return MapState(
      mapController: mapController,
      markers: markers ?? this.markers,
      nearbyRooms: nearbyRooms ?? this.nearbyRooms,
      selectedPosition: selectedPosition,
      isCreatingChatRoom: isCreatingChatRoom ?? this.isCreatingChatRoom,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final ChatService _chatService = ChatService();
  final Ref _ref;
  OnChatRoomMarkerTapCallback? _onChatRoomMarkerTap;
  OnTemporaryMarkerTapCallback? _onTemporaryMarkerTap;

  MapNotifier(this._ref) : super(MapState()) {
    _listenToLocationChanges();
  }

  void setOnChatRoomMarkerTapCallback(OnChatRoomMarkerTapCallback callback) {
    _onChatRoomMarkerTap = callback;
  }

  void setOnTemporaryMarkerTapCallback(OnTemporaryMarkerTapCallback callback) {
    _onTemporaryMarkerTap = callback;
  }

  void _listenToLocationChanges() {
    _ref.listen(locationProvider, (previous, next) {
      if (next.currentPosition != null && 
          (previous?.currentPosition == null || 
           previous!.currentPosition!.latitude != next.currentPosition!.latitude ||
           previous.currentPosition!.longitude != next.currentPosition!.longitude)) {
        _updateCurrentLocationMarker();
        loadNearbyChatRooms();
      }
    });
  }

  // 현재 위치 마커 업데이트
  void _updateCurrentLocationMarker() {
    final locationState = _ref.read(locationProvider);
    if (locationState.currentPosition == null) return;

    final currentPosition = locationState.currentPosition!;
    final currentMarkers = Set<Marker>.from(state.markers);
    
    // 기존 내 위치 마커 제거
    currentMarkers.removeWhere(
      (marker) => marker.markerId == const MarkerId('myLocation'),
    );
    
    // 새 내 위치 마커 추가
    currentMarkers.add(
      Marker(
        markerId: const MarkerId('myLocation'),
        position: LatLng(
          currentPosition.latitude,
          currentPosition.longitude,
        ),
        infoWindow: const InfoWindow(title: '내 위치'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    
    state = state.copyWith(markers: currentMarkers);
  }

  // 주변 채팅방 로드
  Future<void> loadNearbyChatRooms() async {
    final locationState = _ref.read(locationProvider);
    if (locationState.currentPosition == null) return;

    final currentPosition = locationState.currentPosition!;
    
    try {
      final rooms = await _chatService.getNearbyRooms(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
      ).first;
      
      final currentMarkers = Set<Marker>.from(state.markers);
      
      // 기존 채팅방 마커 제거
      currentMarkers.removeWhere(
        (marker) => marker.markerId.value.startsWith('chatRoom_'),
      );
      
      // 새 채팅방 마커 추가
      for (var room in rooms) {
        currentMarkers.add(
          Marker(
            markerId: MarkerId('chatRoom_${room.id}'),
            position: LatLng(room.latitude, room.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
            onTap: () {
              onChatRoomMarkerTap(room);
            },
          ),
        );
      }
      
      state = state.copyWith(
        markers: currentMarkers,
        nearbyRooms: rooms,
      );
    } catch (e) {
      debugPrint('주변 채팅방 로드 오류: $e');
    }
  }

  // 채팅방 마커 탭 처리
  void onChatRoomMarkerTap(ChatRoom room) {
    debugPrint('마커 클릭됨: chatRoom_${room.id}');
    if (_onChatRoomMarkerTap != null) {
      _onChatRoomMarkerTap!(room);
    }
  }

  // 임시 마커 탭 처리
  void onTemporaryMarkerTap(LatLng position) {
    debugPrint('임시 마커 클릭됨: $position');
    if (_onTemporaryMarkerTap != null) {
      _onTemporaryMarkerTap!(position);
    }
  }

  // 맵 컨트롤러 설정
  void setMapController(GoogleMapController controller) {
    if (!state.mapController.isCompleted) {
      state.mapController.complete(controller);
    }
  }

  // 현재 위치로 카메라 이동
  Future<void> moveToCurrentLocation() async {
    final locationState = _ref.read(locationProvider);
    if (locationState.currentPosition == null || !state.mapController.isCompleted) return;
    
    final controller = await state.mapController.future;
    final currentPosition = locationState.currentPosition!;
    
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentPosition.latitude,
              currentPosition.longitude,
            ),
            zoom: 15.0,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Failed to animate camera: $e");
    }
  }

  // 임시 마커 추가 (채팅방 생성 위치)
  void addTemporaryMarker(LatLng position) {
    final currentMarkers = Set<Marker>.from(state.markers);
    const markerId = MarkerId('temporaryMarker');
    
    // 기존 임시 마커 제거
    currentMarkers.removeWhere((marker) => marker.markerId == markerId);
    
    // 새 임시 마커 추가 - 탭 이벤트 추가
    currentMarkers.add(
      Marker(
        markerId: markerId,
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '새 채팅방 위치'),
        onTap: () => onTemporaryMarkerTap(position),
      ),
    );
    
    state = state.copyWith(
      markers: currentMarkers,
      selectedPosition: position,
    );
    
    // 마커를 추가한 후 카메라 이동
    if (state.mapController.isCompleted) {
      state.mapController.future.then((controller) {
        controller.animateCamera(CameraUpdate.newLatLng(position));
      });
    }
  }

  // 임시 마커 제거
  void removeTemporaryMarker() {
    final currentMarkers = Set<Marker>.from(state.markers);
    currentMarkers.removeWhere(
      (marker) => marker.markerId == const MarkerId('temporaryMarker'),
    );
    
    state = state.copyWith(
      markers: currentMarkers,
      selectedPosition: null,
    );
  }

  // 채팅방 생성 모드 설정
  void setCreatingChatRoom(bool isCreating) {
    state = state.copyWith(isCreatingChatRoom: isCreating);
  }

  // 지도 탭 처리
  void onMapTap(LatLng position) {
    if (state.isCreatingChatRoom) {
      addTemporaryMarker(position);
    }
  }

  // 채팅방 삭제 후 맵 새로고침
  Future<void> refreshMapAfterRoomDeletion(String roomId) async {
    final currentMarkers = Set<Marker>.from(state.markers);
    
    // 삭제된 채팅방 마커 제거
    currentMarkers.removeWhere(
      (marker) => marker.markerId == MarkerId('chatRoom_$roomId'),
    );
    
    final nearbyRoomsUpdated = List<ChatRoom>.from(state.nearbyRooms)
      ..removeWhere((room) => room.id == roomId);
    
    state = state.copyWith(
      markers: currentMarkers,
      nearbyRooms: nearbyRoomsUpdated,
    );
    
    // 주변 채팅방 다시 로드
    await loadNearbyChatRooms();
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref);
});