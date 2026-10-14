import 'package:azkar/core/utils/coordinate_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoordinateValidator.isValidLatitude', () {
    test('accepts values inside the range', () {
      expect(CoordinateValidator.isValidLatitude(0), isTrue);
      expect(CoordinateValidator.isValidLatitude(21.4225), isTrue);
      expect(CoordinateValidator.isValidLatitude(-33.8688), isTrue);
    });

    test('accepts boundary values', () {
      expect(CoordinateValidator.isValidLatitude(90), isTrue);
      expect(CoordinateValidator.isValidLatitude(-90), isTrue);
    });

    test('rejects values outside the range', () {
      expect(CoordinateValidator.isValidLatitude(90.0001), isFalse);
      expect(CoordinateValidator.isValidLatitude(-90.0001), isFalse);
      expect(CoordinateValidator.isValidLatitude(1000), isFalse);
    });

    test('rejects non-finite values', () {
      expect(CoordinateValidator.isValidLatitude(double.nan), isFalse);
      expect(CoordinateValidator.isValidLatitude(double.infinity), isFalse);
      expect(CoordinateValidator.isValidLatitude(double.negativeInfinity), isFalse);
    });
  });

  group('CoordinateValidator.isValidLongitude', () {
    test('accepts values inside the range', () {
      expect(CoordinateValidator.isValidLongitude(0), isTrue);
      expect(CoordinateValidator.isValidLongitude(39.8262), isTrue);
      expect(CoordinateValidator.isValidLongitude(-118.2437), isTrue);
    });

    test('accepts boundary values', () {
      expect(CoordinateValidator.isValidLongitude(180), isTrue);
      expect(CoordinateValidator.isValidLongitude(-180), isTrue);
    });

    test('rejects values outside the range', () {
      expect(CoordinateValidator.isValidLongitude(180.0001), isFalse);
      expect(CoordinateValidator.isValidLongitude(-180.0001), isFalse);
      expect(CoordinateValidator.isValidLongitude(500), isFalse);
    });

    test('rejects non-finite values', () {
      expect(CoordinateValidator.isValidLongitude(double.nan), isFalse);
    });
  });

  group('CoordinateValidator.parseLatitude', () {
    test('parses valid input', () {
      expect(CoordinateValidator.parseLatitude('21.4225'), 21.4225);
      expect(CoordinateValidator.parseLatitude('  -33.8688 '), -33.8688);
      expect(CoordinateValidator.parseLatitude('0'), 0);
    });

    test('returns null for out of range input', () {
      expect(CoordinateValidator.parseLatitude('91'), isNull);
      expect(CoordinateValidator.parseLatitude('-91'), isNull);
    });

    test('returns null for unparsable input', () {
      expect(CoordinateValidator.parseLatitude(''), isNull);
      expect(CoordinateValidator.parseLatitude('abc'), isNull);
      expect(CoordinateValidator.parseLatitude(null), isNull);
      expect(CoordinateValidator.parseLatitude('12,5'), isNull);
    });
  });

  group('CoordinateValidator.parseLongitude', () {
    test('parses valid input', () {
      expect(CoordinateValidator.parseLongitude('39.8262'), 39.8262);
      expect(CoordinateValidator.parseLongitude('-118.2437'), -118.2437);
    });

    test('returns null for out of range input', () {
      expect(CoordinateValidator.parseLongitude('181'), isNull);
      expect(CoordinateValidator.parseLongitude('-181'), isNull);
    });

    test('returns null for unparsable input', () {
      expect(CoordinateValidator.parseLongitude(''), isNull);
      expect(CoordinateValidator.parseLongitude('abc'), isNull);
      expect(CoordinateValidator.parseLongitude(null), isNull);
    });
  });

  group('CoordinateValidator.isValidPair', () {
    test('requires both coordinates to be valid', () {
      expect(
        CoordinateValidator.isValidPair(latitude: 21.4225, longitude: 39.8262),
        isTrue,
      );
      expect(
        CoordinateValidator.isValidPair(latitude: 95, longitude: 39.8262),
        isFalse,
      );
      expect(
        CoordinateValidator.isValidPair(latitude: 21.4225, longitude: 200),
        isFalse,
      );
    });
  });
}
