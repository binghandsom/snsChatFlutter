import 'dart:io';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:snschat_flutter/backend/rest/index.dart';
import 'package:snschat_flutter/general/functions/validation_functions.dart';
import 'package:snschat_flutter/general/ui-component/loading.dart';
import 'package:snschat_flutter/objects/conversationGroup/conversation_group.dart';
import 'package:snschat_flutter/objects/index.dart';
import 'package:snschat_flutter/objects/multimedia/multimedia.dart';
import 'package:snschat_flutter/service/file/FileService.dart';
import 'package:snschat_flutter/service/image/ImageService.dart';
import 'package:snschat_flutter/state/bloc/bloc.dart';
import 'package:snschat_flutter/ui/pages/chats/chat_room/chat_room_page.dart';
import 'package:snschat_flutter/ui/pages/group_name/group_name_page.dart';

import 'CustomSearchDelegate.dart';

class SelectContactsPage extends StatefulWidget {
  final String chatGroupType;

  SelectContactsPage({this.chatGroupType});

  @override
  State<StatefulWidget> createState() {
    return new SelectContactsPageState();
  }
}

// TODO: Make Alphabet scroll
// Whatsapp closes the search function when multi select
class SelectContactsPageState extends State<SelectContactsPage> {
  bool isLoading = true;
  bool contactLoaded = false;

  String title = "";
  String subtitle = "";

  List<Contact> selectedContacts = [];
  Map<String, bool> contactCheckBoxes = {};

  Color themePrimaryColor;
  Color appBarThemeTextColor;
  TextStyle circleAvatarTextStyle;

  RefreshController _refreshController;
  ScrollController scrollController;

  FileService fileService = FileService();
  ImageService imageService = ImageService();
  UserContactAPIService userContactAPIService = UserContactAPIService();

