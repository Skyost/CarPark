import 'package:car_park/app/model.dart';
import 'package:car_park/app/style.dart';
import 'package:car_park/util/localization/localization.dart';
import 'package:car_park/util/self_updating_map.dart';
import 'package:car_park/util/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// The start page, where the user can see its location and go to the next screen.
class StartPage extends StatefulWidget {
  /// The current model instance.
  final CarParkModel _model;

  /// Creates a new start page instance.
  StartPage(this._model);

  @override
  State<StatefulWidget> createState() => _StartPageState(_model);
}

/// The start page state.
class _StartPageState extends FullScreenSelfUpdatingMapWidgetState<StartPage> {
  /// The self updating map instance.
  SelfUpdatingMap _map;

  /// Whether the state is currently loading.
  bool _loading;

  /// Creates a new start page state instance.
  _StartPageState(CarParkModel _model) : _loading = true {
    _map = SelfUpdatingMap(
      currentPositionIcon: Icon(
        Icons.directions_car,
        size: 40,
        color: Colors.teal,
      ),
      locationUpdateCallback: (controller, position) => _model.carPosition = position,
    );
  }

  @override
  SelfUpdatingMap get map => _map;

  @override
  Widget get nonFullScreenContent => _loading ? AppCircularProgressIndicator() : _createListView(context);

  @override
  void initState() {
    super.initState();

    widget._model.loadFromStorage(true).then((success) {
      setState(() {
        _loading = false;
      });

      if (success) {
        SchedulerBinding.instance.addPostFrameCallback((_) => Navigator.pushReplacementNamed(context, '/time'));
        widget._model.removeFromStorage();
      }
    });
  }

  /// Creates the list view.
  Widget _createListView(BuildContext context) => PageListView(
        content: Column(
          children: [
            _createMapContainer(context),
            _createNextButton(context),
          ],
        ),
      );

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

  /// Creates the next button.
  Widget _createNextButton(BuildContext context) => Container(
        height: MediaQuery.of(context).size.longestSide - MediaQuery.of(context).padding.top - CarParkAppBar.HEIGHT - _calculateMapContainerHeight(context) - 24,
        padding: EdgeInsets.all(40),
        child: Center(
          child: AppButton(
            text: AppLocalization.of(context).get('start.next'),
            onPressed: () {
              if (widget._model.coherence == Coherence.NULL_VALUES) {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(
                    AppLocalization.of(context).get('localization.message').split('\n')[0],
                  ),
                  backgroundColor: AppStyle.SNACKBAR_ERROR_COLOR,
                ));
                return;
              }

              Navigator.pushReplacementNamed(context, '/time');
            },
          ),
        ),
      );

  /// Calculates the map container height.
  double _calculateMapContainerHeight(BuildContext context) => MediaQuery.of(context).size.shortestSide - MediaQuery.of(context).padding.top - CarParkAppBar.HEIGHT;
}
