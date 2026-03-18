import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(status: LocationStatus.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult(status: LocationStatus.permissionDenied);
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(status: LocationStatus.permissionDeniedForever);
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LocationResult(
      status: LocationStatus.granted,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();
}

enum LocationStatus {
  granted,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
}

class LocationResult {
  const LocationResult({
    required this.status,
    this.latitude,
    this.longitude,
  });

  final LocationStatus status;
  final double? latitude;
  final double? longitude;
}
