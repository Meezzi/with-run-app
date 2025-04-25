import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:provider/provider.dart' as provider;

class LocationButton extends ConsumerWidget {
  final Function(String, {bool isError}) onShowSnackBar;

  const LocationButton({
    super.key,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);
    final locationState = ref.watch(locationProvider);

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
        icon: Icon(
          Icons.my_location,
          color: themeProvider.isDarkMode
              ? Colors.blue[600]
              : const Color(0xFF2196F3),
        ),
        tooltip: '내 위치로 이동',
        onPressed: () async {
          if (locationState.currentPosition != null) {
            ref.read(mapProvider.notifier).moveToCurrentLocation();
          } else if (locationState.error != null) {
            onShowSnackBar(locationState.error!, isError: true);
          } else {
            onShowSnackBar("위치 정보를 가져오는 중입니다...");
            await ref.read(locationProvider.notifier).refreshLocation();
          }
        },
      ),
    );
  }
}