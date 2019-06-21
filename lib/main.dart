import 'package:car_park/page/countdown.dart';
import 'package:car_park/page/end.dart';
import 'package:car_park/page/start.dart';
import 'package:car_park/page/time.dart';
import 'package:car_park/app/model.dart';
import 'package:car_park/util/localization/localization_delegate.dart';
import 'package:car_park/util/noglow_behavior.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/style.dart';

/// Hello world !
void main() => runApp(CarParkApp());

/// The CarPark main widget.
class CarParkApp extends StatelessWidget {
  /// The application name.
  static const String APP_NAME = 'CarPark';

  /// The application model.
  final CarParkModel _model = CarParkModel();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: APP_NAME,
        theme: ThemeData(
          primarySwatch: AppStyle.PRIMARY_SWATCH,
          accentColor: AppStyle.ACCENT_COLOR,
          textTheme: TextTheme(
            display1: AppStyle.D1_STYLE,
            body1: AppStyle.B1_STYLE,
          ),
          buttonTheme: ButtonThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        localizationsDelegates: [
          AppLocalizationDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
          Locale('fr'),
          Locale('es'),
        ],
        localeResolutionCallback: (Locale locale, Iterable<Locale> supportedLocales) {
          if (locale == null) {
            return supportedLocales.first;
          }

          for (Locale supportedLocale in supportedLocales) {
            if (supportedLocale.languageCode == locale.languageCode || supportedLocale.countryCode == locale.countryCode) {
              return supportedLocale;
            }
          }

          return supportedLocales.first;
        },
        initialRoute: '/',
        routes: {
          '/': (context) => _withScaffold(StartPage(_model)),
          '/time': (context) => _withScaffold(TimePage(_model)),
          '/countdown': (context) => _withScaffold(CountdownPage(_model)),
          '/end': (context) => _withScaffold(EndPage()),
        },
        builder: (context, child) => ScrollConfiguration(
              behavior: NoGlowBehavior(),
              child: child,
            ),
        debugShowCheckedModeBanner: false,
      );

  /// Returns the default app scaffold.
  Widget _withScaffold(Widget page) => Scaffold(
        appBar: PreferredSize(
          child: Container(
            color: Colors.blue,
          ),
          preferredSize: Size(0, 0),
        ),
        body: page,
      );
}
