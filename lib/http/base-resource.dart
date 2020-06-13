

class BaseResource {
  static const Map<String, String> HEADERS = {"Content-type": "application/json"};
  static const BASE_URL = "https://cry-out.ew.r.appspot.com";

  static const int STATUS_OK = 200;
  static const int STATUS_CREATED = 201;
  static const int STATUS_CONFLICT = 409;
  static const int STATUS_BAD_REQUEST = 400;
  static const int STATUS_SERVICE_UNAVAILABLE = 503;
}
