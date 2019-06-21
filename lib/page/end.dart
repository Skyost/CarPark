import 'package:car_park/app/style.dart';
import 'package:car_park/util/localization/localization.dart';
import 'package:car_park/util/util.dart';
import 'package:car_park/util/widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The end page.
class EndPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () => _onWillPop(context),
        child: _createListView(context),
      );

  /// Creates the list view.
  Widget _createListView(BuildContext context) => PageListView(
        content: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 40,
          ),
          child: Column(
            children: [_createText(context)]..addAll(_createButtons(context)),
          ),
        ),
      );

  /// Creates the text.
  Widget _createText(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 50),
        child: Text(
          AppLocalization.of(context).get('end.text'),
          textAlign: TextAlign.center,
        ),
      );

  /// Creates the buttons.
  List<Widget> _createButtons(BuildContext context) => [
        AppButton(
          text: AppLocalization.of(context).get('end.button.rate'),
          onPressed: () async => _launchURL(Util.platformURL),
          color: AppStyle.BUTTON_COLOR_2,
        ),
        Padding(
          padding: EdgeInsets.only(
            top: 10,
          ),
          child: AppButton(
            text: AppLocalization.of(context).get('end.button.improvement'),
            onPressed: () async => _launchURL('https://github.com/Skyost/CarPak/issues/new'),
            color: AppStyle.BUTTON_COLOR_2,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            vertical: 30,
          ),
          child: AppButton(
            text: AppLocalization.of(context).get('end.button.home'),
            onPressed: () => _onWillPop(context),
          ),
        )
      ];

  /// Triggered when the user try to push the "back" button.
  Future<bool> _onWillPop(BuildContext context) async {
    Navigator.pushReplacementNamed(context, '/');
    return false;
  }

  /// Launch an URL.
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
