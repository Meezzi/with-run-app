import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:with_run_app/features/map/provider.dart';

// test
class ChatRoom {
  final String id;
  final String title;
  final String description;
  final double lat;
  final double lng;

  const ChatRoom({
    required this.id,
    required this.title,
    required this.description,
    required this.lat,
    required this.lng,
  });
}

final chatRoomProvider = Provider((ref) {
  return ChatRoom;
});

class MapState {
  List<ChatRoom> chatRooms;
  Position? currentPosition;

  MapState({required this.chatRooms, required this.currentPosition});

  MapState copyWith({
    String? id,
    List<ChatRoom>? chatRooms,
    Position? currentPosition,
  }) {
    return MapState(
      chatRooms: chatRooms ?? this.chatRooms,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}

class MapViewModel extends Notifier<MapState> {
  @override
  build() {
    fetchChatRooms();
    return MapState(chatRooms: [], currentPosition: null);
  }

  void fetchChatRooms() async {
    await Future.delayed(Duration(seconds: 1));
    final dummy = [
      ChatRoom(
        id: '1',
        title: '우리랑 뛸 사람',
        description: '친목 도모',
        lat: 37.354689,
        lng: 126.723354,
      ),
      ChatRoom(
        id: '2',
        title: '션보다 잘 뛴다',
        description: '기부 도모',
        lat: 37.355393,
        lng: 126.722420,
      ),
    ];

    state = state.copyWith(chatRooms: dummy);
  }

  Future<Position?> getPosition() async {
    final getPositionUsecase = ref.read(getPositionUsecaseProvider);
    state = state.copyWith(currentPosition: await getPositionUsecase.execute());
    return state.currentPosition;
  }

  Future<bool> moveMyPosition(NaverMapController controller) async {
    try {
      final pos = await getPosition();
      if (pos == null) return false;

      // 카메라 이동이 완료되면 false.
      // true는 카메라 이동이 실패 했을 경우.
      final isMoved = await controller.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(pos.latitude, pos.longitude),
          zoom: 15,
        ),
      );

      if (!isMoved) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
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
