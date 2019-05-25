import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:snschat_flutter/general/functions/repeating_functions.dart';
import 'package:snschat_flutter/objects/settings/settings.dart';

class User {
  String id;
  String displayName;
  String realName;
  String userId;
  String mobileNo;
  String settingsId; // Settings
  // Cannot initialize anything here for flutter_bloc
  FirebaseUser firebaseUser;

  //  FirebaseAuth firebaseAuth; // = FirebaseAuth.instance;
  //  GoogleSignIn googleSignIn; // = new GoogleSignIn();

  User({
    this.id,
    this.displayName,
    this.realName,
    this.userId,
    this.mobileNo,
    this.settingsId,
    this.firebaseUser,
//      this.googleSignIn,
//      this.firebaseAuth
  });

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        displayName = json['displayName'],
        realName = json['realName'],
        userId = json['userId'],
        mobileNo = json['mobileNo'],
        settingsId = json['settingsId'],
        firebaseUser = json['firebaseUser'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'realName': realName,
        'userId': userId,
        'mobileNo': mobileNo,
        'settingsId': settingsId,
        'firebaseUser': firebaseUser,
      };
}
