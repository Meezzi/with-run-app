import 'package:geolocator/geolocator.dart';

abstract interface class LocationDataSource {
  Future<Position?> getPosition();
}
