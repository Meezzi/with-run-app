import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/map/data/data_source/location_data_source.dart';
import 'package:with_run_app/features/map/data/data_source/location_data_source.impl.dart';
import 'package:with_run_app/features/map/data/repository/location_repository_impl.dart';
import 'package:with_run_app/features/map/domain/repository/location_repository.dart';
import 'package:with_run_app/features/map/domain/usecase/get_position_usecase.dart';

final _locationDataSourceProvider = Provider<LocationDataSource>((ref) {
  return LocationDataSourceImpl();
});

final _locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final dataSource = ref.read(_locationDataSourceProvider);
  return LocationRepositoryImpl(dataSource);
});

final getPositionUsecaseProvider = Provider((ref) {
  final repository = ref.read(_locationRepositoryProvider);
  return GetPositionUsecase(repository);
});
