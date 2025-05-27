import 'package:geolocator/geolocator.dart';
import 'package:with_run_app/features/map/data/data_source/location_data_source.dart';

class LocationDataSourceImpl implements LocationDataSource {
  @override
  Future<Position?> getPosition() async {
    final permission = await Geolocator.checkPermission();

    // 1. 현재 권한이 허용되지 않았을 때 권한 요청하기
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // 요청
      final rePermission = await Geolocator.requestPermission();

      // 2 .권한 요청 후 결과가 거부일 때 리턴하기
      if (rePermission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    // 3. Geolocator로 위치 가져와서 리턴하기
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 1000,
      ),
    );
    return position;
  }
}
