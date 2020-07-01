class DistressSignal {
  int id;
  String details;
  double lat;
  double lon;

  DistressSignal({this.id, this.details, this.lat, this.lon});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "details": details,
      "lat": lat,
      "lon": lon,
    };
  }

  static DistressSignal fromJSON(dynamic json) {
    return DistressSignal(
      id: json["id"],
      details: json["details"],
      lat: json["lat"],
      lon: json["lon"],
    );
  }
}
