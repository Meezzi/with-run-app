String _formatDistance(dynamic distance) {
  if (distance == null) return '0.00 km';
  final parsedDistance =
      distance is String
          ? double.tryParse(distance) ?? 0
          : (distance is num ? distance.toDouble() : 0);
  return '${parsedDistance.toStringAsFixed(2)} km';
}
