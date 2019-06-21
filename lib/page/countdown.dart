import 'dart:async';

import 'package:car_park/app/model.dart';
import 'package:car_park/util/localization/localization.dart';
import 'package:car_park/util/self_updating_map.dart';
import 'package:car_park/util/util.dart';
import 'package:car_park/util/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';

/// The countdown page, where the user can see its position on a map with a little countdown.
class CountdownPage extends StatefulWidget {
  /// The current model instance.
  final CarParkModel _model;

  /// Creates a new countdown page instance.
  CountdownPage(this._model);

  @override
  State<StatefulWidget> createState() => _CountdownPageState(_model);
}

/// The countdown page state.
class _CountdownPageState extends FullScreenSelfUpdatingMapWidgetState<CountdownPage> {
  /// The self updating map instance.
  final SelfUpdatingMap _map;

  /// Creates a new countdown page state instance.
  _CountdownPageState(CarParkModel _model)
      : _map = SelfUpdatingMap(
          currentPositionIcon: Icon(
            Icons.directions_walk,
            size: 40,
            color: Colors.blue,
          ),
          locationUpdateCallback: (controller, position) {
            try {
              controller?.fitBounds(
                LatLngBounds(_model.carPosition, position),
                options: FitBoundsOptions(
                  padding: EdgeInsets.all(40),
                ),
              );
            } catch (_) {}
          },
          additionalMarkers: [
            Marker(
              width: 40,
              height: 40,
              point: _model.carPosition,
              builder: (contact) => Icon(
                    Icons.directions_car,
                    size: 40,
                    color: Colors.teal,
                  ),
            ),
          ],
        );

  @override
  SelfUpdatingMap get map => _map;

  @override
  Widget get nonFullScreenContent => WillPopScope(
        child: PageListView(
          backButton: true,
          content: Column(
            children: [
              _createMapContainer(context),
              _createCountdownContainer(),
              _createNextButton(context),
            ],
          ),
        ),
        onWillPop: _onWillPop,
      );

  /// Triggered when the user try to push the "back" button.
  Future<bool> _onWillPop() async {
    await _cancel();
    return true;
  }

  /// Creates the map container.
  Widget _createMapContainer(BuildContext context) => Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.black12,
            ),
          ),
        ),
        height: _calculateMapContainerHeight(context),
        child: mapWithButton,
      );

  /// Creates the countdown container.
  Widget _createCountdownContainer() => Container(
        padding: EdgeInsets.symmetric(
          vertical: 20,
        ),
        color: Colors.black.withAlpha(6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              DateFormat('HH:mm').format(widget._model.start),
            ),
            _CountdownWidget(widget._model.start.add(widget._model.duration)),
            Text(
              DateFormat('HH:mm').format(widget._model.start.add(widget._model.duration)),
            ),
          ],
        ),
      );

  /// Creates the next button.
  Widget _createNextButton(BuildContext context) => Container(
        height: MediaQuery.of(context).size.longestSide - MediaQuery.of(context).padding.top - CarParkAppBar.HEIGHT - _calculateMapContainerHeight(context) - 98,
        padding: EdgeInsets.symmetric(
          horizontal: 40,
        ),
        child: Center(
          child: AppButton(
            text: AppLocalization.of(context).get('countdown.next'),
            onPressed: () => _cancel().then((v) => Navigator.pushReplacementNamed(context, '/end')),
          ),
        ),
      );

  /// Allows to cancel notifications and set the "parked" attribute to false.
  Future<void> _cancel() async {
    widget._model.cancelNotifications();
    widget._model.reset();
    await widget._model.removeFromStorage();
  }

  /// Calculates the map container height.
  double _calculateMapContainerHeight(BuildContext context) => MediaQuery.of(context).size.shortestSide - MediaQuery.of(context).padding.top - CarParkAppBar.HEIGHT;
}

/// The countdown widget.
class _CountdownWidget extends StatefulWidget {
  /// End date of the countdown.
  final DateTime _end;

  /// Creates a new countdown widget instance.
  _CountdownWidget(this._end);

  @override
  State<StatefulWidget> createState() => _CountdownWidgetState();
}

/// The countdown widget state.
class _CountdownWidgetState extends State<_CountdownWidget> with WidgetsBindingObserver {
  /// The countdown.
  HourMinuteSecond _countdown;

  /// The half-time.
  HourMinuteSecond _halfTime;

  /// The current timer.
  Timer _currentTimer;

  @override
  void initState() {
    super.initState();

    _initCountDown();
    _halfTime = _countdown.halfTime;
    _scheduleCountdownIteration();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _currentTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    setState(() {
      _initCountDown();

      if (!_countdown.isZero && (_currentTimer == null || !_currentTimer.isActive)) {
        _scheduleCountdownIteration();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Text(
        _countdown.toString(),
        style: Theme.of(context).textTheme.body1.copyWith(
              fontSize: 28,
              color: _countdownColor,
            ),
      );

  /// Schedules a new countdown iteration.
  void _scheduleCountdownIteration() => _currentTimer = Timer(Duration(seconds: 1), () {
        _countdown.second--;

        if (_countdown.second < 0) {
          _countdown.second = 59;
          _countdown.minute--;
        }

        if (_countdown.minute < 0) {
          _countdown.minute = 59;
          _countdown.hour--;
        }

        if (_countdown.hour < 0) {
          _countdown.hour = 0;
          _countdown.minute = 0;
          _countdown.second = 0;
        } else {
          _scheduleCountdownIteration();
        }

        if (mounted) {
          setState(() {});
        }
      });

  /// Returns the countdown color.
  Color get _countdownColor {
    if (_countdown.isZero) {
      return Colors.red[800];
    }

    if (_isAfterHalfTime) {
      return Colors.orange;
    }

    return Colors.green;
  }

  /// Returns whether the current countdown is after half-time.
  bool get _isAfterHalfTime => _halfTime.hour * 3600 + _halfTime.minute * 60 + _halfTime.second > _countdown.hour * 3600 + _countdown.minute * 60 + _countdown.second;

  /// Initializes the countdown.
  void _initCountDown() {
    Duration countdown = widget._end.difference(DateTime.now());
    _countdown = countdown.isNegative ? HourMinuteSecond(0, 0, 0) : HourMinuteSecond.fromDuration(countdown);
  }
}
