class SearchChannel {
  int id;
  String name;
  String creatorName;
  String city;
  String country;

  SearchChannel({this.id, this.name, this.creatorName, this.city, this.country});

  static SearchChannel fromJSON(dynamic json) {
    return SearchChannel(
      id: json["id"],
      name: json["name"],
      creatorName: json["creatorName"],
      city: json["city"],
      country: json["country"],
    );
  }
}
