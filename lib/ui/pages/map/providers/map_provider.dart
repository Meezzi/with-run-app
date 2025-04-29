import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';

// 맵에 표시될 채팅방 마커를 클릭했을 때의 콜백 함수 타입
typedef OnChatRoomMarkerTapCallback = void Function(String chatRoomId);
typedef OnTemporaryMarkerTapCallback = void Function(LatLng position);

class MapState {
  final Completer<GoogleMapController> mapController;
  final Set<Marker> markers;
  final LatLng? selectedPosition;
  final bool isCreatingChatRoom;
  
  MapState({
    Completer<GoogleMapController>? mapController,
    Set<Marker>? markers,
    this.selectedPosition,
    this.isCreatingChatRoom = false,
  }) : 
    mapController = mapController ?? Completer<GoogleMapController>(),
    markers = markers ?? {};

  MapState copyWith({
    Set<Marker>? markers,
    LatLng? selectedPosition,
    bool? isCreatingChatRoom,
  }) {
    return MapState(
      mapController: mapController,
      markers: markers ?? this.markers,
      selectedPosition: selectedPosition,
      isCreatingChatRoom: isCreatingChatRoom ?? this.isCreatingChatRoom,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final Ref _ref;
  OnChatRoomMarkerTapCallback? _onChatRoomMarkerTap;
  OnTemporaryMarkerTapCallback? _onTemporaryMarkerTap;

  MapNotifier(this._ref) : super(MapState()) {
    _listenToLocationChanges();
  }

  void setOnChatRoomMarkerTapCallback(OnChatRoomMarkerTapCallback callback) {
    _onChatRoomMarkerTap = callback;
    // 기존 마커들에 대한 콜백도 업데이트
    _updateMarkerCallbacks();
  }

  void setOnTemporaryMarkerTapCallback(OnTemporaryMarkerTapCallback callback) {
    _onTemporaryMarkerTap = callback;
    // 임시 마커가 있다면 업데이트
    _updateMarkerCallbacks();
  }

  void _listenToLocationChanges() {
    _ref.listen(locationProvider, (previous, next) {
      if (next.currentPosition != null && 
          (previous?.currentPosition == null || 
           previous!.currentPosition!.latitude != next.currentPosition!.latitude ||
           previous.currentPosition!.longitude != next.currentPosition!.longitude)) {
        _updateCurrentLocationMarker();
        refreshMap();
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
  
  // 마커 콜백 업데이트
  void _updateMarkerCallbacks() {
    final currentMarkers = Set<Marker>.from(state.markers);
    
    // 채팅방 마커 업데이트
    final updatedMarkers = currentMarkers.map((marker) {
      // 채팅방 마커인 경우 콜백 업데이트
      if (marker.markerId.value.startsWith('chatRoom_')) {
        final chatRoomId = marker.markerId.value.substring('chatRoom_'.length);
        return marker.copyWith(
          onTapParam: () {
            debugPrint('마커 클릭됨: ${marker.markerId.value}');
            if (_onChatRoomMarkerTap != null) {
              _onChatRoomMarkerTap!(chatRoomId);
            }
          }
        );
      }
      // 임시 마커인 경우 콜백 업데이트
      else if (marker.markerId == const MarkerId('temporaryMarker') && state.selectedPosition != null) {
        return marker.copyWith(
          onTapParam: () {
            debugPrint('임시 마커 클릭됨: ${state.selectedPosition}');
            if (_onTemporaryMarkerTap != null && state.selectedPosition != null) {
              _onTemporaryMarkerTap!(state.selectedPosition!);
            }
          }
        );
      }
      return marker;
    }).toSet();
    
    state = state.copyWith(markers: updatedMarkers);
  }
  
  // 임시 마커 업데이트
  void _updateTemporaryMarker() {
    if (state.selectedPosition == null) return;
    
    final currentMarkers = Set<Marker>.from(state.markers);
    const markerId = MarkerId('temporaryMarker');
    
    // 기존 임시 마커 제거
    currentMarkers.removeWhere((marker) => marker.markerId == markerId);
    
    // 새 임시 마커 추가
    final position = state.selectedPosition!;
    currentMarkers.add(
      Marker(
        markerId: markerId,
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: '새 채팅방 위치'),
        onTap: () {
          debugPrint('임시 마커 클릭됨: $position');
          if (_onTemporaryMarkerTap != null) {
            _onTemporaryMarkerTap!(position);
          }
        },
      ),
    );
    
    state = state.copyWith(markers: currentMarkers);
  }

  // Firestore에서 채팅방 로드
  Future<void> refreshMap() async {
    try {
      // 채팅방 생성 모드 상태 저장
      final isCreatingChatRoom = state.isCreatingChatRoom;
      final selectedPosition = state.selectedPosition;
      
      final snapshot = await FirebaseFirestore.instance.collection('chatRooms').get();
      final currentMarkers = Set<Marker>.from(state.markers);
      
      // 기존 채팅방 마커 제거
      currentMarkers.removeWhere(
        (marker) => marker.markerId.value.startsWith('chatRoom_'),
      );
      
      // 새 채팅방 마커 추가
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('location')) {
          final location = data['location'] as GeoPoint;
          
          // 마커 ID를 채팅방 ID로 설정
          final markerId = MarkerId('chatRoom_${doc.id}');
          
          // 기존 마커 업데이트 또는 새 마커 추가
          currentMarkers.add(
            Marker(
              markerId: markerId,
              position: LatLng(location.latitude, location.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              onTap: () {
                debugPrint('마커 클릭됨: chatRoom_${doc.id}');
                if (_onChatRoomMarkerTap != null) {
                  _onChatRoomMarkerTap!(doc.id);
                }
              },
            ),
          );
        }
      }
      
      // 상태 업데이트
      state = state.copyWith(markers: currentMarkers);
      
      // 임시 마커 유지
      if (selectedPosition != null && isCreatingChatRoom) {
        addTemporaryMarker(selectedPosition);
      }
    } catch (e) {
      debugPrint('채팅방 로드 오류: $e');
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
        onTap: () {
          debugPrint('임시 마커 클릭됨: $position');
          if (_onTemporaryMarkerTap != null) {
            _onTemporaryMarkerTap!(position);
          }
        },
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
      isCreatingChatRoom: false,  // 임시 마커 제거 시 생성 모드도 비활성화
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
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref);
});