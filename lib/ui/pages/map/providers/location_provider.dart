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
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoading: false,
          error: '위치 서비스를 활성화해주세요.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
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

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      state = state.copyWith(
        currentPosition: position,
        isLoading: false,
        error: null,
      );

      // 위치 변경 스트림 시작
      _startPositionStream();
    } catch (e) {
      debugPrint('위치 가져오기 오류: $e');
      state = state.copyWith(
        isLoading: false,
        error: '위치 정보를 가져오는데 실패했습니다.',
      );
    }
  }

  void _startPositionStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      state = state.copyWith(
        currentPosition: position,
        isLoading: false,
        error: null,
      );
    });
  }

  // 위치 정보 새로고침
  Future<void> refreshLocation() async {
    state = state.copyWith(isLoading: true);
    await _getCurrentLocation();
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});