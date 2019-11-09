import 'dart:io';

import 'package:flutter/material.dart';

/// Contains some useful methods.
class Util {
  /// Returns the platform URL.
  static String get platformURL => Platform.isIOS ? 'http://itunes.apple.com/app/id1469049463' : 'https://play.google.com/store/apps/details?id=fr.skyost.carpark';

  /// Adds a zero before the number if needed.
  static String addZeroIfNeeded(int value) => (value < 10 ? '0' : '') + value.toString();

  /// Strips seconds of a DateTime.
  static DateTime stripSeconds(DateTime dateTime) => DateTime(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute);

  /// Cuts a text word by word (to put it in a Wrap).
  static List<Text> wordByWord(String text, [TextStyle style]) {
    List<String> parts = text.split(' ');
    List<Text> result = [];

    for (String part in parts) {
      if (part.isEmpty) {
        continue;
      }

      result.add(Text(
        part,
        style: style,
      ));
    }

    return result;
  }
}

/// Hash utilities from quiver.
class Hash {

  /// Generates a hash code for two objects.
  static int hash2(a, b) => _finish(_combine(_combine(0, a.hashCode), b.hashCode));

  /// Generates a hash code for three objects.
  static int hash3(a, b, c) => _finish(
      _combine(_combine(_combine(0, a.hashCode), b.hashCode), c.hashCode));

  /// Generates a hash code for four objects.
  static int hash4(a, b, c, d) => _finish(_combine(
      _combine(_combine(_combine(0, a.hashCode), b.hashCode), c.hashCode),
      d.hashCode));

  /// Combine a hash with its value.
  static int _combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  /// Finish the process.
  static int _finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

}

/// Represents an instant in time with an hour and a minute.
class HourMinute {
  /// The hour.
  int hour;

  /// The minute.
  int minute;

  /// Creates a new hour minute instance.
  HourMinute([this.hour = 0, this.minute = 0]);

  /// Creates a new hour minute instance from a duration.
  HourMinute.fromDuration(Duration duration)
      : hour = duration.inHours.remainder(24),
        minute = duration.inMinutes.remainder(60);

  /// Divides every duration by two.
  HourMinuteSecond get halfTime => HourMinuteSecond(hour, minute).halfTime;

  /// Converts this hour minute to a duration.
  Duration get toDuration => Duration(
        hours: hour,
        minutes: minute,
      );

  /// Returns whether hour is 0 and minute is 0.
  bool get isZero => hour == 0 && minute == 0;

  /// Returns this object's value in seconds.
  int get toSeconds => hour * 3600 + minute * 60;

  /// Returns whether we're bigger than specified target.
  bool isBigger(HourMinute target) => toSeconds > target.toSeconds;

  /// Returns whether we're smaller than specified target.
  bool isSmaller(HourMinute target) => toSeconds < target.toSeconds;

  @override
  String toString() => Util.addZeroIfNeeded(hour) + ':' + Util.addZeroIfNeeded(minute);

  @override
  bool operator ==(other) {
    if(!(other is HourMinute)) {
      return false;
    }

    return toSeconds == other.toSeconds;
  }

  @override
  int get hashCode => Hash.hash2(hour, minute);
}

/// Represents an instant in time with an hour, a minute and a second.
class HourMinuteSecond extends HourMinute {
  /// The second.
  int second;

  /// Creates a new hour minute second instance.
  HourMinuteSecond([int hour = 0, int minute = 0, this.second = 0]) : super(hour, minute);

  /// Creates a new hour minute second instance from a duration.
  HourMinuteSecond.fromDuration(Duration duration) : super.fromDuration(duration) {
    second = duration.inSeconds.remainder(60);
  }

  /// Converts this hour minute to a duration.
  @override
  Duration get toDuration => Duration(
        hours: hour,
        minutes: minute,
        seconds: second,
      );

  /// Divides every duration by two.
  @override
  HourMinuteSecond get halfTime {
    HourMinuteSecond halfTime = HourMinuteSecond(hour, minute, second);

    if (halfTime.hour % 2 == 1) {
      halfTime.minute += 60;
      halfTime.hour -= 1;
    }

    if (halfTime.minute % 2 == 1) {
      halfTime.second += 60;
      halfTime.minute -= 1;
    }

    halfTime.hour = (halfTime.hour / 2).round();
    halfTime.minute = (halfTime.minute / 2).round();
    halfTime.second = (halfTime.second / 2).round();

    return halfTime;
  }

  /// Returns whether hour is 0, minute is 0 and second is 0.
  @override
  bool get isZero => super.isZero && second == 0;

  @override
  int get toSeconds => super.toSeconds + second;

  @override
  String toString() => Util.addZeroIfNeeded(hour) + ':' + Util.addZeroIfNeeded(minute) + ':' + Util.addZeroIfNeeded(second);

  @override
  int get hashCode => Hash.hash3(hour, minute, second);
}
