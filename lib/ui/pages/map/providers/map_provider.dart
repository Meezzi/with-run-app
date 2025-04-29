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
  final bool isRefreshing; // 새로고침 상태 추가
  
  MapState({
    Completer<GoogleMapController>? mapController,
    Set<Marker>? markers,
    this.selectedPosition,
    this.isCreatingChatRoom = false,
    this.isRefreshing = false, // 초기값은 false
  }) : 
    mapController = mapController ?? Completer<GoogleMapController>(),
    markers = markers ?? {};

  MapState copyWith({
    Set<Marker>? markers,
    LatLng? selectedPosition,
    bool? isCreatingChatRoom,
    bool? isRefreshing,
  }) {
    return MapState(
      mapController: mapController,
      markers: markers ?? this.markers,
      selectedPosition: selectedPosition,
      isCreatingChatRoom: isCreatingChatRoom ?? this.isCreatingChatRoom,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  final Ref _ref;
  OnChatRoomMarkerTapCallback? _onChatRoomMarkerTap;
  OnTemporaryMarkerTapCallback? _onTemporaryMarkerTap;
  bool _isRefreshing = false; // 새로고침 중복 방지를 위한 플래그

  MapNotifier(this._ref) : super(MapState(isCreatingChatRoom: false, selectedPosition: null)) {
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
    Set<Marker> updatedMarkers = {};
    
    // 모든 마커를 새로 생성하여 콜백 적용
    for (var marker in currentMarkers) {
      if (marker.markerId.value.startsWith('chatRoom_')) {
        // 채팅방 마커 처리
        final chatRoomId = marker.markerId.value.substring('chatRoom_'.length);
        updatedMarkers.add(
          Marker(
            markerId: marker.markerId,
            position: marker.position,
            icon: marker.icon,
            infoWindow: marker.infoWindow,
            onTap: _onChatRoomMarkerTap != null 
                ? () => _onChatRoomMarkerTap!(chatRoomId)
                : null,
          ),
        );
      } else if (marker.markerId == const MarkerId('temporaryMarker')) {
        // 임시 마커(녹색 마커) 처리
        updatedMarkers.add(
          Marker(
            markerId: marker.markerId,
            position: marker.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: '새 채팅방 위치'),
            onTap: _onTemporaryMarkerTap != null 
                ? () => _onTemporaryMarkerTap!(marker.position)
                : null,
          ),
        );
      } else {
        // 기타 마커는 그대로 유지
        updatedMarkers.add(marker);
      }
    }
    
    state = state.copyWith(markers: updatedMarkers);
  }

  // Firestore에서 채팅방 로드
  Future<void> refreshMap() async {
    // 이미 새로고침 중이면 중복 실행 방지
    if (_isRefreshing) return;
    
    try {
      _isRefreshing = true;
      // 새로고침 시작 상태로 변경
      state = state.copyWith(isRefreshing: true);
      
      // 채팅방 생성 모드 상태와 선택된 위치 저장
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
                if (_onChatRoomMarkerTap != null) {
                  _onChatRoomMarkerTap!(doc.id);
                }
              },
            ),
          );
        }
      }
      
      // 상태 업데이트
      state = state.copyWith(
        markers: currentMarkers, 
        isRefreshing: false, // 새로고침 완료
        isCreatingChatRoom: isCreatingChatRoom, // 채팅방 생성 모드 유지
        selectedPosition: selectedPosition // 선택된 위치 유지
      );
      
      // 임시 마커 유지
      if (selectedPosition != null && isCreatingChatRoom) {
        debugPrint('리프레시 후 임시 마커 복원: $selectedPosition');
        _addTemporaryMarkerWithoutStateChange(selectedPosition, currentMarkers);
      }
      
      // 마커 콜백 업데이트
      _updateMarkerCallbacks();
    } catch (e) {
      debugPrint('채팅방 로드 오류: $e');
      // 오류 발생 시에도 새로고침 상태 해제
      state = state.copyWith(isRefreshing: false);
    } finally {
      _isRefreshing = false;
    }
  }

  // 상태 변경 없이 임시 마커만 추가하는 내부 메서드 (refreshMap에서 사용)
  void _addTemporaryMarkerWithoutStateChange(LatLng position, Set<Marker> markers) {
    const markerId = MarkerId('temporaryMarker');
    
    // 기존 임시 마커 제거
    markers.removeWhere((marker) => marker.markerId == markerId);
    
    // 새 임시 마커 추가 - 탭 이벤트 추가
    markers.add(
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
    if (locationState.currentPosition == null || !state.mapController.isCompleted) {
      debugPrint('위치 이동 불가: 위치=${locationState.currentPosition}, 컨트롤러=${state.mapController.isCompleted}');
      return;
    }
    
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
      debugPrint('카메라 이동 성공: ${currentPosition.latitude}, ${currentPosition.longitude}');
    } catch (e) {
      debugPrint("카메라 이동 실패: $e");
    }
  }

  // 임시 마커 추가 (채팅방 생성 위치)
  void addTemporaryMarker(LatLng position) {
    // 위젯 생명주기 문제 방지를 위한 처리
    Future.microtask(() {
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
        isCreatingChatRoom: true,  // 임시 마커 추가 시 채팅방 생성 모드로 자동 전환
      );
      
      // 마커를 추가한 후 카메라 이동
      if (state.mapController.isCompleted) {
        state.mapController.future.then((controller) {
          controller.animateCamera(CameraUpdate.newLatLng(position));
        });
      }
      
      // 마커 콜백 업데이트
      _updateMarkerCallbacks();
      
      // 디버그 정보 출력
      debugPrint('임시 마커 추가됨: $position, 생성 모드: ${state.isCreatingChatRoom}');
    });
  }

  // 임시 마커 제거
  void removeTemporaryMarker() {
    // 위젯 생명주기 문제 방지를 위한 처리
    Future.microtask(() {
      final currentMarkers = Set<Marker>.from(state.markers);
      
      // 임시 마커가 있는지 확인
      bool hasTemporaryMarker = currentMarkers.any(
        (marker) => marker.markerId == const MarkerId('temporaryMarker'),
      );
      
      if (hasTemporaryMarker) {
        debugPrint('임시 마커 제거 중...');
        currentMarkers.removeWhere(
          (marker) => marker.markerId == const MarkerId('temporaryMarker'),
        );
        
        state = state.copyWith(
          markers: currentMarkers,
          selectedPosition: null,
          isCreatingChatRoom: false,  // 임시 마커 제거 시 생성 모드도 비활성화
        );
        
        debugPrint('임시 마커 제거 완료, 생성 모드 해제');
      } else {
        debugPrint('제거할 임시 마커 없음');
      }
    });
  }

  // 채팅방 생성 모드 설정
  void setCreatingChatRoom(bool isCreating) {
    // 위젯 생명주기 문제 방지를 위한 처리
    Future.microtask(() {
      debugPrint('채팅방 생성 모드 변경: $isCreating (이전: ${state.isCreatingChatRoom})');
      
      // 값 변경이 없으면 아무 것도 하지 않음
      if (state.isCreatingChatRoom == isCreating) {
        debugPrint('상태 변경 없음, 무시');
        return;
      }
      
      if (!isCreating) {
        // 생성 모드 해제 시 임시 마커도 함께 제거
        removeTemporaryMarker();
      } else {
        // 생성 모드만 활성화 - 마커는 사용자가 직접 선택하도록 함
        state = state.copyWith(isCreatingChatRoom: isCreating);
        debugPrint('채팅방 생성 모드 활성화: ${state.isCreatingChatRoom}');
      }
    });
  }

  // 지도 탭 처리
  void onMapTap(LatLng position) {
    if (state.isCreatingChatRoom) {
      debugPrint('맵 탭 - 위치 선택: $position');
      addTemporaryMarker(position);
    }
  }
  
  // 디버그 정보 출력
  void printDebugInfo() {
    debugPrint('---- 맵 상태 정보 ----');
    debugPrint('생성 모드: ${state.isCreatingChatRoom}');
    debugPrint('선택된 위치: ${state.selectedPosition}');
    debugPrint('마커 수: ${state.markers.length}');
    
    // 마커 유형별 개수 출력
    int temporaryMarkerCount = 0;
    int chatRoomMarkerCount = 0;
    int otherMarkerCount = 0;
    
    for (var marker in state.markers) {
      if (marker.markerId == const MarkerId('temporaryMarker')) {
        temporaryMarkerCount++;
      } else if (marker.markerId.value.startsWith('chatRoom_')) {
        chatRoomMarkerCount++;
      } else {
        otherMarkerCount++;
      }
    }
    
    debugPrint('임시 마커: $temporaryMarkerCount');
    debugPrint('채팅방 마커: $chatRoomMarkerCount');
    debugPrint('기타 마커: $otherMarkerCount');
    debugPrint('--------------------');
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier(ref);
});