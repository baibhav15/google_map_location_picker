import 'package:flutter/material.dart';

class LocationNeededBottomModal {
  static const GOLDEN_RATIO = 1.25;
  static const H4Size = 12.0;
  static const H3Size = H4Size * GOLDEN_RATIO;
  static const H2Size = H3Size * GOLDEN_RATIO;
  static const H1Size = H2Size * GOLDEN_RATIO;
  static const H0Size = H1Size * 2;
  static const H5Size = H4Size / GOLDEN_RATIO;
  static const H6Size = H5Size / GOLDEN_RATIO;
  static Future show(BuildContext context) async {
    return showModalBottomSheet(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 5),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 15,
                  bottom: 15,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Location Needed',
                          style: TextStyle(color: Color(0xFF505050), fontSize: H2Size, fontWeight: FontWeight.w400),
                        ),
                        InkWell(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                              border: Border.all(color: Colors.grey, width: 1),
                            ),
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.grey,
                              size: 15,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 15 + 15,
                    ),
                    Image.asset(
                      "assets/icons/location_needed.png",
                      height: 150,
                    ),
                    SizedBox(
                      height: 15 + 15,
                    ),
                    Flexible(
                      child: Text(
                        "Because permission has been denied, we are unable to obtain your current location. Please close this dialogue and grant location permission.",
                        style: TextStyle(color: Color(0xFF505050), fontSize: H4Size, fontWeight: FontWeight.w400),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }
}
