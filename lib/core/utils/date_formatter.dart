String formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date).inDays;

  if (difference == 0) return '오늘';
  if (difference == 1) return '어제';
  if (difference < 7) return '$difference일 전';

  return now.year == date.year
      ? '${date.month}월 ${date.day}일'
      : '${date.year}년 ${date.month}월 ${date.day}일';
}
