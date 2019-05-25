import 'package:snschat_flutter/general/functions/repeating_functions.dart';
import 'package:snschat_flutter/objects/multimedia/multimedia.dart';

// system message or normal message, sticker, gifs, emojis, video, recording, photos,
class Message {
  String id;
  String conversationId;

//  String recipientId; // Recipient
  // Sender
  String senderId;
  String senderName;
  String senderMobileNo;

  // Receiver
  String receiverId;
  String receiverName;
  String receiverMobileNo;

  String type;
  String status; // Sent, received, unread, read
  String message;
  String multimediaId; // Multimedia

  Message(
      {this.id,
      this.conversationId,
      this.senderId,
      this.senderName,
      this.senderMobileNo,
      this.receiverId,
      this.receiverName,
      this.receiverMobileNo,
      this.type,
      this.status,
      this.message,
      this.multimediaId});

  Message.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        conversationId = json['conversationId'],
        senderId = json['senderId'],
        senderName = json['senderName'],
        senderMobileNo = json['senderMobileNo'],
        receiverId = json['receiverId'],
        receiverName = json['receiverName'],
        receiverMobileNo = json['receiverMobileNo'],
        type = json['type'],
        status = json['status'],
        message = json['message'],
        multimediaId = json['multimediaId'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'senderName': senderName,
    'senderMobileNo': senderMobileNo,
    'receiverId': receiverId,
    'receiverName': receiverName,
    'receiverMobileNo': receiverMobileNo,
    'type': type,
    'status': status,
    'message': message,
    'multimediaId': multimediaId,
  };
}

//class Recipient {
//  Sender sender;
//  Receiver receiver;
//
//  Recipient({this.sender, this.receiver});
//}
//
//class Sender {
//  String id;
//  String mobileNo;
//  String name;
//  int time; // send time
//  Sender({this.id, this.mobileNo, this.name, this.time});
//}
//
//class Receiver {
//  String id;
//  String mobileNo;
//  String name;
//  int time; // receive time
//  Receiver({this.id, this.mobileNo, this.name, this.time});
//}
