
class ChatMessage {
  String body;
  String userName;
  String userProfilePhoto;
  String userId;
  DateTime dateCreated;
  String displayType;

  ChatMessage({this.body, this.userName, this.userProfilePhoto, this.userId, this.dateCreated, this.displayType});

  dynamic toJSON() {
    return {
      "body": body,
      "userId": userId,
      "userName": userName,
      "userProfilePhoto": userProfilePhoto,
      "dateCreated": dateCreated.toIso8601String(),
      "displayType": displayType,
    };
  }

  static ChatMessage fromJSON(dynamic json) {
    return ChatMessage(
      body: json["body"],
      userId: json["userId"],
      userName: json["userName"],
      userProfilePhoto: json["userProfilePhoto"],
      dateCreated: DateTime.parse(json["dateCreated"]),
      displayType: json["displayType"],
    );
  }
}
