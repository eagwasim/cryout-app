class DistressCall {
  int id;
  String details;
  double lat;
  double lon;

  DistressCall({this.id, this.details, this.lat, this.lon});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "details": details,
      "lat": lat,
      "lon": lon,
    };
  }

  static DistressCall fromJSON(dynamic json) {
    return DistressCall(
      id: json["id"],
      details: json["details"],
      lat: json["lat"],
      lon: json["lon"],
    );
  }
}
