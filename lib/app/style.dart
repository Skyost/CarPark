import 'dart:ui';

import 'package:flutter/material.dart';

/// Contains some app styles.
class AppStyle {
  /// The primary swatch.
  static const Color PRIMARY_SWATCH = Colors.grey;

  /// The accent color.
  static const Color ACCENT_COLOR = Color(0xFF66BB6A); // Colors.green[400]

  /// The button 1 color.
  static const Color BUTTON_COLOR_1 = Color(0xFF42A5F5); // Colors.blue[400]

  /// The button 2 color.
  static const Color BUTTON_COLOR_2 = ACCENT_COLOR;

  /// Color of SnackBar containing errors.
  static const Color SNACKBAR_ERROR_COLOR = Color(0xFFB71C1C); // Colors.red[900]

  /// Display 1 text style.
  static const TextStyle D1_STYLE = TextStyle(
    fontFamily: 'handlee-regular',
    fontSize: 60,
    color: Colors.black87,
  );

  /// Body 1 text style.
  static const TextStyle B1_STYLE = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
}
