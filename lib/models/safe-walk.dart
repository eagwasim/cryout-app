class SafeWalk {
  int id;
  String destination;
  String lastKnownLocation;

  SafeWalk({this.id, this.destination, this.lastKnownLocation});

  static SafeWalk fromJSON(dynamic json) {
    return SafeWalk(id: json["id"], destination: json["destination"], lastKnownLocation: json["lastKnownLocation"]);
  }

  Map<String, dynamic> toJson() {
    return {"id": id, "destination": destination, "lastKnownLocation": lastKnownLocation};
  }
}
