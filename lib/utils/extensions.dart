extension StringExtension on String {
  String titleCapitalize() {
    if (this.length <= 1) return this.toUpperCase();
    var words = this.toLowerCase().split(' ');
    var capitalized = words.map((word) {
      if (word.length < 2) {
        return word;
      }
      var first = word.substring(0, 1).toUpperCase();
      var rest = word.substring(1);
      return '$first$rest';
    });
    return capitalized.join(' ');
  }

  String capitalize() {
    if (this.length <= 1) return this.toUpperCase();
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
