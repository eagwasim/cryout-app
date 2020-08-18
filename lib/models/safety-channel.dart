class SafetyChannel {
  int id;
  String name;
  String description;
  String creatorName;
  String creatorId;
  String creatorImage;
  String latestPostText;
  String role;
  String city;
  String country;
  int subscriberCount;
  int latestPostId;

  String dateCreated;
  String dateModified;

  SafetyChannel({
    this.id,
    this.name,
    this.description,
    this.creatorName,
    this.creatorId,
    this.latestPostText,
    this.role,
    this.city,
    this.country,
    this.subscriberCount,
    this.latestPostId,
    this.dateCreated,
    this.dateModified,
    this.creatorImage,
  });

  dynamic toJSON() {
    return {
      "id": this.id,
      "name": this.name,
      "description": this.description,
      "creatorName": this.creatorName,
      "creatorId": this.creatorId,
      "latestPostText": this.latestPostText,
      "role": this.role,
      "city": this.city,
      "country": this.country,
      "subscriberCount": this.subscriberCount,
      "latestPostId": this.latestPostId,
      "dateCreated": this.dateCreated,
      "dateModified": this.dateModified,
      "creatorImage": this.creatorImage,
    };
  }

  static SafetyChannel fromJSON(dynamic json) {
    return SafetyChannel(
        id: json["id"],
        name: json["name"],
        description: json["description"],
        creatorName: json["creatorName"],
        creatorId: json["creatorId"],
        latestPostText: json["latestPostText"],
        role: json["role"],
        city: json["city"],
        country: json["country"],
        subscriberCount: json["subscriberCount"],
        latestPostId: json["latestPostId"],
        dateCreated: json["dateCreated"],
        dateModified: json["dateModified"],
        creatorImage: json["creatorImage"]);
  }
}
