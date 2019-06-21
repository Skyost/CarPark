import 'package:car_park/util/localization/localization.dart';
import 'package:car_park/util/util.dart';
import 'package:flutter/widgets.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:localstorage/localstorage.dart';

/// The app model.
class CarParkModel {
  /// Manual notification details for Android.
  static AndroidNotificationDetails _carParkManual = AndroidNotificationDetails('car_park_manual', 'CarkPark Manual Notifications', 'Notifications that are manually sent through CarPark');

  /// Automatic notification details for Android.
  static AndroidNotificationDetails _carParkAutomatic = AndroidNotificationDetails('car_park_automatic', 'CarkPark Automatic Notifications', 'Notifications that are automatically sent by CarPark');

  /// Half-time notification id.
  static const int _MANUAL_NOTIFICATION_1 = 0;

  /// Before end notification id.
  static const int _MANUAL_NOTIFICATION_2 = 1;

  /// End notification id.
  static const int _AUTOMATIC_NOTIFICATION = 2;

  /// The file where the current model is saved.
  static const String _PREFS_FILE = 'park_state.json';

  /// The current car position.
  LatLng carPosition;

  /// The start.
  DateTime start;

  /// The park duration.
  Duration duration;

  /// Whether half-time notifications are enabled.
  bool halfTimeNotificationEnabled;

  /// Whether a before end notification should be sent.
  bool beforeEndNotificationEnabled;

  /// The before end notification delay.
  Duration beforeEndNotificationDelay;

  /// Whether the user car is actually parked.
  bool parked;

  /// The current notifications plugin.
  FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Creates a new CarPark model instance.
  CarParkModel() {
    reset();
  }

  /// Schedules notifications.
  void scheduleNotifications(BuildContext context) {
    Coherence coherence = this.coherence;
    if (coherence != Coherence.COHERENT) {
      throw IncoherentModelException(coherence);
    }

    AndroidInitializationSettings androidInitializationSettings = AndroidInitializationSettings('notification_icon');
    IOSInitializationSettings iosInitializationSettings = IOSInitializationSettings();

    _flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(androidInitializationSettings, iosInitializationSettings),
    );

