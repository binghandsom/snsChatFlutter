import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:snschat_flutter/general/functions/validation_functions.dart';
import 'package:snschat_flutter/general/ui-component/list-view.dart';
import 'package:snschat_flutter/objects/chat/conversation_group.dart';
import 'package:snschat_flutter/objects/multimedia/multimedia.dart';
import 'package:snschat_flutter/objects/unreadMessage/UnreadMessage.dart';
import 'package:snschat_flutter/service/file/FileService.dart';
import 'package:snschat_flutter/service/image/ImageService.dart';
import 'package:snschat_flutter/state/bloc/WholeApp/WholeAppBloc.dart';
import 'package:snschat_flutter/state/bloc/WholeApp/WholeAppEvent.dart';
import 'package:snschat_flutter/state/bloc/WholeApp/WholeAppState.dart';
import 'package:snschat_flutter/ui/pages/chats/chat_room/chat_room_page.dart';
import 'package:time_formatter/time_formatter.dart';

class ChatGroupListPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ChatGroupListState();
  }
}

class ChatGroupListState extends State<ChatGroupListPage> {
  bool getListDone = false;

  RefreshController _refreshController;
  WholeAppBloc wholeAppBloc;

  FileService fileService = FileService();
  ImageService imageService = ImageService();

  @override
  initState() {
    super.initState();
    _refreshController = new RefreshController();
    final WholeAppBloc _wholeAppBloc = BlocProvider.of<WholeAppBloc>(context);
    wholeAppBloc = _wholeAppBloc;
    initialize();
  }

  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  initialize() async {
    wholeAppBloc.dispatch(InitializeWebSocketServiceEvent());
    wholeAppBloc.dispatch(LoadDatabaseToStateEvent(callback: (bool loadDone) {
      if (loadDone) {
        // Set list done to true to prevent waiting due to poor Internet connection
        setState(() {
          getListDone = true;
        });
        wholeAppBloc.dispatch(CheckUserLoginEvent(callback: (bool hasSignedIn) {
          if (hasSignedIn) {
            wholeAppBloc.dispatch(LoadUserPreviousDataEvent(callback: (bool done) {
              setState(() {
                print("Reload the page");
              });
            }));
          } else {
            wholeAppBloc.dispatch(UserSignOutEvent()); // Remove State data before leaving
            goToLoginPage();
          }
        }));
      } else {
        wholeAppBloc.dispatch(UserSignOutEvent()); // Remove State data before leaving
        goToLoginPage();
      }
    }));
  }

  goToLoginPage() {
    Navigator.of(context).pushNamedAndRemoveUntil("login_page", (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: wholeAppBloc,
      builder: (context, WholeAppState state) {
        if (conversationGroupsAreReady(state) && unreadMessagesAreReady(state)) {
          return SmartRefresher(
            controller: _refreshController,
            header: WaterDropHeader(),
            onRefresh: () {
              setState(() {});
              //Delay 1 second to simulate something loading
              Future.delayed(Duration(seconds: 1), () {
                _refreshController.refreshCompleted();
              });
            },
            child: ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                itemCount: state.conversationGroupList.length,
                itemBuilder: (context, index) {
                  return PageListTile(mapConversationToPageListTile(state.conversationGroupList[index]), context);
                }),
          );
        } else {
          return getListDone
              ? Center(child: Text("No conversations. Tap \"+\" to create one!"))
              : Center(child: Text("Loading messages..."));
        }
      },
    );
  }

  bool conversationGroupsAreReady(WholeAppState state) {
    return !isObjectEmpty(state.conversationGroupList) && state.conversationGroupList.length > 0;
  }

  bool unreadMessagesAreReady(WholeAppState state) {
    return !isObjectEmpty(state.unreadMessageList) && state.unreadMessageList.length > 0;
  }

  PageListItem mapConversationToPageListTile(ConversationGroup conversation) {
    Multimedia multimedia = wholeAppBloc.findMultimediaByConversationId(conversation.id);
    UnreadMessage unreadMessage = wholeAppBloc.findUnreadMessage(conversation.id);

    return PageListItem(
        title: Hero(
          tag: conversation.name,
          child: Text(conversation.name),
        ),
        subtitle: Text(isObjectEmpty(unreadMessage) ? "" : unreadMessage.lastMessage),
        leading: Hero(
          tag: conversation.id,
          child: CachedNetworkImage(
            // Note: imageBuilder is a place that tell CachedNetworkImage how the image should be displayed
            imageBuilder: (BuildContext context, ImageProvider<dynamic> imageProvider) {
              return CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: imageProvider,
              );
            },
            useOldImageOnUrlChange: true,
            imageUrl: multimedia.remoteThumbnailUrl,
            placeholder: (context, url) => new CircularProgressIndicator(),
            errorWidget: (context, url, error) => Image.asset(fileService.getDefaultImagePath(conversation.type)),
          ),
        ),
        trailing: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text(isObjectEmpty(unreadMessage) ? "" : formatTime(unreadMessage.date), style: TextStyle(fontSize: 9.0)),
            ),
            Text(isObjectEmpty(unreadMessage) ? "" : unreadMessage.count.toString() == "0" ? "" : unreadMessage.count.toString())
          ],
        ),
        onTap: (BuildContext context, object) {
          // Send argument need to use the old way
          Navigator.push(context, MaterialPageRoute(builder: ((context) => ChatRoomPage(conversation))));
        });
  }
}
