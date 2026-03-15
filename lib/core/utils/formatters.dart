import 'package:intl/intl.dart';

class Formatters {
  static final _decimal = NumberFormat.decimalPattern();
  static final _compact = NumberFormat.compact();

  static String bytes(num bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var value = bytes.toDouble();
    var index = 0;
    while (value >= 1024 && index < suffixes.length - 1) {
      value /= 1024;
      index++;
    }
    final decimals = value >= 10 || index == 0 ? 0 : 1;
    return '${value.toStringAsFixed(decimals)} ${suffixes[index]}';
  }

  static String speed(num bytesPerSecond) => '${bytes(bytesPerSecond)}/s';

  static String ratio(double ratio) {
    if (ratio < 0) {
      return 'N/A';
    }
    return ratio.toStringAsFixed(2);
  }

  static String eta(int? seconds) {
    if (seconds == null || seconds < 0) {
      return 'Unknown';
    }
    final duration = Duration(seconds: seconds);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    }
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }

  static String percentage(double value) =>
      '${(value * 100).clamp(0, 100).toStringAsFixed(1)}%';

  static String dateTime(DateTime? value) {
    if (value == null) {
      return 'Unknown';
    }
    return DateFormat.yMMMd().add_Hm().format(value.toLocal());
  }

  static String number(num value) => _decimal.format(value);

  static String compactNumber(num value) => _compact.format(value);
}
