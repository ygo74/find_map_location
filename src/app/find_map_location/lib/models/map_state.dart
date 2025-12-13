/// Represents the state of the map display.
///
/// Used to track the current state of map loading and display.
enum MapState {
  /// Initial state before any postal code submission
  idle,

  /// Loading state during geocoding lookup
  loading,

  /// Success state when map is displayed
  success,

  /// Error state when an error occurred
  error,
}
