import 'dart:async';

import 'package:car_park/app/style.dart';
import 'package:car_park/util/localization/localization.dart';
import 'package:car_park/util/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_permissions/location_permissions.dart';

/// A self updating map which can follow the user's position.
class SelfUpdatingMap extends StatefulWidget {
  /// The current position icon.
  final Icon currentPositionIcon;

  /// Callback for when the user changes its position.
  final Function(MapController, LatLng) locationUpdateCallback;

  /// Some additional markers.
  final List<Marker> additionalMarkers;

  /// Whether the map should be interactive.
  final bool interactive;

  /// Whether the map should follow the user's position.
  final bool followCurrentPosition;

  /// Creates a new self updating map instance.
  SelfUpdatingMap({
    this.currentPositionIcon,
    @required this.locationUpdateCallback,
    this.additionalMarkers = const [],
    this.interactive = false,
    this.followCurrentPosition = true,
  });

  /// Creates a new self updating map instance dedicated to be in fullscreen.
  SelfUpdatingMap.fullScreen({
    Icon currentPositionIcon,
    List<Marker> additionalMarkers = const [],
  }) : this(
          currentPositionIcon: currentPositionIcon,
          locationUpdateCallback: (controller, position) {},
          additionalMarkers: additionalMarkers,
          interactive: true,
          followCurrentPosition: false,
        );

  @override
  State<StatefulWidget> createState() => _SelfUpdatingMapState();
}

class _SelfUpdatingMapState extends State<SelfUpdatingMap> {
  /// The map controller.
  final MapController _controller = MapController();

  /// The stream.
  Stream<LatLng> _stream;

  /// The current permission status.
  PermissionStatus _permissionStatus;

  /// The stream subscription.
  StreamSubscription<LatLng> _subscription;

  /// The default position.
  LatLng _position;

  @override
  void initState() {
    super.initState();

    LocationPermissions().requestPermissions().then((status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (status == PermissionStatus.granted) {
          _registerStream();
        }

        if (mounted) {
          setState(() => _permissionStatus = status);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionStatus == PermissionStatus.denied) {
      return _createErrorWidget(context);
    }

    if (_position == null) {
      return AppCircularProgressIndicator();
    }

    return _createMapWidget(context);
  }

  /// Creates the error icon.
  Widget _createErrorWidget(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _createErrorMessage(context),
            _createAskButton(context),
            _createSettingsButton(context),
          ],
        ),
      );

  /// Creates the error message.
  Widget _createErrorMessage(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: Text(
          AppLocalization.of(context).get('localization.message'),
          style: Theme.of(context).textTheme.body2.copyWith(
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
      );

  /// Creates the button that allows to ask for permission.
  Widget _createAskButton(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: AppButton(
            text: AppLocalization.of(context).get('localization.button.ask'),
            color: AppStyle.BUTTON_COLOR_2,
            onPressed: () {
              LocationPermissions().requestPermissions(permissionLevel: LocationPermissionLevel.location).then((status) {
                if (status == PermissionStatus.granted) {
                  setState(() {
                    _permissionStatus = status;
                    _registerStream();
                  });
                }
              });
            }),
      );

  /// Creates the settings button.
  Widget _createSettingsButton(BuildContext context) => AppButton(
        text: AppLocalization.of(context).get('localization.button.settings'),
        color: AppStyle.BUTTON_COLOR_2,
        onPressed: () => LocationPermissions().openAppSettings(),
      );

  /// Creates the map widget.
  Widget _createMapWidget(BuildContext context) => FlutterMap(
        options: MapOptions(
          center: _position,
          zoom: 18,
          interactive: widget.interactive,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', // https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png is good too.
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(
            markers: []
              ..addAll(widget.additionalMarkers)
              ..add(
                Marker(
                  width: 40,
                  height: 40,
                  point: _position,
                  builder: (contact) => widget.currentPositionIcon,
                ),
              ),
          )
        ],
        mapController: _controller,
      );

  /// Registers the stream.
  void _registerStream() {
    Geolocator geolocator = Geolocator();
    _stream = geolocator
        .getPositionStream(LocationOptions(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 1,
        ))
        .map(
          (location) => LatLng(location.latitude, location.longitude),
        );
    geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation).then((position) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onPositionUpdate(LatLng(position.latitude, position.longitude));

        _subscription = _stream.listen((newPosition) {
          _onPositionUpdate(LatLng(newPosition.latitude, newPosition.longitude));
        });
      });
    });
  }

  /// Triggered when the position is updated.
  void _onPositionUpdate(LatLng position) {
    if (widget.followCurrentPosition && _controller.ready) {
      _controller.move(position, 18);
    }
    widget.locationUpdateCallback(_controller, position);

    if (!mounted) {
      return;
    }

    setState(() {
      _position = position;
    });
  }
}

/// Allows widgets to hold a fullscreen self updating map.
abstract class FullScreenSelfUpdatingMapWidgetState<T extends StatefulWidget> extends State<T> {
  /// Whether we're currently in fullscreen.
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) => _isFullScreen ? fullScreenContent : nonFullScreenContent;

  /// Returns the self updating map.
  SelfUpdatingMap get map;

  /// Returns the fullscreen content.
  Widget get fullScreenContent => WillPopScope(
        child: Stack(
          children: [
            Positioned.fill(
              child: SelfUpdatingMap.fullScreen(
                currentPositionIcon: map.currentPositionIcon,
                additionalMarkers: map.additionalMarkers,
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 10,
                ),
                child: Text(
                  '© rastertiles/voyager',
                  style: Theme.of(context).textTheme.body2.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _FlatButtonIcon(
                icon: Icons.fullscreen_exit,
                onTap: () => setState(() => _isFullScreen = false),
              ),
            ),
          ],
        ),
        onWillPop: _onWillPop,
      );

  /// Returns the non full screen content.
  Widget get nonFullScreenContent;

  /// Returns the current self updating map with buttons.
  Widget get mapWithButton => Stack(
        children: [
          Positioned.fill(
            child: map,
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: _FlatButtonIcon(
              icon: Icons.fullscreen,
              onTap: () => setState(() => _isFullScreen = true),
            ),
          ),
        ],
      );

  /// Triggered when the user try to push the "back" button.
  Future<bool> _onWillPop() async {
    setState(() => _isFullScreen = false);
    return false;
  }
}

/// A simple round flat button icon.
class _FlatButtonIcon extends StatelessWidget {
  /// The icon.
  final IconData icon;

  /// The on tap callback.
  final GestureTapCallback onTap;

  /// Creates a new flat button icon instance.
  _FlatButtonIcon({this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.black12,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 30,
          ),
        ),
      );
}
