import 'dart:async';
import 'dart:convert';
import 'dart:math';
//import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_map_location_picker/components/location_needed.dart';
import 'package:google_map_location_picker/generated/l10n.dart';
import 'package:google_map_location_picker/src/providers/location_provider.dart';
import 'package:google_map_location_picker/src/radius_selection.dart';
import 'package:google_map_location_picker/src/utils/loading_builder.dart';
import 'package:google_map_location_picker/src/utils/log.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'model/location_result.dart';
import 'utils/location_utils.dart';

Color primaryColor = Color(0xFF0e52d6);
Color primaryColorLight = Color(0xFF02c2fa);
Color bgColorNew = Color(0xFFFAFAFA);

class MapPicker extends StatefulWidget {
  const MapPicker(
    this.apiKey, {
    Key? key,
    this.initialCenter,
    this.initialZoom,
    this.requiredGPS,
    this.myLocationButtonEnabled,
    this.layersButtonEnabled,
    this.automaticallyAnimateToCurrentLocation,
    this.mapStylePath,
    this.appBarColor,
    this.searchBarBoxDecoration,
    this.hintText,
    this.resultCardConfirmIcon,
    this.resultCardAlignment,
    this.resultCardDecoration,
    this.resultCardPadding,
    this.language,
    this.desiredAccuracy,
    this.option,
  }) : super(key: key);

  final int? option;

  final String apiKey;

  final LatLng? initialCenter;
  final double? initialZoom;

  final bool? requiredGPS;
  final bool? myLocationButtonEnabled;
  final bool? layersButtonEnabled;
  final bool? automaticallyAnimateToCurrentLocation;

  final String? mapStylePath;

  final Color? appBarColor;
  final BoxDecoration? searchBarBoxDecoration;
  final String? hintText;
  final Widget? resultCardConfirmIcon;
  final Alignment? resultCardAlignment;
  final Decoration? resultCardDecoration;
  final EdgeInsets? resultCardPadding;

  final String? language;

  final LocationAccuracy? desiredAccuracy;

  @override
  MapPickerState createState() => MapPickerState();
}

class MapPickerState extends State<MapPicker> {
  static const GOLDEN_RATIO = 1.25;
  static const H4Size = 10.5;
  static const H3Size = H4Size * GOLDEN_RATIO;
  static const H2Size = H3Size * GOLDEN_RATIO;
  static const H1Size = H2Size * GOLDEN_RATIO;
  static const H5Size = H4Size / GOLDEN_RATIO;
  static const H6Size = H5Size / GOLDEN_RATIO;

  Completer<GoogleMapController> mapController = Completer();

  MapType _currentMapType = MapType.normal;

  String? _mapStyle;

  LatLng? _lastMapPosition;

  Position? _currentPosition;

  String? _address;

  String? _placeId;

  void _onToggleMapTypePressed() {
    MapType nextType = MapType.values[(_currentMapType.index + 1) % MapType.values.length];
    if(nextType==MapType.none){
      nextType = MapType.normal;
    }
    setState(() => _currentMapType = nextType);
  }

  Future? _locationDialog;

  _checkAndShowDialogLocation(BuildContext context) async {
    if (_locationDialog == null) {
      _locationDialog = LocationNeededBottomModal.show(context);
      await _locationDialog;
      _locationDialog = null;
      await Geolocator.openAppSettings();
    } else {
      //do nothing
    }
  }

  // this also checks for location permission.
  Future<void> _initCurrentLocation(bool btnPress) async {
    Position? currentPosition;
    LocationPermission permission;
    bool serviceEnabled;
    try {
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permissions are denied, next time you could try
          // requesting permissions again (this is also where
          // Android's shouldShowRequestPermissionRationale
          // returned true. According to Android guidelines
          // your App should show an explanatory UI now.
          // _checkAndShowDialogLocation(context);
          //return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        if (btnPress) _checkAndShowDialogLocation(context);

        /*if (permission == LocationPermission.deniedForever) {
          return Future.error('Location permissions are permanently denied, we cannot request permissions.');
        }*/
      }
    } catch (e) {}
    try {
      currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: widget.desiredAccuracy!);
      d("position = $currentPosition");

