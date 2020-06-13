class User {
  String id;

  String status;
  String firstName;
  String lastName;
  String phoneNumber;
  String emailAddress;
  String authKey;
  String role;
  String gender;
  String profilePhoto;

  String dateOfBirth;

  User({
    this.id,
    this.status,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.emailAddress,
    this.authKey,
    this.role,
    this.gender,
    this.dateOfBirth,
    this.profilePhoto,
  });

  static User fromJson(Map<String, dynamic> json) {
    return User(
        id: json["id"],
        firstName: json["firstName"] ?? "",
        lastName: json["lastName"] ?? "",
        phoneNumber: json["phoneNumber"] ?? "",
        emailAddress: json["emailAddress"] ?? "",
        status: json["status"] ?? "",
        role: json["role"] ?? "",
        gender: json["gender"] ?? "",
        dateOfBirth: json["dateOfBirth"] ?? "",
        profilePhoto: json["profilePhoto"] ?? "");
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
      'id': id,
      'dateOfBirth': dateOfBirth,
      'role': role,
      'gender': gender,
      'status': status,
      'profilePhoto': profilePhoto,
    };
  }
}

enum GenderConstant { MALE, FEMALE }

extension ParseToString on GenderConstant {
  String toShortString() {
    return this.toString().split('.').last;
  }
}