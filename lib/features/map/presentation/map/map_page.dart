import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:with_run_app/features/map/presentation/map/map_view_model.dart';
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
  void initState() {
    super.initState();
    _permission();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapViewModelProvider);
    final mapVm = ref.read(mapViewModelProvider.notifier);

    _showChatRoomMarkers(mapState);

    return Scaffold(
      body: Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(locationButtonEnable: true),
            onMapReady: (controller) async {
              mapController = controller;
            },
            onMapTapped: (NPoint point, NLatLng latLng) async {
              mapVm.addMarker(mapController!, latLng);
            },
            onCameraIdle: () {
              // TODO : 서버에 데이터 쌓이면 아래 함수 테스트 해보기
              // _showChatRoomMarkers(mapState);
            },
          ),
          ZoomButtons(mapController: mapController),
        ],
      ),
    );
  }

  void _permission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;
    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  // TODO : StreamBuilder 위젯으로 변경 가능성 있음
  void _showChatRoomMarkers(MapState mapState) {
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
  }
}
