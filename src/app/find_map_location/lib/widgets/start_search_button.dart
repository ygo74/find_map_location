import 'package:flutter/material.dart';

/// Button widget to start the address search game
///
/// Displays a Material Design 3 ElevatedButton that becomes disabled after being pressed.
/// The button triggers the map zoom to the user's current location.
class StartSearchButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onPressed;

  const StartSearchButton({
    super.key,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
          child: const Text(
            'Start Search',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
