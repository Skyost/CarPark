import 'dart:async';

import 'package:car_park/util/localization/localization.dart';
import 'package:car_park/util/util.dart';
import 'package:flutter/material.dart';

/// A dialog that allows the user to select a time (hour and minute).
class TimePickerDialog extends StatefulWidget {
  /// The default time.
  final HourMinute _hourMinute;

  /// Creates a new time picker dialog instance.
  TimePickerDialog(this._hourMinute);

  @override
  State<StatefulWidget> createState() => _TimePickerDialogState();

  static Future<HourMinute> askTime(BuildContext context, HourMinute hourMinute) async {
    HourMinute hourMinuteCopy = HourMinute(
      hourMinute.hour,
      hourMinute.minute,
    );

    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(AppLocalization.of(context).get('time.arrival.dialog')),
            content: TimePickerDialog(hourMinuteCopy),
            actions: [
              FlatButton(
                child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                onPressed: () => Navigator.pop(context, hourMinute),
              ),
              FlatButton(
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
                onPressed: () => Navigator.pop(context, hourMinuteCopy),
              ),
            ],
          ),
    );
  }
}

/// The time picker dialog state.
class _TimePickerDialogState extends State<TimePickerDialog> {
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: DropdownButton(
              isExpanded: true,
              value: widget._hourMinute.hour,
              items: [
                for (int i = 0; i < 24; i++)
                  DropdownMenuItem(
                    child: Text(Util.addZeroIfNeeded(i)),
                    value: i,
                  )
              ],
              onChanged: (value) => setState(() {
                    widget._hourMinute.hour = value;
                  }),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(':'),
          ),
          Expanded(
            child: DropdownButton(
              isExpanded: true,
              value: widget._hourMinute.minute,
              items: [
                for (int i = 0; i < 60; i++)
                  DropdownMenuItem(
                    child: Text(Util.addZeroIfNeeded(i)),
                    value: i,
                  )
              ],
              onChanged: (value) => setState(() {
                    widget._hourMinute.minute = value;
                  }),
            ),
          ),
        ],
      );
}
