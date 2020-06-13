class ReceivedDistressSignal {
  String age;
  String detail;
  String date;
  String distressId;
  String firstName;
  String lastName;
  String gender;
  String phone;
  String photo;
  String userId;
  String distance;
  String location;

  ReceivedDistressSignal({
    this.age,
    this.detail,
    this.date,
    this.distressId,
    this.firstName,
    this.lastName,
    this.gender,
    this.phone,
    this.photo,
    this.userId,
    this.distance,
    this.location,
  });

  Map<String, dynamic> toJSON() {
    return {
      "age": age,
      "detail": detail,
      "date": date,
      "distressId": distressId,
      "firstName": firstName,
      "lastName": lastName,
      "gender": gender,
      "phone": phone,
      "photo": photo,
      "userId": userId,
      "distance": distance,
      "location": location,
    };
  }

  static ReceivedDistressSignal fromJSON(dynamic json) {
    return ReceivedDistressSignal(
      age: json["age"],
      detail: json["detail"],
      date: json["date"],
      distressId: json["distressId"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      gender: json["gender"],
      phone: json["phone"],
      photo: json["photo"],
      userId: json["userId"],
      distance: json["distance"],
      location: json["location"],
    );
  }
}
