import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:snschat_flutter/environments/development/variables.dart' as globals;
import 'package:snschat_flutter/objects/unreadMessage/unread_message.dart';

import '../RestRequestUtils.dart';
import '../RestResponseUtils.dart';

class UnreadMessageAPIService {
  String REST_URL = globals.REST_URL;

  Future<UnreadMessage> addUnreadMessage(UnreadMessage unreadMessage) async {
    String wholeURL = REST_URL + "/unreadMessage";
    String unreadMessageJsonString = json.encode(unreadMessage.toJson());
    var httpResponse = await http.post(REST_URL + "/unreadMessage", body: unreadMessageJsonString, headers: createAcceptJSONHeader());
    if (httpResponseIsCreated(httpResponse)) {
      String locationString = httpResponse.headers['location'];
      String unreadMessageId = locationString.replaceAll(wholeURL + "/", "");
      unreadMessage.id = unreadMessageId;
      return unreadMessage;
    }
    return null;
  }

  Future<bool> editUnreadMessage(UnreadMessage unreadMessage) async {
    String unreadMessageJsonString = json.encode(unreadMessage.toJson());
    var httpResponse = await http.put(REST_URL + "/unreadMessage", body: unreadMessageJsonString, headers: createAcceptJSONHeader());
    return httpResponseIsOK(httpResponse);
  }

  Future<bool> deleteUnreadMessage(String unreadMessageId) async {
    var httpResponse = await http.delete(REST_URL + "/unreadMessage/" + unreadMessageId);
    return httpResponseIsOK(httpResponse);
  }

  Future<UnreadMessage> getSingleUnreadMessage(String messageId) async {
    var httpResponse = await http.get(REST_URL + "/unreadMessage/" + messageId);
    if (httpResponseIsOK(httpResponse)) {
      UnreadMessage message = new UnreadMessage.fromJson(json.decode(httpResponse.body));
      return message;
    }
    return null;
  }

  Future<List<UnreadMessage>> getUnreadMessagesOfAUser(String userId) async {
    var httpResponse = await http.get(REST_URL + "/unreadMessage/user/" + userId);

    if (httpResponseIsOK(httpResponse)) {
      Iterable list = json.decode(httpResponse.body);
      List<UnreadMessage> unreadMessageList = list.map((model) => UnreadMessage.fromJson(model)).toList();
      return unreadMessageList;
    }
    return null;
  }
}
