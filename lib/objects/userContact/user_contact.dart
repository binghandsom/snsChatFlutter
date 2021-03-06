// Why UserContact is needed if it can be merged into User itself?
// Because I need to create a table that has unknown contact numbers(those who hasn't registered as User)
class UserContact {
  String id;

  String displayName;

  String realName;

  String about;

  // TODO: Move it to User, declare it as UserContactIds, which means how many contact does this User own.
  // This UserContact is belonged to which user IN PHONE STORAGE?
  List<String> userIds;

  String userId; // This UserContact is what user in USER TABLE?

  // Mobile number of the User/Stranger. Will use a method to determine the phone number's origin country. (Require to do strict validation during sign up + SMS verification)
  String mobileNo;

  int lastSeenDate;

  bool block;

  // Show the user's picture. Uses the multimedia from the User itself. Show default user picture for strangers.
  String multimediaId;

  UserContact(
      {this.id,
      this.displayName,
      this.realName,
      this.about,
      this.userIds,
      this.userId,
      this.mobileNo,
      this.lastSeenDate,
      this.block,
      this.multimediaId});

  factory UserContact.fromJson(Map<String, dynamic> json) {
    UserContact userContact = UserContact(
      id: json['id'],
      displayName: json['displayName'],
      realName: json['realName'],
      about: json['about'],
      userId: json['userId'],
      mobileNo: json['mobileNo'],
      lastSeenDate: json['lastSeenDate'],
      block: json['block'],
      multimediaId: json['multimediaId'],
    );

    var userIdsFromJson = json['userIds'];

    List<String> userIds = new List<String>.from(userIdsFromJson);
    userContact.userIds = userIds;

    return userContact;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'realName': realName,
        'about': about,
        'userId': userId,
        'userIds': userIds,
        'mobileNo': mobileNo,
        'lastSeenDate': lastSeenDate,
        'block': block,
        'multimediaId': multimediaId,
      };
}
