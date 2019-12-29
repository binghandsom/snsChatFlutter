import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:snschat_flutter/general/functions/validation_functions.dart';
import 'package:snschat_flutter/objects/conversationGroup/conversation_group.dart';
import 'package:snschat_flutter/objects/index.dart';
import 'package:snschat_flutter/objects/message/message.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snschat_flutter/objects/multimedia/multimedia.dart';
import 'package:snschat_flutter/service/file/FileService.dart';
import 'package:snschat_flutter/service/image/ImageService.dart';
import 'package:snschat_flutter/state/bloc/bloc.dart';
import 'package:snschat_flutter/ui/pages/chats/chat_info/chat_info_page.dart';

import 'package:snschat_flutter/environments/development/variables.dart' as globals;

class ChatRoomPage extends StatefulWidget {
  final ConversationGroup _conversationGroup;

  ChatRoomPage([this._conversationGroup]);

  @override
  State<StatefulWidget> createState() {
    return new ChatRoomPageState();
  }
}

class ChatRoomPageState extends State<ChatRoomPage> {
  bool isShowSticker = false;
  bool isLoading;
  bool imageFound = false;
  double deviceWidth;
  double deviceHeight;

  Color appBarTextTitleColor;
  Color appBarThemeColor;

  // This is used to get batch send multiple multimedia in one go, like multiple image and video
  List<File> fileList = [];

  String WEBSOCKET_URL = globals.WEBSOCKET_URL;

  File imageFile;

  TextEditingController textEditingController = new TextEditingController();
  ScrollController listScrollController = new ScrollController();
  FocusNode focusNode = new FocusNode();

