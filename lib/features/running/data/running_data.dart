class RunningData {
  final int steps;
  final double distance;
  final double speed;
  final int calories;
  final int runningTime;

  RunningData({
    required this.steps,
    required this.distance,
    required this.speed,
    required this.calories,
    required this.runningTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'steps': steps.toString(),
      'distance': distance.toStringAsFixed(2),
      'speed': speed.toStringAsFixed(2),
      'calories': calories.toString(),
      'runningTime': runningTime.toString(),
    };
  }
}
