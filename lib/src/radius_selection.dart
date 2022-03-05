import 'package:flutter/material.dart';

class RadiusSelection extends StatefulWidget {
  RadiusSelection({
    Key? key,
    required this.mapKey
  }) : super(key: key);
  final Key? mapKey;
  @override
  _RadiusSelectionState createState() => _RadiusSelectionState(mapKey);
}

class _RadiusSelectionState extends State<RadiusSelection> {
  double radius = 10.0;
  var mapKey;
  _RadiusSelectionState(this.mapKey);
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          child: Text(
            "Choose Radius",
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(height: 10),
        Slider(
          inactiveColor: Color(0xFF3c3c3c),
          activeColor: Color(0xFF00319c),
          max: 50,
          divisions: 50,
          onChanged: (double value) {
            value = value.roundToDouble();
            setState(
              () {
                radius = value;
                updateZoom();
              },
            );
          },
          value: radius,
        ),
        Row(
          children: [
            SizedBox(width: 5),
            Text(
              "0 K.M.",
              style: TextStyle(color:  Colors.black54,fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: Center(
                child: Text(radius.toStringAsFixed(0) + " K.M."),
              ),
            ),
            Text(
              "50 K.M.",
              style: TextStyle(color:  Colors.black54,fontSize: 10.5, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 5),
          ],
        ),
      ],
    );
  }

  void updateZoom() {
    mapKey.currentState.updateRadius(radius*1000);
  }
}
