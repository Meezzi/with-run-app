String _formatTime(dynamic runningTime) {
  final seconds = int.tryParse(runningTime?.toString() ?? '0') ?? 0;
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}
