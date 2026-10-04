/// Time-of-day greeting from the device's local time:
/// 05:00-11:59 morning, 12:00-17:59 afternoon, otherwise evening.
String greetingFor(DateTime localNow) {
  final hour = localNow.hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 18) return 'Good afternoon';
  return 'Good evening';
}

/// First word of [fullName], or '' when blank.
String firstNameOf(String? fullName) {
  final parts = (fullName ?? '').trim().split(RegExp(r'\s+'));
  return parts.first;
}

/// Formats schema `curfewHours` (24h number) for display, e.g. 22 -> "10:00 PM".
String formatCurfew(num? hours) {
  if (hours == null) return 'No curfew';
  final h = hours.toInt();
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final suffix = h < 12 ? 'AM' : 'PM';
  return '$h12:00 $suffix';
}
