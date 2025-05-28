import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(locationButtonEnable: true),
            onMapReady: (controller) async {
              mapController = controller;

              final isMoved = await mapVm.moveMyPosition(mapController!);

              if (context.mounted) {
                if (isMoved) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '현재 위치로 이동했습니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '현재 위치를 찾지 못했습니다',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
              }
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
