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

  void markCurrentPosition(NaverMapController controller, NLatLng latLng) {
    final seletedPos = NMarker(
      // TODO : uid로 변경하기
      id: "test",
      position: NLatLng(latLng.latitude, latLng.longitude),
    );
    controller.addOverlay(seletedPos);

    // ✅ 지도에 표시된 마커의 정보창 표시하기
    final onMarkerInfoWindow = NInfoWindow.onMarker(
      id: seletedPos.info.id,
      text: "이 위치에서 채팅방을 만드시려면 마커를 터치해주세요",
    );
    // 지도에 추가된 마커에만 정보창을 띄움
    seletedPos.openInfoWindow(onMarkerInfoWindow);

    // 마커 클릭 이벤트
    seletedPos.setOnTapListener((NMarker marker) {
      // TODO : marker.id == uid 로 조건문 만들어 페이지 라우팅하기
      print('✅ 네비게이터');
    });
  }
}

final mapViewModelProvider = NotifierProvider<MapViewModel, Position?>(() {
  return MapViewModel();
});
