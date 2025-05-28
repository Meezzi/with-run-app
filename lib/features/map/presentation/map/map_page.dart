import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/map/presentation/map/widgets/map_bottom_sheet.dart';
import 'package:with_run_app/features/map/presentation/map/widgets/zoom_buttons.dart';
import 'package:with_run_app/features/map/provider.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  NaverMapController? mapController;

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapViewModelProvider);
    final mapVm = ref.read(mapViewModelProvider.notifier);

    print(mapState.chatRooms);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mapController != null) {
        final chatRooms = mapState.chatRooms;
        Set<NMarker> overlays = {};

        for (final room in chatRooms) {
          final marker = NMarker(
            id: room.id,
            position: NLatLng(room.lat, room.lng),
          );

          overlays.add(marker);

          marker.setOnTapListener((overlay) {
            showModalBottomSheet(
              context: context,
              isDismissible: true,
              builder: (context) {
                return MapBottomSheet(room);
              },
            );
          });
        }

        mapController?.addOverlayAll(overlays);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(locationButtonEnable: true),
            onMapReady: (controller) async {
              mapController = controller;
            },
            onMapTapped: (NPoint point, NLatLng latLng) async {
              mapVm.markCurrentPosition(mapController!, latLng);
            },
          ),
          ZoomButtons(mapController: mapController),
        ],
      ),
    );
  }
}