  @override
  initState() {
    super.initState();
    _refreshController = new RefreshController();
    scrollController = new ScrollController();
    getContacts(context);
    setConversationType(widget.chatGroupType);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _refreshController.dispose();
    scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    themePrimaryColor = Theme.of(context).textTheme.title.color;
    appBarThemeTextColor = Theme.of(context).appBarTheme.textTheme.title.color;
    circleAvatarTextStyle = TextStyle(color: appBarThemeTextColor);

    return Scaffold(
      appBar: appBar(context),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PhoneStorageContactBloc, PhoneStorageContactState>(
            listener: (context, phoneStorageContactState) {
              if (phoneStorageContactState is PhoneStorageContactsLoaded) {
                setupCheckBoxes(phoneStorageContactState.phoneStorageContactList);
              }
            },
          ),
          BlocListener<UserBloc, UserState>(
            listener: (context, userState) {
              print('select_contacts_page.dart UserBloc listener worklng.');
              if (userState is UserLoaded) {
                print('select_contacts_page.dart User state is loaded detected.');
              }
            },
          ),
        ],
        child: BlocBuilder<PhoneStorageContactBloc, PhoneStorageContactState>(
          builder: (context, phoneStorageContactState) {
            if (phoneStorageContactState is PhoneStorageContactLoading) {
              print('select-contect-page.dart if (phoneStorageContactState is PhoneStorageContactLoading)');
              return showLoadingContactsPage(context);
            }

            if (phoneStorageContactState is PhoneStorageContactsLoaded) {
              print('select-contect-page.dart if (phoneStorageContactState is PhoneStorageContactsLoaded)');
              if (phoneStorageContactState.phoneStorageContactList.length == 0) {
                print('select-contect-page.dart showNoContactPage');
                return showNoContactPage(context);
              } else {
                print('select-contect-page.dart show contacts');
                return SmartRefresher(
                  controller: _refreshController,
                  enablePullDown: true,
                  physics: BouncingScrollPhysics(),
                  onRefresh: () => onRefresh(context),
                  child: ListView(
                    controller: scrollController,
                    children: phoneStorageContactState.phoneStorageContactList.map((Contact contact) {
                      return Container(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            needSelectMultipleContacts()
                                ? showContactWithCheckBox(context, contact)
                                : showContactWithoutCheckbox(context, contact)
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }
            }

            if (phoneStorageContactState is PhoneStorageContactsNotLoaded) {
              print('select-contect-page.dart if (phoneStorageContactState is PhoneStorageContactsNotLoaded)');
              return showNoContactPermissionPage(context);
            }

            print('select-contect-page.dart showErrorPage()');
            return showErrorPage(context);
          },
        ),
      ),
      bottomNavigationBar: _bottomAppBar(context),
      floatingActionButton: _floatingActionButton(context),
    );
  }

  Widget appBar(BuildContext context) {
    return AppBar(
        title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 18.0),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w300),
              )
            ],
          ),
        ),
        Tooltip(
          message: "Next",
          child: InkWell(
            borderRadius: BorderRadius.circular(30.0),
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Icon(Icons.check),
            ),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: ((context) => GroupNamePage(selectedContacts: selectedContacts))));
            },
          ),
        ),
      ],
    ));
  }

  Widget showLoadingContactsPage(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text('Reading contacts from storage....'),
        SizedBox(
          height: 10.0,
        ),
        CircularProgressIndicator(),
      ],
    ));
  }

  Widget showContactWithCheckBox(BuildContext context, Contact contact) {
    return CheckboxListTile(
      title: Text(
        contact.displayName,
        softWrap: true,
      ),
      subtitle: Text(
        'Hey There! I am using PocketChat.',
        softWrap: true,
      ),
      value: contactCheckBoxes[contact.displayName],
      onChanged: (bool value) {
        if (contactIsSelected(contact)) {
          selectedContacts.remove(contact);
        } else {
          selectedContacts.add(contact);
        }
        setState(() {
          contactCheckBoxes[contact.displayName] = value;
        });
      },
      secondary: CircleAvatar(
        backgroundColor: themePrimaryColor,
        backgroundImage: contact.avatar.isNotEmpty ? MemoryImage(contact.avatar) : NetworkImage(''),
        child: contact.avatar.isEmpty
            ? Text(
                contact.displayName[0],
                style: circleAvatarTextStyle,
              )
            : Text(
                '',
                style: circleAvatarTextStyle,
              ),
        radius: 20.0,
      ),
    );
  }

  Widget showContactWithoutCheckbox(BuildContext context, Contact contact) {
    return ListTile(
      title: Text(
        contact.displayName,
        softWrap: true,
      ),
      subtitle: Text(
        'Hey There! I am using PocketChat.',
        softWrap: true,
      ),
      onTap: () {
        if (widget.chatGroupType == "Personal") {
          createPersonalConversation(contact, context);
        }
      },
      leading: CircleAvatar(
        backgroundColor: themePrimaryColor,
        backgroundImage: contact.avatar.isNotEmpty ? MemoryImage(contact.avatar) : NetworkImage(''),
        child: contact.avatar.isEmpty
            ? Text(
                contact.displayName[0],
                style: circleAvatarTextStyle,
              )
            : Text(
                '',
                style: circleAvatarTextStyle,
              ),
        radius: 20.0,
      ),
    );
  }

  Widget showErrorPage(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'Error in getting phone storage contacts. Please try again.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget showNoContactPage(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'No contact in your phone storage. Create a few to start a conversation!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget showNoContactPermissionPage(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          'Unable to read contacts from storage. Please grant contact permission first.',
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: 10.0,
        ),
        RaisedButton(
          onPressed: () => getContacts(context),
          child: Text("Grant Contact Permission"),
        )
      ],
    ));
  }

  BottomAppBar _bottomAppBar(BuildContext context) {
    return BottomAppBar(
      shape: CircularNotchedRectangle(),
      color: Theme.of(context).primaryColor,
    );
  }

  FloatingActionButton _floatingActionButton(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.search),
      onPressed: () => showSearch(context: context, delegate: CustomSearchDelegate()),
    );
  }

  bool contactIsSelected(Contact contact) {
    return selectedContacts.any((Contact selectedContact) => selectedContact.displayName == contact.displayName);
  }

  bool needSelectMultipleContacts() {
    // return widget.chatGroupType == ChatGroupType.Group || widget.chatGroupType == ChatGroupType.Broadcast;
    // return widget.chatGroupType == "Group" || widget.chatGroupType == "Broadcast";
    return widget.chatGroupType != "Personal";
  }

  setupCheckBoxes(List<Contact> phoneStorageContactList) {
    phoneStorageContactList.forEach((contact) {
      contactCheckBoxes[contact.displayName] = false;
    });

    contactLoaded = true;
  }

  getContacts(BuildContext context) async {
    BlocProvider.of<PhoneStorageContactBloc>(context).add(GetPhoneStorageContactsEvent(callback: (bool success) {
      success ? _refreshController.refreshCompleted() : _refreshController.refreshFailed();
    }));
  }

  setConversationType(String chatGroupType) async {
    print("widget.chatGroupType: " + widget.chatGroupType);
    switch (chatGroupType) {
      case "Personal":
        title = "Create Personal Chat";
        subtitle = "Select a contact below.";
        break;
      case "Group":
        title = "Create Group Chat";
        subtitle = "Select a few contacts below.";
        break;
      case "Broadcast":
        title = "Broadcast";
        subtitle = "Select a few contacts below.";
        break;
      default:
        title = "Unknown Chat";
        subtitle = "Error. Please go back and select again.";
        break;
    }
  }

  onRefresh(BuildContext context) async {
    getContacts(context);
  }

  // TODO: Conversation Group Creation into BLOC, can be merged with Group & Broadcast
  createPersonalConversation(Contact contact, BuildContext context) async {
    // TODO: create loading that cannot be dismissed to prevent exit, and make it faster
    showLoading(context, "Loading conversation...");
    UserState userState = BlocProvider.of<UserBloc>(context).state;
    if (userState is UserLoaded) {
      User currentUser = userState.user;
      List<Contact> contactList = [];
      contactList.add(contact);

      ConversationGroup conversationGroup = new ConversationGroup(
        id: null,
        creatorUserId: currentUser.id,
        createdDate: new DateTime.now().millisecondsSinceEpoch,
        name: contact.displayName,
        type: "Personal",
        block: false,
        description: '',
        adminMemberIds: [],
        // Add later
        memberIds: [],
        // Add later
        // memberIds put UserContact.id. NOT User.id
        notificationExpireDate: 0,
      );

      UnreadMessage unreadMessage = UnreadMessage(
        id: null,
        conversationId: null,
        count: 0,
        date: DateTime.now().millisecondsSinceEpoch,
        lastMessage: "",
        userId: null,
      );

      Multimedia groupMultimedia = Multimedia(
          id: null,
          localFullFileUrl: null,
          localThumbnailUrl: null,
          remoteThumbnailUrl: null,
          remoteFullFileUrl: null,
          userContactId: null,
          conversationId: null,
          // Add later
          messageId: null,
          userId: null);

      File userContactImage;
      // TODO: Temporary close it because not yet able to convert Uint8List to File
      //    if (!isObjectEmpty(contact.avatar) && contact.avatar.length > 0) {
      //      print("if (!isObjectEmpty(contact.avatar))");
      //      print("contact.avatar.length.toString(): " + contact.avatar.length.toString());
      //      userContactImage = await getUserContactPhoto(contact);
      //    }

      if (!isObjectEmpty(userContactImage)) {
        groupMultimedia.localFullFileUrl = userContactImage.path;
        // TODO: What if this userContact is known user in REST?
        groupMultimedia.localThumbnailUrl = userContactImage.path;
      }

      // 2. Upload UserContactList
      // Note: Backend already helped you to check any duplicates of the same UserContact
      List<UserContact> userContactList = [];

      UserContact yourOwnUserContact = UserContact(
        id: null,
        userIds: [currentUser.id],
        userId: currentUser.id,
        displayName: currentUser.displayName,
        realName: currentUser.realName,
        block: false,
        lastSeenDate: new DateTime.now().millisecondsSinceEpoch,
        // make unknown time, let server decide
        mobileNo: currentUser.mobileNo,
      );

      userContactList.add(yourOwnUserContact);

      contactList.forEach((contact) {
        List<String> primaryNo = [];
        if (contact.phones.length > 0) {
          contact.phones.forEach((phoneNo) {
            primaryNo.add(phoneNo.value);
          });
        } else {
          // No phone number and the display name is the phone number itself
          // Reason: No contact.phones when the mobile number doesn't have a name on it
          String mobileNo = contact.displayName.replaceAll(new RegExp(r"\s+\b|\b\s|\s|\b"), "");
          print("mobileNo with whitespaces removed: " + mobileNo);
          primaryNo.add(mobileNo);
        }

        UserContact userContact = UserContact(
          id: null,
          // So this contact number is mine. Later send it to backend and merge with other UserContact who got the same number
          userIds: [currentUser.id],
          displayName: contact.displayName,
          realName: contact.displayName,
          block: false,
          lastSeenDate: new DateTime.now().millisecondsSinceEpoch,
        );

        userContact.mobileNo = primaryNo.length == 0 ? "" : primaryNo[0];

        // If got Malaysia number
        if (primaryNo[0].contains("+60")) {
          print("If Malaysian Number: ");
          String trimmedString = primaryNo[0].substring(3);
          print("trimmedString: " + trimmedString);
        }

        userContactList.add(userContact);
      });

      UserContact targetUserContact = userContactList[1];

      // Logic to detect to find same personal conversation group in local state/DB
      UserContact userContactFromServer = await userContactAPIService.getUserContactByMobileNo(targetUserContact.mobileNo);
      if (!isObjectEmpty(userContactFromServer)) {
        UserContactState userContactState = BlocProvider.of<UserContactBloc>(context).state;
        ConversationGroupState conversationGroupState = BlocProvider.of<ConversationGroupBloc>(context).state;

        if (userContactState is UserContactsLoaded && conversationGroupState is ConversationGroupsLoaded) {
          List<UserContact> userContactList = userContactState.userContactList;
          List<ConversationGroup> conversationGroupList = conversationGroupState.conversationGroupList;

          bool personalConversationGroupExist = conversationGroupList.contains((ConversationGroup existingConversationGroup) =>
              existingConversationGroup.type == 'Personal' &&
              existingConversationGroup.memberIds.contains((String memberId) => memberId == userContactFromServer.id));

          if (personalConversationGroupExist) {
            goToChatRoomPage(context, conversationGroup);
            return;
          }
        }
      }

      BlocProvider.of<UserContactBloc>(context).add(AddMultipleUserContactEvent(
          userContactList: userContactList,
          callback: (List<UserContact> newUserContactList) {
            if ((contactList.length != newUserContactList.length - 1) || newUserContactList.length == 0) {
              // event.contactList doesn't include yourself, so newUserContactList.length - 1 OR Any UserContact is not added into the list (means not uploaded successfully)
              // That means some UseContact are not uploaded into the REST
              Navigator.pop(context);
              Fluttertoast.showToast(msg: 'Unable to upload your member list. Please try again.', toastLength: Toast.LENGTH_SHORT);
            } else {
              print("Uploaded and saved uploadUserContactList to REST, DB and State.");

              // Give the list of UserContactIds to memberIds of ConversationGroup
              conversationGroup.memberIds = newUserContactList.map((newUserContact) => newUserContact.id).toList();

              // Add your own userContact's ID as admin by find the one that has the same mobile number in the userContactList
              conversationGroup.adminMemberIds.add(newUserContactList
                  .firstWhere((UserContact newUserContact) => newUserContact.mobileNo == currentUser.mobileNo, orElse: () => null)
                  .id);

              print('select_contacts.page.dart conversationGroup.memberIds: ' + conversationGroup.memberIds.toString());
              print('select_contacts.page.dart conversationGroup.adminMemberIds: ' + conversationGroup.adminMemberIds.toString());

              BlocProvider.of<ConversationGroupBloc>(context).add(AddConversationGroupEvent(
                  conversationGroup: conversationGroup,
                  callback: (ConversationGroup conversationGroup2) async {
                    if (!isObjectEmpty(conversationGroup2)) {
                      groupMultimedia.conversationId = unreadMessage.conversationId = conversationGroup2.id;
                      unreadMessage.userId = conversationGroup2.creatorUserId;
                      BlocProvider.of<UnreadMessageBloc>(context).add(AddUnreadMessageEvent(
                          unreadMessage: unreadMessage,
                          callback: (UnreadMessage unreadMessage2) {
                            if (!isObjectEmpty(unreadMessage2)) {
                              addMultimedia(groupMultimedia, null, conversationGroup2, context);
                            }
                          }));
                    } else {
                      Navigator.pop(context);
                      Fluttertoast.showToast(
                          msg: 'Unable to create conversation group. Please try again.', toastLength: Toast.LENGTH_SHORT);
                    }
                  }));
            }
          }));
    }
  }

  addMultimedia(Multimedia groupMultimedia, File imageFile, ConversationGroup conversationGroup, BuildContext context) async {
    // 4. Upload Group Multimedia
    // Create thumbnail before upload
    File thumbnailImageFile;
    if (!isStringEmpty(groupMultimedia.localFullFileUrl) && !isObjectEmpty(imageFile)) {
      thumbnailImageFile = await imageService.getImageThumbnail(imageFile);
    }

    if (!isObjectEmpty(thumbnailImageFile)) {
      groupMultimedia.localThumbnailUrl = thumbnailImageFile.path;
    }

    BlocProvider.of<MultimediaBloc>(context).add(AddMultimediaEvent(
        multimedia: groupMultimedia,
        callback: (Multimedia multimedia2) {
          goToChatRoomPage(context, conversationGroup);
        }));
  }

  goToChatRoomPage(BuildContext context, ConversationGroup conversationGroup) {
    // Go to chat room page
    Navigator.pop(context); //pop loading dialog
    Navigator.of(context).pushNamedAndRemoveUntil('tabs_page', (Route<dynamic> route) => false);
    Navigator.push(context, MaterialPageRoute(builder: ((context) => ChatRoomPage(conversationGroup))));
  }
}
