import 'package:connectivity/connectivity.dart';

class BaseResource {
  static const Map<String, String> HEADERS = {"Content-type": "application/json"};

  //static const BASE_URL = "https://cry-out.ew.r.appspot.com";
  static const BASE_URL = "https://cryout.app";
  static const int STATUS_OK = 200;
  static const int STATUS_CREATED = 201;
  static const int STATUS_CONFLICT = 409;
  static const int STATUS_BAD_REQUEST = 400;
  static const int STATUS_SERVICE_UNAVAILABLE = 503;

  static Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }
}
