import 'package:find_map_location/models/random_address.dart';

/// Wrapper for address generation operations.
///
/// Provides either a successful address or an error message.
/// Exactly one of [address] or [error] will be non-null.
class AddressSelectionResult {
  /// The successfully generated address (null on failure)
  final RandomAddress? address;

  /// User-friendly error message (null on success)
  final String? error;

  /// Whether the address generation was successful
  bool get isSuccess => address != null;

  /// Private constructor to enforce factory usage
  const AddressSelectionResult._({
    this.address,
    this.error,
  }) : assert(
          (address != null && error == null) || (address == null && error != null),
          'Exactly one of address or error must be non-null',
        );

  /// Creates a successful result with an address.
  ///
  /// Example:
  /// ```dart
  /// final address = RandomAddress(...);
  /// return AddressSelectionResult.success(address);
  /// ```
  factory AddressSelectionResult.success(RandomAddress address) {
    return AddressSelectionResult._(address: address, error: null);
  }

  /// Creates a failure result with an error message.
  ///
  /// The error message should be user-friendly and actionable.
  ///
  /// Example:
  /// ```dart
  /// return AddressSelectionResult.failure(
  ///   'Unable to generate address for this location. Please try a different city.'
  /// );
  /// ```
  factory AddressSelectionResult.failure(String error) {
    return AddressSelectionResult._(address: null, error: error);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'AddressSelectionResult.success($address)';
    } else {
      return 'AddressSelectionResult.failure($error)';
    }
  }
}
