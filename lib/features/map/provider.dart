import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/features/map/presentation/map/map_view_model.dart';

final mapViewModelProvider = NotifierProvider<MapViewModel, MapState>(() {
  return MapViewModel();
});
