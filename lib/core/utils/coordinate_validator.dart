/// Validation helpers for geographic coordinates.
///
/// Prayer calculations are only meaningful for coordinates inside the valid
/// geographic range, so invalid manual entries must be rejected before they
/// are persisted or used.
class CoordinateValidator {
  const CoordinateValidator._();

  static const double minLatitude = -90;
  static const double maxLatitude = 90;
  static const double minLongitude = -180;
  static const double maxLongitude = 180;

  /// Whether [latitude] is a usable latitude.
  static bool isValidLatitude(double latitude) {
    return latitude.isFinite &&
        latitude >= minLatitude &&
        latitude <= maxLatitude;
  }

  /// Whether [longitude] is a usable longitude.
  static bool isValidLongitude(double longitude) {
    return longitude.isFinite &&
        longitude >= minLongitude &&
        longitude <= maxLongitude;
  }

  /// Whether both coordinates can be used for prayer calculations.
  static bool isValidPair({required double latitude, required double longitude}) {
    return isValidLatitude(latitude) && isValidLongitude(longitude);
  }

  /// Parses and validates a latitude entered as text.
  ///
  /// Returns `null` when the text is not a number or is out of range.
  static double? parseLatitude(String? raw) {
    final value = double.tryParse(raw?.trim() ?? '');
    if (value == null || !isValidLatitude(value)) {
      return null;
    }
    return value;
  }

  /// Parses and validates a longitude entered as text.
  ///
  /// Returns `null` when the text is not a number or is out of range.
  static double? parseLongitude(String? raw) {
    final value = double.tryParse(raw?.trim() ?? '');
    if (value == null || !isValidLongitude(value)) {
      return null;
    }
    return value;
  }
}
