import 'package:cryout_app/models/received-distress-signal.dart';
import 'package:cryout_app/utils/widget-utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ViewDistressLocationOnMapScreen extends StatefulWidget {
  final ReceivedDistressSignal distressSignal;

  const ViewDistressLocationOnMapScreen({Key key, this.distressSignal}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ViewDistressLocationOnMapScreenState(distressSignal);
  }
}

class _ViewDistressLocationOnMapScreenState extends State {
  final ReceivedDistressSignal distressSignal;
  GoogleMapController mapController;

  _ViewDistressLocationOnMapScreenState(this.distressSignal);

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    LatLng position = LatLng(double.parse(distressSignal.location.split(",")[0]), double.parse(distressSignal.location.split(",")[1]));

    return AnnotatedRegion(
      value: WidgetUtils.updateSystemColors(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Distress Signal Location'),
          backgroundColor: Colors.green[700],
          brightness: Brightness.dark,
          elevation: 1,
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: 11.0,
          ),
          markers: {
            Marker(
              markerId: MarkerId(distressSignal.distressId),
              draggable: false,
              position: position,
              infoWindow: InfoWindow(
                title: distressSignal.detail,
                snippet: "${distressSignal.firstName} ${distressSignal.lastName.substring(0, 1)}. | ${distressSignal.distance}km | ${distressSignal.gender.toLowerCase()}",
              ),
            )
          },
        ),
      ),
    );
  }
}
