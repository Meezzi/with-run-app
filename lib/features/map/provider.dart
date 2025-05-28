import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:with_run_app/features/map/data/data_source/location_data_source.dart';
import 'package:with_run_app/features/map/data/data_source/geolocator_location_data_source_impl.dart';
import 'package:with_run_app/features/map/data/repository/geolocator_location_repository_impl.dart';
import 'package:with_run_app/features/map/domain/repository/location_repository.dart';
import 'package:with_run_app/features/map/domain/usecase/get_position_usecase.dart';
import 'package:with_run_app/features/map/presentation/map/map_view_model.dart';

final _locationDataSourceProvider = Provider<LocationDataSource>((ref) {
  return GeolocatorLocationDataSourceImpl();
});

final _locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final dataSource = ref.read(_locationDataSourceProvider);
  return GeolocatorLocationRepositoryImpl(dataSource);
});

final getPositionUsecaseProvider = Provider((ref) {
  final repository = ref.read(_locationRepositoryProvider);
  return GetPositionUseCase(repository);
});

final mapViewModelProvider = NotifierProvider<MapViewModel, Position?>(() {
  return MapViewModel();
});
