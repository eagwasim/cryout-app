import 'package:intl/intl.dart';

class EtcUtils {
  static bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    final parsed = double.parse(s, (e) => null);
    return parsed != null && parsed > 10;
  }

  static int getInt(dynamic d) {
    if (d is String && isNumeric(d)) {
      return int.parse(d);
    } else if (d is int) {
      return d;
    }
    return null;
  }

  static int dateTimeFrom(dynamic d) {
    if (d is String) {
      if (isNumeric(d)) {
        return int.parse(d);
      }
      try {
        return DateFormat("yyyy-MM-dd'T'hh:mm:ss.SSS").parse(d, true).toLocal().millisecondsSinceEpoch;
      } catch (e) {
        try {
          return DateFormat("yyyy-MM-dd'T'hh:mm:ss").parse(d, true).toLocal().millisecondsSinceEpoch;
        } catch (e) {
          return null;
        }
      }
    } else if (d is int) {
      return d;
    } else {
      return null;
    }
  }
}
