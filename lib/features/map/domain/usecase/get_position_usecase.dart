import 'package:geolocator/geolocator.dart';
import 'package:with_run_app/features/map/domain/repository/location_repository.dart';

class GetPositionUsecase {
  final LocationRepository _locationRepository;

  GetPositionUsecase(this._locationRepository);

  Future<Position?> execute() async {
    return await _locationRepository.getPosition();
  }
}
