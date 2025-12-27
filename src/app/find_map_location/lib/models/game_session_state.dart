import 'package:find_map_location/models/city.dart';
import 'package:find_map_location/models/random_address.dart';

/// Represents the state of a game session for address finding
///
/// Tracks the current target address and all previously used addresses
/// to ensure uniqueness. Immutable with factory constructors for state transitions.
class GameSessionState {
  final City city;
  final RandomAddress? currentAddress;
  final Set<RandomAddress> usedAddresses;
  final bool hasStartedSearch;
  final String? currentCellId;

  const GameSessionState._({
    required this.city,
    required this.currentAddress,
    required this.usedAddresses,
    required this.hasStartedSearch,
    this.currentCellId,
  });

  /// Creates initial state for a city with no addresses
  factory GameSessionState.initial({required City city}) {
    return GameSessionState._(
      city: city,
      currentAddress: null,
      usedAddresses: {},
      hasStartedSearch: false,
      currentCellId: null,
    );
  }

  /// Creates new state with the given address as current
  ///
  /// Automatically adds the address to usedAddresses to prevent reuse.
  /// Optionally includes the cell ID for the address location.
  GameSessionState withAddress(RandomAddress address, {String? cellId}) {
    final newUsedAddresses = Set<RandomAddress>.from(usedAddresses)
      ..add(address);

    return GameSessionState._(
      city: city,
      currentAddress: address,
      usedAddresses: newUsedAddresses,
      hasStartedSearch: hasStartedSearch,
      currentCellId: cellId,
    );
  }

  /// Adds an address to used addresses without changing current address
  ///
  /// Useful for tracking addresses that were generated but not selected
  GameSessionState addUsedAddress(RandomAddress address) {
    final newUsedAddresses = Set<RandomAddress>.from(usedAddresses)
      ..add(address);

    return GameSessionState._(
      city: city,
      currentAddress: currentAddress,
      usedAddresses: newUsedAddresses,
      hasStartedSearch: hasStartedSearch,
      currentCellId: currentCellId,
    );
  }

  /// Marks the search as started (Start Search button pressed)
  GameSessionState withSearchStarted() {
    return GameSessionState._(
      city: city,
      currentAddress: currentAddress,
      usedAddresses: usedAddresses,
      hasStartedSearch: true,
      currentCellId: currentCellId,
    );
  }

  /// Creates new state for a different city, clearing all addresses
  GameSessionState withCity(City newCity) {
    return GameSessionState.initial(city: newCity);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSessionState &&
          runtimeType == other.runtimeType &&
          city == other.city &&
          currentAddress == other.currentAddress &&
          usedAddresses.length == other.usedAddresses.length &&
          usedAddresses.containsAll(other.usedAddresses) &&
          hasStartedSearch == other.hasStartedSearch &&
          currentCellId == other.currentCellId;

  @override
  int get hashCode =>
      city.hashCode ^
      currentAddress.hashCode ^
      usedAddresses.fold(0, (prev, addr) => prev ^ addr.hashCode) ^
      hasStartedSearch.hashCode ^
      currentCellId.hashCode;
}
