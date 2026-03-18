import 'package:geocoding/geocoding.dart';
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
      return const LocationResult(
        status: LocationStatus.permissionDeniedForever,
      );
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

  Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return null;
      }

      final place = placemarks.first;
      final cityCandidates = [
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ];

      String? city;
      for (final candidate in cityCandidates) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          city = candidate.trim();
          break;
        }
      }

      final country = place.country?.trim();
      final parts = [
        if (city != null && city.isNotEmpty) city,
        if (country != null && country.isNotEmpty) country,
      ];

      if (parts.isEmpty) {
        return null;
      }

      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}

enum LocationStatus {
  granted,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
}

class LocationResult {
  const LocationResult({required this.status, this.latitude, this.longitude});

  final LocationStatus status;
  final double? latitude;
  final double? longitude;
}
