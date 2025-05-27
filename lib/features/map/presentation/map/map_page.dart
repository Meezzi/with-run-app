import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/map/presentation/map/map_view_model.dart';

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
      body: NaverMap(
        options: NaverMapViewOptions(),
        onMapReady: (controller) async {
          mapController = controller;

          mapVm.moveMyPosition(mapController!, context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (mapController == null) return;
          mapVm.moveMyPosition(mapController!, context);
        },
        child: Icon(Icons.gps_fixed),
      ),
    );
  }
}