  FileService fileService = FileService();
  ImageService imageService = ImageService();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    isLoading = false;
    isShowSticker = false;
  }

  @override
  void dispose() {
    listScrollController.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("widget._conversation.id: " + widget._conversationGroup.id);

    appBarTextTitleColor = Theme.of(context).appBarTheme.textTheme.title.color;
    appBarThemeColor = Theme.of(context).appBarTheme.color;

    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;

    // TODO: Send message using WebSocket
    // Do in this order (To allow resend message if anything goes wrong [Send timeout, websocket down, Internet down situations])
    // 1. Send to DB
    // 2. Send to State
    // 3. Send to API
    // 4. Retrieve through WebSocket

    return MultiBlocListener(
      listeners: [],
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, userState) {
          if (userState is UserLoading) {
            return Center(
              child: Text('Loading...'),
            );
          }

          if (userState is UserNotLoaded) {
            goToLoginPage();
            return Center(
              child: Text('Unable to load user.'),
            );
          }

          if (userState is UserLoaded) {
            return BlocBuilder<ConversationGroupBloc, ConversationGroupState>(
              builder: (context, conversationGroupState) {
                if (conversationGroupState is ConversationGroupsLoaded) {
                  ConversationGroup conversationGroup = conversationGroupState.conversationGroupList.firstWhere(
                      (ConversationGroup conversationGroup) => conversationGroup.id == widget._conversationGroup.id,
                      orElse: () => null);
                  if (!isObjectEmpty(conversationGroup)) {
                    return chatRoomMainBody(context, conversationGroup, userState.user);
                  } else {
                    Fluttertoast.showToast(msg: 'Error. Conversation Group not found.', toastLength: Toast.LENGTH_LONG);
                    Navigator.pop(context);
                  }
                }

                return chatRoomMainBody(context, null, userState.user);
              },
            );
          }

          return Center(
            child: Text('Error. Unable to load user'),
          );
        },
      ),
    );
  }

  Widget chatRoomMainBody(BuildContext context, ConversationGroup selectedConversationGroup, User user) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0.0,
          title: BlocBuilder<MultimediaBloc, MultimediaState>(
            builder: (context, multimediaState) {
              if (multimediaState is MultimediaLoaded) {
                Multimedia multimedia = multimediaState.multimediaList.firstWhere(
                    (Multimedia existingMultimedia) => existingMultimedia.conversationId == selectedConversationGroup.id,
                    orElse: () => null);

                return chatRoomPageTopBar(context, selectedConversationGroup, multimedia);
              }

              return chatRoomPageTopBar(context, selectedConversationGroup, null);
            },
          ),
        ),
        body: WillPopScope(
          // To handle event when user press back button when sticker screen is on, dismiss sticker if keyboard is shown
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  //UI for message list
                  buildListMessage(context, user),
                  // UI for stickers, gifs
                  (isShowSticker ? buildSticker(context, user) : Container()),
                  // UI for text field
                  buildInput(context, user),
                ],
              ),
              buildLoading(),
            ],
          ),
          onWillPop: onBackPress,
        ),
      ),
    );
  }

  Widget chatRoomPageTopBar(BuildContext context, ConversationGroup conversationGroup, Multimedia multimedia) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Tooltip(
          message: "Back",
          child: Material(
            color: appBarThemeColor,
            child: InkWell(
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Row(
                children: <Widget>[
                  Icon(Icons.arrow_back),
                  Hero(
                    tag: conversationGroup.id + "1",
                    child: imageService.loadImageThumbnailCircleAvatar(multimedia, conversationGroup.type, context),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 30.0),
                  ),
                ],
              ),
            ),
          ),
        ),
        Material(
          color: appBarThemeColor,
          child: InkWell(
              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => ChatInfoPage(conversationGroup)));
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(top: 10.0, right: 250.0),
                  ),
                  Hero(
                    tag: conversationGroup.id,
                    child: Text(
                      conversationGroup.name,
                      style: TextStyle(color: appBarTextTitleColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    "Tap here for more details",
                    style: TextStyle(color: appBarTextTitleColor, fontSize: 13.0),
                  )
                ],
              )),
        ),
      ],
    );
  }

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  Widget buildInput(BuildContext context, User user) {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.image),
                onPressed: () => getImage(),
              ),
            ),
            color: Colors.white,
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.face),
                onPressed: () => getSticker(),
              ),
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(fontSize: 17.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => sendChatMessage(context, textEditingController.text, 0, user),
              ),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey, width: 0.5)), color: Colors.white),
    );
  }

  Widget buildListMessage(BuildContext context, User user) {
    return BlocBuilder<WebSocketBloc, WebSocketState>(
      builder: (context, webSocketState) {
        print('chat_room_page.dart BlocBuilder<WebSocketBloc, WebSocketState>');
        if (webSocketState is WebSocketNotLoaded) {
          BlocProvider.of<WebSocketBloc>(context).add(ReconnectWebSocketEvent(callback: (bool done) {}));
        }

        if (webSocketState is WebSocketLoaded) {
          print('chat_room_page.dart if (webSocketState is WebSocketLoaded)');
          processWebSocketMessage(context, webSocketState.webSocketStream, user);
          return loadMessageList(context, user);
        }
        return loadMessageList(context, user);
      },
    );
  }

  processWebSocketMessage(BuildContext context, Stream<dynamic> webSocketStream, User user) {
    webSocketStream.listen((data) {
      print("chat_room_page.dart webSocketStream listener is working.");
      print("chat_room_page.dart data: " + data.toString());
      Fluttertoast.showToast(msg: "Message confirmed received!", toastLength: Toast.LENGTH_LONG);
      WebSocketMessage receivedWebSocketMessage = WebSocketMessage.fromJson(json.decode(data));
      BlocProvider.of<WebSocketBloc>(context)
          .add(ProcessWebSocketMessageEvent(webSocketMessage: receivedWebSocketMessage, context: context, callback: (bool done) {}));
    }, onError: (onError) {
      print("chat_room_page.dart onError listener is working.");
      print("chat_room_page.dart onError: " + onError.toString());
      BlocProvider.of<WebSocketBloc>(context).add(ReconnectWebSocketEvent(user: user, callback: (bool done) {}));
    }, onDone: () {
      print("chat_room_page.dart onDone listener is working.");
      // TODO: Show reconnect message
      BlocProvider.of<WebSocketBloc>(context).add(ReconnectWebSocketEvent(user: user, callback: (bool done) {}));
    }, cancelOnError: false);
  }

  Widget loadMessageList(BuildContext context, User user) {
    return BlocBuilder<MessageBloc, MessageState>(
      builder: (context, messageState) {
        print('chat_room_page.dart BlocBuilder<MessageBloc, MessageState>');
        if (messageState is MessageLoading) {
          return showSingleMessagePage('Loading...');
        }

        if (messageState is MessagesLoaded) {
          print('if (messageState is MessagesLoaded) RUN HERE?');
          // Get current conversation messages and sort them.
          List<Message> conversationGroupMessageList =
              messageState.messageList.where((Message message) => message.conversationId == widget._conversationGroup.id).toList();
          conversationGroupMessageList.sort((message1, message2) => message2.timestamp.compareTo(message1.timestamp));
          print("conversationGroupMessageList.length: " + conversationGroupMessageList.length.toString());

          return Flexible(
            child: ListView.builder(
              controller: listScrollController,
              itemCount: conversationGroupMessageList.length,
              reverse: true,
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) => displayChatMessage(index, conversationGroupMessageList[index], user),
            ),
          );
        }

        return showSingleMessagePage('No messages.');
      },
    );
  }

  Widget showSingleMessagePage(String message) {
    return Material(
      color: Colors.white,
      child: Flexible(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                message,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget displayChatMessage(int index, Message message, User user) {
//    print("displayChatMessage()");
//    print("message.senderId: " + message.senderId);
//    print("user.id: " + user.id);
    return Column(
      children: <Widget>[
        Text(
          message.senderName + ", " + messageTimeDisplay(message.timestamp),
          style: TextStyle(fontSize: 10.0, color: Colors.black38),
        ),
        Row(
          crossAxisAlignment: message.senderId == user.id ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          mainAxisAlignment: isSenderMessage(message, user) ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
              decoration: BoxDecoration(color: appBarThemeColor, borderRadius: BorderRadius.circular(8.0)),
              margin: EdgeInsets.only(
                  bottom: 20.0,
                  right: isSenderMessage(message, user) ? deviceWidth * 0.01 : 0.0,
                  left: isSenderMessage(message, user) ? deviceWidth * 0.01 : 0.0),
              child: Row(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text(
                        // message.senderName + message.messageContent + messageTimeDisplay(message.timestamp),
                        message.messageContent,
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  bool isSenderMessage(Message message, User user) {
    return message.senderId == user.id;
  }

  String messageTimeDisplay(int timestamp) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat("dd-MM-yyyy").format(now);
//    print("now: " + formattedDate);
    DateFormat dateFormat = DateFormat("dd-MM-yyyy");
    DateTime today = dateFormat.parse(formattedDate);
    String formattedDate2 = DateFormat("dd-MM-yyyy hh:mm:ss").format(today);
//    print("today: " + formattedDate2);
    DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    String formattedDate3 = DateFormat("hh:mm").format(messageTime);
    return formattedDate3;
  }

  Widget buildSticker(BuildContext context, User user) {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi1', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi1.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )),
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi2', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi2.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )),
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi3', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi3.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ))
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi4', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi4.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )),
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi5', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi5.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )),
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi6', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi6.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ))
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi7', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi7.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )),
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi8', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi8.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  )),
              FlatButton(
                  onPressed: () => sendChatMessage(context, 'mimi9', 2, user),
                  child: Image(
                    image: AssetImage("lib/ui/images/mimi9.gif"),
                    width: 50.0,
                    height: 50.0,
                    fit: BoxFit.cover,
                  ))
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey, width: 0.5)), color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 180.0,
    );
  }

  sendChatMessage(BuildContext context, String content, int type, User user) {
    print("sendChatMessage()");
    // type: 0 = text,
    // 1 = image,
    // 2 = sticker
    if (content.trim() != '') {
      print("if (content.trim() != '')");
      textEditingController.clear();

      Message newMessage;
      Multimedia newMultimedia;

      switch (type) {
        case 0:
          print("if (type == 0)");
          // Text
          print("Checkpoint 2");
          newMessage = Message(
            id: null,
            conversationId: widget._conversationGroup.id,
            messageContent: content,
            multimediaId: "",
            // Send to group will not need receiver
            receiverId: "",
            receiverMobileNo: "",
            receiverName: "",
            senderId: user.id,
            senderMobileNo: user.mobileNo,
            senderName: user.displayName,
            status: "Sent",
            type: "Text",
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          print("Checkpoint 3");
          break;
        case 1:
          // Image
          break;
        case 2:
          break;
        default:
          Fluttertoast.showToast(msg: 'Error. Unable to determine message type.', toastLength: Toast.LENGTH_SHORT);
          break;
      }
      // Text doesn't need multimedia, so others other than Text needs multimedia
      if (type != 0) {
        newMultimedia = Multimedia(
            id: null,
            conversationId: widget._conversationGroup.id,
            messageId: "",
            // Add after message created
            userContactId: "",
            localFullFileUrl: "",
            localThumbnailUrl: "",
            remoteFullFileUrl: "",
            remoteThumbnailUrl: "");
      }
      print("Checkpoint 1");
      if (!isObjectEmpty(newMessage)) {
        print('if(!isObjectEmpty(newMessage)');

        BlocProvider.of<MessageBloc>(context).add(AddMessageEvent(
            message: newMessage,
            callback: (Message message) {
              if (isObjectEmpty(message)) {
                Fluttertoast.showToast(msg: 'Message not sent. Please try again.', toastLength: Toast.LENGTH_SHORT);
              } else {
                print('if(!isObjectEmpty(message)');
                WebSocketMessage webSocketMessage = WebSocketMessage(message: message);
                BlocProvider.of<WebSocketBloc>(context)
                    .add(SendWebSocketMessageEvent(webSocketMessage: webSocketMessage, callback: (bool done) {}));
              }
            }));

//        wholeAppBloc.dispatch(SendMessageEvent(
//            message: newMessage,
//            multimedia: newMultimedia,
//            callback: (Message message) {
//              if (isObjectEmpty(message)) {
//                Fluttertoast.showToast(msg: 'Message not sent. Please try again.', toastLength: Toast.LENGTH_SHORT);
//              } else {
//                WebSocketMessage webSocketMessage = WebSocketMessage(message: message);
//                wholeAppBloc.dispatch(
//                    SendWebSocketMessageEvent(webSocketMessage: webSocketMessage, callback: (WebSocketMessage websocketMessage) {}));
//                Fluttertoast.showToast(msg: 'Message sent!', toastLength: Toast.LENGTH_SHORT);
//                // Need to do this,or else the message list won't refresh
//                setState(() {
//                  // Do nothing
//                });
//              }
//            }));
      } else {
        print('if(isObjectEmpty(newMessage)');
      }
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });

      // TODO: Will handle image file upload
      //uploadFile();
    }
  }

  // TODO: Will think about last message is left or right to determine bottom margin between last message and textfield
//  isLastMessage(int index) {
//    if ((index > 0 && messageList != null &&
//        messageList[index - 1]['idFrom'] != id) || index == 0) {
//      return true;
//    } else {
//      return false;
//    }
//  }

  // Hide sticker or back
  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      Navigator.pop(context);
    }
    return Future.value(false);
  }

  void getSticker() {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  goToLoginPage() {
    BlocProvider.of<GoogleInfoBloc>(context).add(RemoveGoogleInfoEvent());
    Navigator.of(context).pushNamedAndRemoveUntil("login_page", (Route<dynamic> route) => false);
  }
}
