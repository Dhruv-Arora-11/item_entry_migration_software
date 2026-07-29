import 'package:flutter/material.dart';

void showSnack(
  BuildContext context,
  String message,
  Color color,
) {
  final messenger =
      ScaffoldMessenger.of(context);

  // removes current + queued snackbars
  messenger.clearSnackBars();

  messenger.showSnackBar(
    SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(
        seconds: 2,
      ),
      content: Text(message),
    ),
  );
}