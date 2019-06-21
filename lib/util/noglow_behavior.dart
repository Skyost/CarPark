import 'package:flutter/material.dart';

/// A simple scroll behavior that allows to stop list views from glowing.
class NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(BuildContext context, Widget child, AxisDirection axisDirection) => child;
}