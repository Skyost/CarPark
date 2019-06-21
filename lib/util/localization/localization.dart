import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// The app localization class.
class AppLocalization {
  /// The current locale.
  final Locale locale;

  /// Creates a new app localization instance.
  AppLocalization(this.locale);

  /// Gets the app localization instance attached to the specified build config.
  static AppLocalization of(BuildContext context) => Localizations.of<AppLocalization>(context, AppLocalization);

  /// The localized strings.
  Map<String, String> _strings = HashMap();

  /// Loads the localized strings.
  Future<bool> load() async {
    String data = await rootBundle.loadString("assets/languages/${locale.languageCode}.json");
    Map<String, dynamic> strings = json.decode(data);
    strings.forEach((String key, dynamic value) => this._strings[key] = value.toString());
    return true;
  }

  /// Returns the string associated to the specified key.
  String get(String key) => this._strings[key];
}
