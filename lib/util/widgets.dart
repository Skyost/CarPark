import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:car_park/app/style.dart';
import 'package:car_park/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Just a list view that aims to contain app pages.
class PageListView extends StatelessWidget {
  /// Whether to add a back button.
  final bool backButton;

  /// The page.
  final Widget content;

  /// Creates a new page list view instance.
  PageListView({this.backButton = false, @required this.content});

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          CarParkAppBar(
            backButton: backButton,
          ),
          content,
        ],
      );
}

/// A simple app bar that matches the app style.
class CarParkAppBar extends StatelessWidget with PreferredSizeWidget {
  /// The height.
  static const double HEIGHT = kToolbarHeight + PADDING * 2;

  /// The padding.
  static const double PADDING = 8;

  /// Whether to show a back button.
  final bool backButton;

  /// Creates a new car park app bar.
  CarParkAppBar({
    this.backButton = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Positioned.fill(
        child: _createAppBar(context),
      ),
    ];

    if (backButton) {
      children.add(
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          child: BackButton(
            color: Colors.white,
          ),
        ),
      );
    }

    return SizedBox(
      height: HEIGHT,
      width: MediaQuery.of(context).size.width,
      child: Stack(children: children),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(HEIGHT);

  /// Creates the app bar.
  Widget _createAppBar(BuildContext context) => Container(
        color: Colors.blue,
        padding: EdgeInsets.symmetric(
          vertical: PADDING,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: SvgPicture.asset(
                'assets/images/car.svg',
                height: 30,
              ),
            ),
            AutoSizeText(
              CarParkApp.APP_NAME,
              style: Theme.of(context).textTheme.display1.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
              minFontSize: 0,
            ),
          ],
        ),
      );
}

/// A simple button that matches the app style.
class AppButton extends StatelessWidget {
  /// The button text.
  final String text;

  /// The on pressed callback.
  final GestureTapCallback onPressed;

  /// The button color.
  final Color color;

  /// Creates a new app button instance.
  AppButton({
    @required this.text,
    @required this.onPressed,
    this.color = AppStyle.BUTTON_COLOR_1,
  });

  @override
  Widget build(BuildContext context) => FlatButton(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 30,
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Text(
              text.toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.button.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ),
        ),
        onPressed: onPressed,
        color: color,
      );
}

/// A simple circular progress indicator that matches the app style.
class AppCircularProgressIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double size = min(MediaQuery.of(context).size.shortestSide, 100);
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 6,
        ),
      ),
    );
  }
}
