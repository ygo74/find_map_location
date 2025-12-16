import 'package:flutter_test/flutter_test.dart';
import 'package:find_map_location/models/game_session_state.dart';
import 'package:find_map_location/models/random_address.dart';
import 'package:find_map_location/models/city.dart';

void main() {
  group('GameSessionState', () {
    final testCity = City(
      name: 'Paris',
      latitude: 48.8566,
      longitude: 2.3522,
      department: '75',
      postalCode: '75001',
    );

    final testAddress1 = RandomAddress(
      streetNumber: '42',
      streetName: 'Rue de Rivoli',
      cityName: 'Paris',
      postcode: '75001',
      latitude: 48.8606,
      longitude: 2.3376,
      generatedAt: DateTime.now().toUtc(),
    );

    final testAddress2 = RandomAddress(
      streetNumber: '10',
      streetName: 'Avenue des Champs-Élysées',
      cityName: 'Paris',
      postcode: '75008',
      latitude: 48.8738,
      longitude: 2.2950,
      generatedAt: DateTime.now().toUtc(),
    );

    test('initial state has null current address and empty used addresses', () {
      final state = GameSessionState.initial(city: testCity);

      expect(state.currentAddress, isNull);
      expect(state.usedAddresses, isEmpty);
      expect(state.city, equals(testCity));
    });

    test('withAddress creates new state with current address and adds to used addresses', () {
      final state = GameSessionState.initial(city: testCity);

      final newState = state.withAddress(testAddress1);

      expect(newState.currentAddress, equals(testAddress1));
      expect(newState.usedAddresses, contains(testAddress1));
      expect(newState.usedAddresses.length, 1);
      expect(newState.city, equals(testCity));

      // Original state should be unchanged
      expect(state.currentAddress, isNull);
      expect(state.usedAddresses, isEmpty);
    });

    test('withAddress with multiple addresses accumulates in used addresses', () {
      final state = GameSessionState.initial(city: testCity);

      final state1 = state.withAddress(testAddress1);
      final state2 = state1.withAddress(testAddress2);

      expect(state2.currentAddress, equals(testAddress2));
      expect(state2.usedAddresses, containsAll([testAddress1, testAddress2]));
      expect(state2.usedAddresses.length, 2);
    });

    test('used addresses Set prevents duplicates', () {
      final state = GameSessionState.initial(city: testCity);

      final state1 = state.withAddress(testAddress1);
      final state2 = state1.withAddress(testAddress1); // Same address again

      expect(state2.usedAddresses.length, 1); // Still only 1 unique address
      expect(state2.usedAddresses, contains(testAddress1));
    });

    test('addUsedAddress adds address to used addresses without changing current address', () {
      final state = GameSessionState.initial(city: testCity)
          .withAddress(testAddress1);

      final newState = state.addUsedAddress(testAddress2);

      expect(newState.currentAddress, equals(testAddress1)); // Unchanged
      expect(newState.usedAddresses, containsAll([testAddress1, testAddress2]));
      expect(newState.usedAddresses.length, 2);
    });

    test('withCity creates new state with new city and clears addresses', () {
      final state = GameSessionState.initial(city: testCity)
          .withAddress(testAddress1);

      final newCity = City(
        name: 'Lyon',
        latitude: 45.7640,
        longitude: 4.8357,
        department: '69',
        postalCode: '69001',
      );

      final newState = state.withCity(newCity);

      expect(newState.city, equals(newCity));
      expect(newState.currentAddress, isNull);
      expect(newState.usedAddresses, isEmpty);
    });

    test('equality is based on city, current address, and used addresses', () {
      final state1 = GameSessionState.initial(city: testCity)
          .withAddress(testAddress1);

      final state2 = GameSessionState.initial(city: testCity)
          .withAddress(testAddress1);

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('different current addresses result in different states', () {
      final state1 = GameSessionState.initial(city: testCity)
          .withAddress(testAddress1);

      final state2 = GameSessionState.initial(city: testCity)
          .withAddress(testAddress2);

      expect(state1, isNot(equals(state2)));
    });

    test('different cities result in different states', () {
      final state1 = GameSessionState.initial(city: testCity);

      final differentCity = City(
        name: 'Lyon',
        latitude: 45.7640,
        longitude: 4.8357,
        department: '69',
        postalCode: '69001',
      );

      final state2 = GameSessionState.initial(city: differentCity);

      expect(state1, isNot(equals(state2)));
    });
  });
}
