/// A value object representing a French postal code.
///
/// Validates that the postal code follows the French 5-digit format.
class PostalCode {
  static final RegExp _validationPattern = RegExp(r'^[0-9]{5}$');

  final String value;

  PostalCode(this.value);

  /// Checks if the postal code matches the valid 5-digit format
  bool get isValid => _validationPattern.hasMatch(value);

  /// Checks if the postal code is empty
  bool get isEmpty => value.isEmpty;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostalCode && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
