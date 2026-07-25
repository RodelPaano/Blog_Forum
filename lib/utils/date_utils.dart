import 'package:intl/intl.dart';

class AppDate {
  AppDate._();

  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, y').format(dt);
  }

  static String display(DateTime created, DateTime updated) {
    final base = relative(created);
    final isEdited =
        (updated.millisecondsSinceEpoch - created.millisecondsSinceEpoch)
                .abs() >=
            1000;
    if (isEdited) return '$base · edited';
    return base;
  }
}
