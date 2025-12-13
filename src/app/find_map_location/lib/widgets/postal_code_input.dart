import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input widget for entering postal codes.
///
/// Provides a text field limited to 5 digits with a submit button.
/// Displays validation errors via [errorMessage] when provided.
class PostalCodeInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final String? errorMessage;

  const PostalCodeInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'French Postal Code',
            hintText: 'Enter 5-digit postal code',
            errorText: errorMessage,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.location_city),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          maxLength: 5,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onSubmit,
          icon: const Icon(Icons.search),
          label: const Text('Find City'),
        ),
      ],
    );
  }
}
