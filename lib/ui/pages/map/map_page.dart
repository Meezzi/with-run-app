import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:with_run_app/ui/pages/map/providers/location_provider.dart';
import 'package:with_run_app/ui/pages/map/providers/map_provider.dart';
import 'package:with_run_app/ui/pages/map/theme_provider.dart';
import 'package:with_run_app/ui/pages/setting/setting_page.dart';
import 'package:with_run_app/ui/pages/map/viewmodels/map_viewmodel.dart';
import 'package:provider/provider.dart' as provider;

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(mapViewModelProvider.notifier).initialize(context);
      }
    });
  }

  @override
  void dispose() {
    ref.read(mapViewModelProvider.notifier).dispose();
    super.dispose();
  }

  Widget _buildAppTitle(AppThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () => themeProvider.toggleTheme(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                color: themeProvider.isDarkMode
                    ? Colors.black
                    : const Color(0xFF212121),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    final themeProvider = provider.Provider.of<AppThemeProvider>(context);
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

    final initialPosition = locationState.currentPosition != null
        ? CameraPosition(
            target: LatLng(
              locationState.currentPosition!.latitude,
              locationState.currentPosition!.longitude,
            ),
            zoom: 15,
          )
        : const CameraPosition(target: LatLng(37.5665, 126.9780), zoom: 11);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
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
              Icons.menu,
              color: themeProvider.isDarkMode
                  ? Colors.blue[600]!
                  : const Color(0xFF2196F3),
            ),
            tooltip: '설정',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingPage()),
              );
            },
          ),
        ),
        title: _buildAppTitle(themeProvider),
        centerTitle: true,
        actions: [
          _buildActionButton(
            icon: Icons.my_location,
            iconColor: themeProvider.isDarkMode
                ? Colors.blue[600]!
                : const Color(0xFF2196F3),
            onPressed: () =>
                ref.read(mapViewModelProvider.notifier).moveToCurrentLocation(context),
            tooltip: '내 위치로 이동',
          ),
          _buildActionButton(
            icon: Icons.forum_outlined,
            iconColor: themeProvider.isDarkMode
                ? Colors.blue[600]!
                : const Color(0xFF2196F3),
            onPressed: () =>
                ref.read(mapViewModelProvider.notifier).showChatListOverlay(context),
            tooltip: '채팅 목록',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialPosition,
            markers: mapState.markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            compassEnabled: false,
            onMapCreated: (controller) =>
                ref.read(mapProvider.notifier).setMapController(controller),
            onTap: (position) {
              if (mapState.isCreatingChatRoom) {
                ref.read(mapProvider.notifier).onMapTap(position);
              }
            },
            mapType: MapType.normal,
            liteModeEnabled: false,
            style: themeProvider.isDarkMode
                ? themeProvider.darkMapStyle
                : themeProvider.lightMapStyle,
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 240,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: themeProvider.isDarkMode
                        ? [Colors.blue[400]!, Colors.green[400]!]
                        : [const Color(0xFF2196F3), const Color(0xFF00E676)],
                  ),
                  borderRadius: const BorderRadius.all(Radius.circular(30)),
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
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => ref
                        .read(mapViewModelProvider.notifier)
                        .startChatRoomCreationMode(context),
                    splashColor: const Color(0x33FFFFFF),
                    highlightColor: const Color(0x22FFFFFF),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 16,
                          child: Icon(
                            Icons.add_comment_outlined,
                            color: themeProvider.isDarkMode
                                ? Colors.green[600]
                                : const Color(0xFF2196F3),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '새 채팅방 만들기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
  }
}