class Helper {
  static String formatDuration(String seconds) {
    int secondsInt = int.parse(seconds.substring(0, seconds.length - 1));
    final int hours = secondsInt ~/ 3600;
    final int minutes = (secondsInt % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return "$hours hr $minutes min";
    } else if (hours > 0) {
      return "$hours hr";
    } else {
      return "$minutes min";
    }
  }
}
