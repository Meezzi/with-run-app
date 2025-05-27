import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:with_run_app/features/map/provider.dart';

class MapViewModel extends Notifier<Position?> {
  @override
  build() {
    return null;
  }

  Future<Position?> getPosition() async {
    final getPositionUsecase = ref.read(getPositionUsecaseProvider);
    state = await getPositionUsecase.execute();
    return state;
  }

  void moveMyPosition(
    NaverMapController controller,
    BuildContext context,
  ) async {
    try {
      final pos = await getPosition();
      if (pos == null) return;

      // 카메라 이동이 완료되면 false.
      // true는 카메라 이동이 실패 했을 경우.
      final isMoved = await controller.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(pos.latitude, pos.longitude),
          zoom: 15,
        ),
      );
      final myPosMaker = NMarker(
        id: "test",
        position: NLatLng(pos.latitude, pos.longitude),
      );

      controller.addOverlay(myPosMaker);

      print(isMoved);
      if (context.mounted) {
        if (!isMoved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '현재 위치로 이동했습니다',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.fixed,
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
  }
}

final mapViewModelProvider = NotifierProvider<MapViewModel, Position?>(() {
  return MapViewModel();
});
