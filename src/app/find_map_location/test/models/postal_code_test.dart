import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/postal_code.dart';

void main() {
  group('PostalCode', () {
    test('isValid returns true for valid 5-digit postal code', () {
      final postalCode = PostalCode('75001');
      expect(postalCode.isValid, isTrue);
    });

    test('isValid returns false for postal code with less than 5 digits', () {
      final postalCode = PostalCode('123');
      expect(postalCode.isValid, isFalse);
    });

    test('isValid returns false for postal code with more than 5 digits', () {
      final postalCode = PostalCode('750011');
      expect(postalCode.isValid, isFalse);
    });

    test('isValid returns false for postal code containing letters', () {
      final postalCode = PostalCode('7500A');
      expect(postalCode.isValid, isFalse);
    });

    test('isEmpty returns true for empty postal code', () {
      final postalCode = PostalCode('');
      expect(postalCode.isEmpty, isTrue);
    });

    test('isEmpty returns false for non-empty postal code', () {
      final postalCode = PostalCode('75001');
      expect(postalCode.isEmpty, isFalse);
    });

    test('toString returns the postal code value', () {
      final postalCode = PostalCode('75001');
      expect(postalCode.toString(), equals('75001'));
    });

    test('equality works correctly', () {
      final postalCode1 = PostalCode('75001');
      final postalCode2 = PostalCode('75001');
      final postalCode3 = PostalCode('69001');

      expect(postalCode1, equals(postalCode2));
      expect(postalCode1, isNot(equals(postalCode3)));
    });
  });
}
