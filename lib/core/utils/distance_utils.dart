import 'package:geolocator/geolocator.dart';

class DistanceUtils {
  static double kilometersBetween({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng) / 1000;
  }

  static double distanceWeight(double? kilometers) {
    if (kilometers == null) return 0.55;
    if (kilometers <= 1) return 1;
    if (kilometers >= 12) return 0.1;
    return 1 - ((kilometers - 1) / 11 * 0.9);
  }
}