      setState(() => _currentPosition = currentPosition);
    } catch (e) {
      currentPosition = null;
      d("_initCurrentLocation#e = $e");
    }
    /* serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
        // Location services are not enabled don't continue
        // accessing the position and request users of the
        // App to enable the location services.
        //return Future.error('Location services are disabled.');
        await Geolocator.openLocationSettings();
        if (!serviceEnabled) {
          return Future.error('Location services are disabled.');
        }else{
          try {
            currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: widget.desiredAccuracy!);
            d("position = $currentPosition");

            setState(() => _currentPosition = currentPosition);
          } catch (e) {
            currentPosition = null;
            d("_initCurrentLocation#e = $e");
          }
        }
      }*/

    if (!mounted) return;

    setState(() => _currentPosition = currentPosition);
    if (widget.option == 2) {
      setState(() {
        circles.clear();
        circles.add(
          Circle(
              circleId: CircleId("1"),
              center: LatLng(currentPosition!.latitude, currentPosition.longitude),
              radius: circleRadius,
              strokeColor: primaryColor,
              fillColor: Color(0x220e52d6),
              strokeWidth: 1),
        );
        getZoomLevel();
      });
    }

    if (currentPosition != null) moveToCurrentLocation(LatLng(currentPosition.latitude, currentPosition.longitude));
  }

  updateRadius(double radius) {
    circleRadius = radius;
    print("RADIUS = " + radius.toString());
    /*if (radius == 0) {
      circles.clear();
      setState(() {
        getZoomLevel();
      });
    } else {
      circles.clear();
      setState(() {
        circles.add(
          Circle(
            circleId: CircleId("2"),
            center: _lastMapPosition,
            radius: radius,
            strokeColor: primaryColor,
            fillColor: Color(0x220e52d6),
            strokeWidth: 1,
          ),
        );
        getZoomLevel();
      });
    }*/
    circles.clear();
    if (radius != 0) {
      circles.add(
        Circle(
          circleId: CircleId("2"),
          center: _lastMapPosition!,
          radius: radius,
          strokeColor: primaryColor,
          fillColor: Color(0x220e52d6),
          strokeWidth: 1,
        ),
      );
    }
    getZoomLevel();
    print("CIRC  = " + circles.toString());
    moveToCurrentLocation(LatLng(_lastMapPosition!.latitude, _lastMapPosition!.longitude));
  }

  double zoomLevel = 16;
  double circleRadius = 10000;
  getZoomLevel() {
    if (circles.isNotEmpty) {
      //    if (circles.first != null) {
      double radius = circles.first.radius;
      double scale = radius / 500;
      zoomLevel = (16 - log(scale) / log(2)) - 0.5;
      //   }
      print("zoom called = " + zoomLevel.toString());
      return zoomLevel;
    } else {
      return 16;
    }
  }

  Future moveToCurrentLocation(LatLng currentLocation) async {
    d('MapPickerState.moveToCurrentLocation "currentLocation = [$currentLocation]"');
    final controller = await mapController.future;
    print("new camera called = " + zoomLevel.toString());
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: currentLocation, zoom: zoomLevel),
    ));
  }

  @override
  void initState() {
    super.initState();
    if (widget.automaticallyAnimateToCurrentLocation! && !widget.requiredGPS!) _initCurrentLocation(false);

    if (widget.mapStylePath != null) {
      rootBundle.loadString(widget.mapStylePath!).then((string) {
        _mapStyle = string;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.requiredGPS!) {
      _checkGeolocationPermission();
      if (_currentPosition == null) _initCurrentLocation(false);
    }

    if (_currentPosition != null && dialogOpen != null) Navigator.of(context, rootNavigator: true).pop();

    return Scaffold(
      body: Builder(
        builder: (context) {
          if (_currentPosition == null && widget.automaticallyAnimateToCurrentLocation! && widget.requiredGPS!) {
            return const Center(child: CircularProgressIndicator());
          }

          return buildMap();
        },
      ),
    );
  }

  Set<Circle> circles = Set.from([]);
  Widget buildMap() {
    return Center(
      child: Stack(
        children: <Widget>[
          GoogleMap(
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            initialCameraPosition: CameraPosition(
              target: widget.initialCenter!,
              zoom: widget.initialZoom!,
            ),
            circles: circles,
            onMapCreated: (GoogleMapController controller) {
              mapController.complete(controller);
              //Implementation of mapStyle
              if (widget.mapStylePath != null) {
                controller.setMapStyle(_mapStyle);
              }

              _lastMapPosition = widget.initialCenter;
              LocationProvider.of(context, listen: false).setLastIdleLocation(_lastMapPosition);
            },
            onCameraMove: (CameraPosition position) {
              _lastMapPosition = position.target;
            },
            onCameraIdle: () async {
              print("onCameraIdle#_lastMapPosition = $_lastMapPosition");
              LocationProvider.of(context, listen: false).setLastIdleLocation(_lastMapPosition);
              if (widget.option == 2) {
                setState(() {
                  circles.clear();
                  circles.add(
                    Circle(
                      circleId: CircleId("2"),
                      center: _lastMapPosition!,
                      radius: circleRadius,
                      strokeColor: primaryColor,
                      fillColor: Color(0x220e52d6),
                      strokeWidth: 1,
                    ),
                  );
                });
              }
            },
            onCameraMoveStarted: () {
              print("onCameraMoveStarted#_lastMapPosition = $_lastMapPosition");
            },

//            onTap: (latLng) {
//              clearOverlay();
//            },
            mapType: _currentMapType,
            myLocationEnabled: true,
          ),
          _MapFabs(
            myLocationButtonEnabled: widget.myLocationButtonEnabled,
            layersButtonEnabled: widget.layersButtonEnabled,
            onToggleMapTypePressed: _onToggleMapTypePressed,
            onMyLocationPressed: () {
              _initCurrentLocation(true);
            },
          ),
          pin(),
          locationCard(),
        ],
      ),
    );
  }

  Widget locationCard() {
    return Align(
      alignment: widget.resultCardAlignment ?? Alignment.bottomCenter,
      child: Column(
        children: [
          widget.option == 2
              ? Container(
                  margin: EdgeInsets.only(left: 10, right: 10),
                  child: RadiusSelection(
                    mapKey: widget.key,
                  ),
                )
              : SizedBox(height: 0),
          Padding(
            padding: widget.resultCardPadding ?? EdgeInsets.all(0.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[bgColorNew, bgColorNew],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
              padding: EdgeInsets.only(right: 15, left: 15, top: 10, bottom: 10),
              width: double.infinity,
              child: Consumer<LocationProvider>(builder: (context, locationProvider, _) {
                return Padding(
                  padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        flex: 20,
                        child: FutureLoadingBuilder<Map<String, String?>?>(
                          future: getAddress(locationProvider.lastIdleLocation),
                          mutable: true,
                          loadingIndicator: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              CircularProgressIndicator(
                                valueColor: new AlwaysStoppedAnimation<Color>(primaryColor),
                                strokeWidth: 2,
                              ),
                            ],
                          ),
                          builder: (context, data) {
                            _address = data!["address"];
                            _placeId = data["placeId"];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ADDRESS',
                                  style: TextStyle(color: Color(0xFF4D4D4D), fontSize: H5Size, fontWeight: FontWeight.w400),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  _address ?? S.of(context)?.unnamedPlace ?? 'Unnamed place',
                                  style: TextStyle(color: Color(0xFF505050), fontSize: H4Size, fontWeight: FontWeight.w400),
                                ),
                                /* SizedBox(height: 5),
                                Text(
                                  'This allows the Q-expert to navigate properly',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w400),
                                ),*/
                              ],
                              mainAxisSize: MainAxisSize.min,
                            );
                          },
                        ),
                      ),
                      Spacer(),
                      Spacer(),
                      InkWell(
                        child: Container(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'NEXT',
                                style: TextStyle(color: primaryColor, fontSize: H4Size, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(
                                width: 2,
                              ),
                              Icon(
                                Icons.navigate_next,
                                size: 20,
                                color: primaryColor,
                              ),
                            ],
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                          ),
                          height: 50,
                        ),
                        onTap: () {
                          Navigator.of(context).pop({
                            'location': LocationResult(
                                latLng: locationProvider.lastIdleLocation, address: _address, placeId: _placeId, radius: circleRadius)
                          });
                        },
                      ),
                      /*FloatingActionButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'location': LocationResult(
                          latLng: locationProvider.lastIdleLocation,
                          address: _address,
                          placeId: _placeId,
                        )
                      });
                    },
                    child: widget.resultCardConfirmIcon ?? Icon(Icons.arrow_forward),
                  ),*/
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }

  Future<Map<String, String?>> getAddress(LatLng? location) async {
    try {
      final endPoint = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location?.latitude},${location?.longitude}'
          '&key=${widget.apiKey}&language=${widget.language}';

      var response = jsonDecode((await http.get(Uri.parse(endPoint), headers: await (LocationUtils.getAppHeaders()))).body);

      return {"placeId": response['results'][0]['place_id'], "address": response['results'][0]['formatted_address']};
    } catch (e) {
      print(e);
    }

    return {"placeId": null, "address": null};
  }

  Widget pin() {
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset("assets/icons/logo_shape.png", height: 40, width: 40),
            Container(
              decoration: ShapeDecoration(
                shadows: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black38,
                  ),
                ],
                shape: CircleBorder(
                  side: BorderSide(
                    width: 4,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
            SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  var dialogOpen;

  Future _checkGeolocationPermission() async {
    final geolocationStatus = await Geolocator.checkPermission();
    d("geolocationStatus = $geolocationStatus");

    if (geolocationStatus == LocationPermission.denied && dialogOpen == null) {
      dialogOpen = _showDeniedDialog();
    } else if (geolocationStatus == LocationPermission.deniedForever && dialogOpen == null) {
      dialogOpen = _showDeniedForeverDialog();
    } else if (geolocationStatus == LocationPermission.whileInUse || geolocationStatus == LocationPermission.always) {
      d('GeolocationStatus.granted');

      if (dialogOpen != null) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogOpen = null;
      }
    }
  }

  Future _showDeniedDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context, rootNavigator: true).pop();
            return true;
          },
          child: AlertDialog(
            title: Text(S.of(context)?.access_to_location_denied ?? 'Access to location denied'),
            content: Text(S.of(context)?.allow_access_to_the_location_services ?? 'Allow access to the location services.'),
            actions: <Widget>[
              TextButton(
                child: Text(S.of(context)?.ok ?? 'Ok'),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _initCurrentLocation(false);
                  dialogOpen = null;
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future _showDeniedForeverDialog() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context, rootNavigator: true).pop();
            return true;
          },
          child: AlertDialog(
            title: Text(S.of(context)?.access_to_location_permanently_denied ?? 'Access to location permanently denied'),
            content: Text(S.of(context)?.allow_access_to_the_location_services_from_settings ??
                'Allow access to the location services for this App using the device settings.'),
            actions: <Widget>[
              TextButton(
                child: Text(S.of(context)?.ok ?? 'Ok'),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  Geolocator.openAppSettings();
                  dialogOpen = null;
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // TODO: 9/12/2020 this is no longer needed, remove in the next release
  /*Future _checkGps() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context)?.cant_get_current_location ?? "Can't get current location"),
              content: Text(S.of(context)?.please_make_sure_you_enable_gps_and_try_again ?? 'Please make sure you enable GPS and try again'),
              actions: <Widget>[
                TextButton(
                  child: Text('Ok'),
                  onPressed: () {
                    final AndroidIntent intent = AndroidIntent(action: 'android.settings.LOCATION_SOURCE_SETTINGS');

                    intent.launch();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  } */
}

class _MapFabs extends StatelessWidget {
  const _MapFabs({
    Key? key,
    required this.myLocationButtonEnabled,
    required this.layersButtonEnabled,
    required this.onToggleMapTypePressed,
    required this.onMyLocationPressed,
  }) : super(key: key);

  final bool? myLocationButtonEnabled;
  final bool? layersButtonEnabled;

  final VoidCallback onToggleMapTypePressed;
  final VoidCallback onMyLocationPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topRight,
      margin: const EdgeInsets.only(top: kToolbarHeight + 40, right: 8),
      child: Column(
        children: <Widget>[
          if (layersButtonEnabled!)
            FloatingActionButton(
              backgroundColor: primaryColor,
              onPressed: onToggleMapTypePressed,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              mini: true,
              child: const Icon(Icons.layers, color: Colors.white),
              heroTag: "layers",
            ),
          if (myLocationButtonEnabled!)
            FloatingActionButton(
              backgroundColor: primaryColor,
              onPressed: onMyLocationPressed,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              mini: true,
              child: const Icon(Icons.my_location, color: Colors.white),
              heroTag: "myLocation",
            ),
        ],
      ),
    );
  }
}
