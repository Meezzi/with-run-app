import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/map/presentation/view_models/location_provider.dart';
import 'package:with_run_app/features/map/presentation/view_models/map_provider.dart';

class LocationButtonViewModel extends StateNotifier<bool> {
  final Ref _ref;

  LocationButtonViewModel(this._ref) : super(false);

  Future<void> onLocationButtonTap(BuildContext context) async {
    final locationState = _ref.read(locationProvider);
    if (locationState.currentPosition != null) {
      _ref.read(mapProvider.notifier).moveToCurrentLocation();
    } else if (locationState.error != null) {
      _showSnackBar(context, locationState.error!, isError: true);
    } else {
      _showSnackBar(context, "위치 정보를 가져오는 중입니다...");
      await _ref.read(locationProvider.notifier).refreshLocation();
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
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
}

final locationButtonViewModelProvider =
    StateNotifierProvider<LocationButtonViewModel, bool>((ref) {
      return LocationButtonViewModel(ref);
    });
