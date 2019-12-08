import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:snschat_flutter/backend/rest/index.dart';
import 'package:snschat_flutter/database/sembast/index.dart';
import 'package:snschat_flutter/general/functions/validation_functions.dart';
import 'package:snschat_flutter/objects/index.dart';
import 'package:snschat_flutter/state/bloc/user/bloc.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserAPIService userAPIService = UserAPIService();
  UserDBService userDBService = UserDBService();

  @override
  UserState get initialState => UserLoading();

  @override
  Stream<UserState> mapEventToState(UserEvent event) async* {
    if (event is InitializeUserEvent) {
      yield* _initializeUserToState(event);
    } else if (event is AddUserEvent) {
      yield* _addUser(event);
    } else if (event is EditUserEvent) {
      yield* _editUserToState(event);
    } else if (event is DeleteUserEvent) {
      yield* _deleteUserFromState(event);
    } else if (event is GetOwnUserEvent) {
      yield* _getOwnUser(event);
    } else if (event is CheckUserSignedUpEvent) {
      yield* _checkUserSignedUp(event);
    } else if (event is UserSignInEvent) {
      yield* _signIn(event);
    }
  }

  Stream<UserState> _initializeUserToState(InitializeUserEvent event) async* {
    try {
      // Bloc-to-bloc communication. https://bloclibrary.dev/#/architecture

      User userFromDB = await userDBService.getUserByGoogleAccountId(event.googleSignIn.currentUser.id);

      if (!isObjectEmpty(userFromDB)) {
        yield UserLoaded(userFromDB);
        functionCallback(event, true);
      } else {
        yield UserNotLoaded();
        functionCallback(event, false);
      }
    } catch (e) {
      yield UserNotLoaded();
      functionCallback(event, false);
    }
  }

  // Register user in API, DB, BLOC
  Stream<UserState> _addUser(AddUserEvent event) async* {
    User userFromServer;
    bool userSaved = false;

    userFromServer = await userAPIService.addUser(event.user);

    if (!isObjectEmpty(userFromServer)) {
      userSaved = await userDBService.addUser(userFromServer);

      if (userSaved) {
        functionCallback(event, userFromServer);
        yield UserLoaded(userFromServer);
      }
    }

    if (isObjectEmpty(userFromServer) || !userSaved) {
      functionCallback(event, null);
      yield UserNotLoaded();
    }
  }

  // Change User information in API, DB, and State
  Stream<UserState> _editUserToState(EditUserEvent event) async* {
    bool updatedInREST = false;
    bool userSaved = false;
    if (state is UserLoaded) {
      updatedInREST = await userAPIService.editUser(event.user);

      if (updatedInREST) {
        userSaved = await userDBService.editUser(event.user);

        if (userSaved) {
          functionCallback(event, event.user);
          yield UserLoaded(event.user);
        }
      }
    }

    if (!updatedInREST || !userSaved) {
      functionCallback(event, null);
    }
  }

  // Remove User from DB, and BLOC state
  Stream<UserState> _deleteUserFromState(DeleteUserEvent event) async* {
    bool deletedFromREST = false;
    bool deleted = false;
    if (state is UserLoaded) {
      deletedFromREST = await userAPIService.deleteUser(event.user.id);
      if (deletedFromREST) {
        deleted = await userDBService.deleteUser(event.user.id);
        if (deleted) {
          functionCallback(event, true);

          User existingUser = (state as UserLoaded).user;

          if (existingUser.id == event.user.id) {
            yield UserNotLoaded();
          }
        }
      }

      if (!deletedFromREST || !deleted) {
        functionCallback(event, false);
      }
    }
  }

  Stream<UserState> _getOwnUser(GetOwnUserEvent event) async* {
    if (state is UserLoaded) {
      User user = (state as UserLoaded).user;
      functionCallback(event, user);
    }
  }

  Stream<UserState> _checkUserSignedUp(CheckUserSignedUpEvent event) async* {

    bool isSignedUp = false;
    User existingUser;

    if (!isStringEmpty(event.mobileNo)) {
      existingUser = await userAPIService.getUserByUsingMobileNo(event.mobileNo);
    } else {
      existingUser = await userAPIService.getUserByUsingGoogleAccountId(event.googleSignIn.currentUser.id);
    }

    isSignedUp = !isObjectEmpty(existingUser);

    if (!isObjectEmpty(event)) {
      event.callback(isSignedUp);
    }
  }

  Stream<UserState> _signIn(UserSignInEvent event) async* {
    bool isSignedIn;
    User userFromServer;
    if (!isObjectEmpty(event.googleSignIn)) {
      isSignedIn = await event.googleSignIn.isSignedIn();
      if (isSignedIn) {
        userFromServer = await userAPIService.getUserByUsingGoogleAccountId(event.googleSignIn.currentUser.id);

        if (!isObjectEmpty(userFromServer)) {
          yield UserLoaded(userFromServer);
          functionCallback(event, userFromServer);
        }
      }
    }

    if (!isSignedIn || !isObjectEmpty(userFromServer)) {
      yield UserNotLoaded();
      functionCallback(event, null);
    }
  }

  // To send response to those dispatched Actions
  void functionCallback(event, value) {
    if (!isObjectEmpty(event)) {
      event.callback(value);
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
