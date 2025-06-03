import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// TODO : 파이어베이스에서 가져오기
class ChatRoom {
  final String id;
  final String? address;
  final String title;
  final String description;
  final DateTime createdAt;
  final int memberCount;
  final double lat;
  final double lng;

  const ChatRoom({
    required this.id,
    required this.address,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.memberCount,
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
        address: '',
        title: '우리랑 뛸 사람',
        description: '친목 도모',
        createdAt: DateTime.now().subtract(Duration(days: 365)),
        memberCount: 1,
        lat: 37.354689,
        lng: 126.723354,
      ),
      ChatRoom(
        id: '2',
        address: '',
        title: '션보다 잘 뛴다',
        description: '기부 도모',
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        memberCount: 1,
        lat: 37.355393,
        lng: 126.722420,
      ),
    ];

    state = state.copyWith(chatRooms: dummy);
  }

  void addMarker(NaverMapController controller, NLatLng latLng) {
    final seletedPos = NMarker(
      // TODO : uid로 변경하기
      id: "test",
      position: NLatLng(latLng.latitude, latLng.longitude),
    );
    controller.addOverlay(seletedPos);

    // 지도에 표시된 마커의 정보창 표시하기
    final onMarkerInfoWindow = NInfoWindow.onMarker(
      id: seletedPos.info.id,
      text: "이 위치에서 채팅방을 만드시려면 마커를 터치해주세요",
    );
    // 지도에 추가된 마커에만 정보창을 띄움
    seletedPos.openInfoWindow(onMarkerInfoWindow);

    // 마커 클릭 이벤트
    seletedPos.setOnTapListener((NMarker marker) {
      // TODO : marker.id == uid 로 조건문 만들어 페이지 라우팅하기
    });
  }
}
