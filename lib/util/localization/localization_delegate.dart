import 'dart:async';

import 'package:car_park/util/localization/localization.dart';
import 'package:flutter/material.dart';

/// The app localization delegate class.
class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  /// Creates a new app localization delegate instance.
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) async {
    AppLocalization appLocalization = AppLocalization(locale);
    await appLocalization.load();
    return appLocalization;
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalization> old) => false;
}