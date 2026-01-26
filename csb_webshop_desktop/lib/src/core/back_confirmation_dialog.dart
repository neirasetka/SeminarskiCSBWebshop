import 'package:flutter/material.dart';

/// Shows a confirmation dialog when the user tries to go back.
/// Returns true if the user confirms they want to leave, false otherwise.
Future<bool> showBackConfirmationDialog(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Napustiti stranicu?'),
      content: const Text('Jeste li sigurni da želite napustiti ovu stranicu?'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ne'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Da'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Handles back navigation with confirmation dialog.
/// Call this from AppBar leading button or custom back button.
Future<void> handleBackWithConfirmation(BuildContext context) async {
  final bool shouldPop = await showBackConfirmationDialog(context);
  if (shouldPop && context.mounted) {
    Navigator.of(context).pop();
  }
}

/// A widget that wraps content and intercepts back navigation
/// to show a confirmation dialog.
class BackConfirmationWrapper extends StatelessWidget {
  const BackConfirmationWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await handleBackWithConfirmation(context);
      },
      child: child,
    );
  }
}

/// Creates a back button that shows confirmation dialog before navigating back.
Widget buildBackButtonWithConfirmation(BuildContext context) {
  return IconButton(
    icon: const Icon(Icons.arrow_back),
    tooltip: 'Nazad',
    onPressed: () => handleBackWithConfirmation(context),
  );
}