    if (halfTimeNotificationEnabled) {
      _scheduleHalfTimeNotification(context);
    }
    if (beforeEndNotificationEnabled) {
      _scheduleBeforeEndNotification(context);
    }
    _scheduleEndNotification(context);
  }

  /// Schedules the half-time notification.
  void _scheduleHalfTimeNotification(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime end = start.add(duration);
    HourMinuteSecond halftime = HourMinute.fromDuration(end.difference(now)).halfTime;

    IOSNotificationDetails iOSPlatformChannelSpecifics = IOSNotificationDetails();
    _flutterLocalNotificationsPlugin.schedule(
      _MANUAL_NOTIFICATION_1,
      AppLocalization.of(context).get('model.notification.halfTime.title'),
      _formatNotificationMessage(AppLocalization.of(context).get('model.notification.halfTime.message'), halftime),
      now.add(halftime.toDuration),
      NotificationDetails(_carParkManual, iOSPlatformChannelSpecifics),
    );
  }

  /// Schedules the before end notification.
  void _scheduleBeforeEndNotification(BuildContext context) {
    DateTime end = start.add(duration);

    IOSNotificationDetails iOSPlatformChannelSpecifics = IOSNotificationDetails();
    _flutterLocalNotificationsPlugin.schedule(
      _MANUAL_NOTIFICATION_2,
      AppLocalization.of(context).get('model.notification.beforeEnd.title'),
      _formatNotificationMessage(AppLocalization.of(context).get('model.notification.beforeEnd.message'), HourMinute.fromDuration(beforeEndNotificationDelay)),
      end.subtract(beforeEndNotificationDelay),
      NotificationDetails(_carParkManual, iOSPlatformChannelSpecifics),
    );
  }

  /// Schedules the end notification.
  void _scheduleEndNotification(BuildContext context) {
    IOSNotificationDetails iOSPlatformChannelSpecifics = IOSNotificationDetails();
    _flutterLocalNotificationsPlugin.schedule(
      _AUTOMATIC_NOTIFICATION,
      AppLocalization.of(context).get('model.notification.end.title'),
      _formatNotificationMessage(AppLocalization.of(context).get('model.notification.end.message'), HourMinute.fromDuration(duration)),
      start.add(duration),
      NotificationDetails(_carParkAutomatic, iOSPlatformChannelSpecifics),
    );
  }

  /// Formats a notification message.
  String _formatNotificationMessage(String message, HourMinute hour) => message.replaceAll('{time}', hour.toString());

  /// Cancels scheduled notifications.
  void cancelNotifications() {
    for (int id in [
      _MANUAL_NOTIFICATION_1,
      _MANUAL_NOTIFICATION_2,
      _AUTOMATIC_NOTIFICATION,
    ]) {
      _flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  /// Loads the model from storage.
  Future<bool> loadFromStorage([bool stopIfNotParked = false]) async {
    LocalStorage storage = LocalStorage(_PREFS_FILE);
    await storage.ready;

    bool parked = storage.getItem('parked');
    if (parked == null || (stopIfNotParked && !parked)) {
      return false;
    }

    List<String> latlng = storage.getItem('carPosition').split(':');
    carPosition = LatLng(double.parse(latlng[0]), double.parse(latlng[1]));
    start = DateTime.fromMillisecondsSinceEpoch(storage.getItem('start'));
    duration = Duration(
      milliseconds: storage.getItem('duration'),
    );
    halfTimeNotificationEnabled = storage.getItem('halfTimeNotificationEnabled');
    beforeEndNotificationEnabled = storage.getItem('beforeEndNotificationEnabled');
    beforeEndNotificationDelay = Duration(
      milliseconds: storage.getItem('beforeEndNotificationDelay'),
    );
    this.parked = parked;

    return true;
  }

  /// Saves the current model to storage.
  Future<void> saveToStorage() async {
    if (coherence != Coherence.COHERENT) {
      return;
    }

    LocalStorage storage = LocalStorage(_PREFS_FILE);
    await storage.ready;

    await storage.setItem('carPosition', carPosition.latitude.toString() + ':' + carPosition.longitude.toString());
    await storage.setItem('start', start.millisecondsSinceEpoch);
    await storage.setItem('duration', duration.inMilliseconds);
    await storage.setItem('halfTimeNotificationEnabled', halfTimeNotificationEnabled);
    await storage.setItem('beforeEndNotificationEnabled', beforeEndNotificationEnabled);
    await storage.setItem('beforeEndNotificationDelay', beforeEndNotificationDelay.inMilliseconds);
    await storage.setItem('parked', parked);
  }

  /// Removes the current model from the storage.
  Future<void> removeFromStorage() async {
    LocalStorage storage = LocalStorage(_PREFS_FILE);
    return storage.clear();
  }

  /// Returns the model coherence.
  Coherence get coherence {
    if (carPosition == null) {
      return Coherence.NULL_VALUES;
    }

    if (start.add(duration).isBefore(DateTime.now())) {
      return Coherence.END_BEFORE_NOW;
    }

    if (beforeEndNotificationEnabled && start.add(duration).subtract(beforeEndNotificationDelay).isBefore(DateTime.now())) {
      return Coherence.BEFORE_END_NOTIFICATION_BEFORE_NOW;
    }

    return Coherence.COHERENT;
  }

  /// Resets the model's fields.
  void reset() {
    carPosition = null;
    start = DateTime.now();
    duration = Duration(
      minutes: 30,
    );
    halfTimeNotificationEnabled = true;
    beforeEndNotificationEnabled = false;
    beforeEndNotificationDelay = Duration(
      minutes: 5,
    );
    parked = false;
  }
}

/// Allows to represent the model coherence.
enum Coherence {
  /// If there are values that should not be null.
  NULL_VALUES,

  /// If the park period ends before now.
  END_BEFORE_NOW,

  /// If the before end notification is before now.
  BEFORE_END_NOTIFICATION_BEFORE_NOW,

  /// If everything is okay.
  COHERENT,
}

/// Thrown when the model is incoherent.
class IncoherentModelException implements Exception {
  /// The coherence.
  final Coherence coherence;

  /// Creates a new incoherent model exception.
  IncoherentModelException(this.coherence);
}
