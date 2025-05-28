import 'package:geolocator/geolocator.dart';
import 'package:with_run_app/features/map/domain/repository/location_repository.dart';

class GetPositionUseCase {
  final LocationRepository _locationRepository;

  GetPositionUseCase(this._locationRepository);

  Future<Position?> execute() async {
    return await _locationRepository.getPosition();
  }
}
