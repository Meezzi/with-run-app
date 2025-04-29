import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// 위치 정보를 담는 클래스
class LocationState {
  final Position? currentPosition;
  final bool isLoading;
  final String? error;

  LocationState({
    this.currentPosition,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    Position? currentPosition,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  LatLng? get latLng => currentPosition != null
      ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
      : null;
}

class LocationNotifier extends StateNotifier<LocationState> {
  StreamSubscription<Position>? _positionStream;

  LocationNotifier() : super(LocationState(isLoading: true)) {
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    debugPrint('위치 정보 가져오기 시작');
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('위치 서비스가 비활성화되었습니다');
        state = state.copyWith(
          isLoading: false,
          error: '위치 서비스를 활성화해주세요.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('현재 위치 권한 상태: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('위치 권한 요청 결과: $permission');
        
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoading: false,
            error: '위치 권한이 거부되었습니다.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoading: false,
          error: '위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해주세요.',
        );
        return;
      }

      // 위치 정보 로딩 중임을 표시
      state = state.copyWith(isLoading: true);
      
      // 위치 정보 가져오기
      try {
        // 장치에 적합한 설정 사용
        final LocationSettings locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );

        debugPrint('위치 정보 가져오기 성공: $position');
        state = state.copyWith(
          currentPosition: position,
          isLoading: false,
          error: null,
        );

        // 위치 변경 스트림 시작
        _startPositionStream();
      } catch (e) {
        debugPrint('정확한 위치 가져오기 실패: $e');
        
        // 최신 위치를 가져오지 못하는 경우, 마지막으로 알려진 위치라도 시도
        try {
          final lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            debugPrint('마지막 알려진 위치 사용: $lastPosition');
            state = state.copyWith(
              currentPosition: lastPosition,
              isLoading: false,
              error: null,
            );
            
            // 그래도 위치 스트림 시작
            _startPositionStream();
            return;
          }
        } catch (e2) {
          debugPrint('마지막 위치 가져오기 실패: $e2');
        }
        
        state = state.copyWith(
          isLoading: false,
          error: '위치 정보를 가져오는데 실패했습니다.',
        );
      }
    } catch (e) {
      debugPrint('위치 서비스 초기화 오류: $e');
      state = state.copyWith(
        isLoading: false,
        error: '위치 서비스 초기화 오류: $e',
      );
    }
  }

  void _startPositionStream() {
    try {
      _positionStream?.cancel();
      
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen(
        (Position position) {
          debugPrint('위치 업데이트: $position');
          state = state.copyWith(
            currentPosition: position,
            isLoading: false,
            error: null,
          );
        },
        onError: (error) {
          debugPrint('위치 스트림 에러: $error');
        },
      );
    } catch (e) {
      debugPrint('위치 스트림 시작 실패: $e');
    }
  }

  // 위치 정보 새로고침
  Future<void> refreshLocation() async {
    debugPrint('위치 정보 새로고침 요청');
    state = state.copyWith(isLoading: true);
    await _getCurrentLocation();
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});