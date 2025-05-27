import 'package:geolocator/geolocator.dart';
import 'package:with_run_app/features/map/data/data_source/location_data_source.dart';
import 'package:with_run_app/features/map/domain/repository/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _locationDataSource;

  LocationRepositoryImpl(this._locationDataSource);

  @override
  Future<Position?> getPosition() async {
    return await _locationDataSource.getPosition();
  }
}
