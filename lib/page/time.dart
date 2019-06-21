import 'package:car_park/app/model.dart';
import 'package:car_park/app/style.dart';
import 'package:car_park/util/dialogs.dart';
import 'package:car_park/util/localization/localization.dart';
import 'package:car_park/util/util.dart';
import 'package:car_park/util/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:flutter_duration_picker/flutter_duration_picker.dart';

/// The time page : where the user can choose the park period, where he can toggle notifications, etc...
class TimePage extends StatefulWidget {
  /// The current model instance.
  final CarParkModel _model;

  /// Creates a new time page instance.
  TimePage(this._model);

  @override
  State<StatefulWidget> createState() => _TimePageState();
}

/// The time page state.
class _TimePageState extends State<TimePage> {
  @override
  void initState() {
    super.initState();
    if (widget._model.parked) {
      SchedulerBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, '/countdown'));
    }
  }

  @override
  Widget build(BuildContext context) => WillPopScope(child: _createListView(context), onWillPop: _onWillPop,);

  /// Creates the list view.
  Widget _createListView(BuildContext context) => PageListView(
        backButton: true,
        content: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ButtonWithLabel(
                button: _createArrivalTimeButton(),
                labelStringKey: 'time.arrival',
              ),
              _ButtonWithLabel(
                button: _createDurationButton(),
                labelStringKey: 'time.duration',
              ),
              _createHalfTimeNotificationSwitch(context),
              _createNotificationBox(context),
              _createNextButton(context),
            ],
          ),
        ),
      );

  /// Creates the arrival time button.
  Widget _createArrivalTimeButton() => AppButton(
        text: DateFormat('HH:mm').format(widget._model.start),
        onPressed: () async {
          HourMinute result = await TimePickerDialog.askTime(context, HourMinute(widget._model.start.hour, widget._model.start.minute));
          if (result == null) {
            return;
          }

          DateTime now = DateTime.now();
          setState(() => widget._model.start = DateTime(now.year, now.month, now.day, result.hour, result.minute));
        },
        color: AppStyle.BUTTON_COLOR_2,
      );

  /// Creates the duration button.
  Widget _createDurationButton() => AppButton(
        text: HourMinute.fromDuration(widget._model.duration).toString(),
        onPressed: () async {
          Duration result = await showDurationPicker(
            context: context,
            initialTime: widget._model.duration,
          );
          if (result == null) {
            return;
          }

          setState(() => widget._model.duration = result);
        },
        color: AppStyle.BUTTON_COLOR_2,
      );

  /// Creates the half-time notification switch.
  Widget _createHalfTimeNotificationSwitch(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          top: 20,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                AppLocalization.of(context).get('time.halfTimeNotification'),
                style: Theme.of(context).textTheme.body1,
              ),
            ),
            Switch(
              value: widget._model.halfTimeNotificationEnabled,
              onChanged: (value) => setState(() {
                    widget._model.halfTimeNotificationEnabled = value;
                  }),
            ),
          ],
        ),
      );

  /// Creates the notification box.
  Widget _createNotificationBox(BuildContext context) => Padding(
        padding: EdgeInsets.only(
          top: 10,
        ),
        child: _NotificationBox(widget._model),
      );

  /// Creates the next button.
  Widget _createNextButton(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: AppButton(
          text: AppLocalization.of(context).get('time.next'),
          onPressed: () {
            switch (widget._model.coherence) {
              case Coherence.NULL_VALUES:
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalization.of(context).get('model.coherence.nullValues')),
                  backgroundColor: AppStyle.SNACKBAR_ERROR_COLOR,
                ));
                Navigator.pushReplacementNamed(context, '/');
                break;
              case Coherence.END_BEFORE_NOW:
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalization.of(context).get('model.coherence.endBeforeNow')),
                  backgroundColor: AppStyle.SNACKBAR_ERROR_COLOR,
                ));
                break;
              case Coherence.BEFORE_END_NOTIFICATION_BEFORE_NOW:
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(AppLocalization.of(context).get('model.coherence.endNotificationBeforeNow')),
                  backgroundColor: AppStyle.SNACKBAR_ERROR_COLOR,
                ));
                break;
              case Coherence.COHERENT:
                widget._model.saveToStorage();
                widget._model.parked = true;
                widget._model.scheduleNotifications(context);
                Navigator.pushReplacementNamed(context, '/countdown');
                break;
            }
          },
        ),
      );

  /// Triggered when the user try to push the "back" button.
  Future<bool> _onWillPop() async {
    Navigator.pushReplacementNamed(context, '/');
    return false;
  }
}

/// Just a little widget that contains a button and a label.
class _ButtonWithLabel extends StatelessWidget {
  /// The button.
  final AppButton button;

  /// The label string key.
  final String labelStringKey;

  /// Creates a new button with label instance.
  _ButtonWithLabel({
    @required this.button,
    @required this.labelStringKey,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: 30,
              bottom: 10,
            ),
            child: Text(
              AppLocalization.of(context).get(labelStringKey),
            ),
          ),
          button,
        ],
      );
}

/// The notification box widget.
class _NotificationBox extends StatefulWidget {
  /// The current model instance.
  final CarParkModel _model;

  /// Creates a new notification box instance.
  _NotificationBox(this._model);

  @override
  State<StatefulWidget> createState() => _NotificationBoxState();
}

/// The notification box widget state.
class _NotificationBoxState extends State<_NotificationBox> {
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      _createNotificationSwitch(context),
    ];

    if (widget._model.beforeEndNotificationEnabled) {
      TextStyle style = Theme.of(context).textTheme.body1.copyWith(
            fontWeight: FontWeight.normal,
          );
      children.add(_createNotificationHiddenBox(style));
    }

    return Column(
      children: children,
    );
  }

  /// Creates the notification switch.
  Widget _createNotificationSwitch(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              AppLocalization.of(context).get('time.notificationSwitch'),
              style: Theme.of(context).textTheme.body1,
            ),
          ),
          Switch(
            value: widget._model.beforeEndNotificationEnabled,
            onChanged: (value) => setState(() {
                  widget._model.beforeEndNotificationEnabled = value;
                }),
          ),
        ],
      );

  /// Creates the notification hidden box.
  Widget _createNotificationHiddenBox(TextStyle textStyle) {
    String text = AppLocalization.of(context).get('time.notificationHiddenBox');
    List<String> parts = text.split('{minutes}');

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Wrap(
          spacing: 5,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: []
            ..addAll(Util.wordByWord(parts[0], textStyle))
            ..add(_createTextField(textStyle))
            ..addAll(Util.wordByWord(parts[1], textStyle))),
    );
  }

  Widget _createTextField(TextStyle textStyle) => Container(
        margin: EdgeInsets.only(right: 5),
        width: 40,
        child: TextField(
          controller: TextEditingController(
            text: widget._model.beforeEndNotificationDelay == null ? '' : widget._model.beforeEndNotificationDelay.inMinutes.toString(),
          ),
          style: textStyle,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          onChanged: (value) => widget._model.beforeEndNotificationDelay = Duration(minutes: (num.tryParse(value) ?? 1).toInt()),
        ),
      );
}
