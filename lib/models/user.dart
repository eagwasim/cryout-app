class User {
  String id;

  String status;
  String firstName;
  String lastName;
  String phoneNumber;
  String authKey;
  String gender;
  String profilePhoto;

  String dateOfBirth;

  User({
    this.id,
    this.status,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.authKey,
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
        status: json["status"] ?? "",
        gender: json["gender"] ?? "",
        dateOfBirth: json["dateOfBirth"] ?? "",
        profilePhoto: json["profilePhoto"] ?? "");
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'id': id,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'status': status,
      'profilePhoto': profilePhoto,
    };
  }

  String shortName() {
    return "${firstName + " " + lastName.substring(0, 1)}.";
  }

  String fullName() {
    return "${firstName + " " + lastName}";
  }

  String genderPronoun() {
    if (gender == "MALE") {
      return "his";
    }

    if (gender == "FEMALE") {
      return "her";
    }

    return "their";
  }

  String getWalkingImageAsset() {
    if (gender == "MALE") {
      return "assets/images/male_walking.png";
    }

    if (gender == "FEMALE") {
      return "assets/images/female_walking.png";
    }

    return "assets/images/female_walking.png";
  }
}

enum GenderConstant { MALE, FEMALE, NON_BINARY }

extension ParseToString on GenderConstant {
  String toShortString() {
    return this.toString().split('.').last;
  }
}
