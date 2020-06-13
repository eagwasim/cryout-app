class EtcUtils {
  static bool isNumeric(String s) {
    if (s == null) {
      return false;
    }
    final parsed = double.parse(s, (e) => null);
    return parsed != null && parsed > 10;
  }
}
