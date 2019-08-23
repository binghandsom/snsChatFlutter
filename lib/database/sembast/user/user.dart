import 'package:sembast/sembast.dart';
import 'package:snschat_flutter/objects/user/user.dart';

import '../SembastDB.dart';

class UserDBService {
  static const String USER_STORE_NAME = "user";

  final _userStore = intMapStoreFactory.store(USER_STORE_NAME);

  Future<Database> get _db async => await SembastDB.instance.database;

  //CRUD
  Future addUser(User user) async {
    await _userStore.add(await _db, user.toJson());
  }

  Future editUser(User user) async {
    final finder = Finder(filter: Filter.equals("id", user.id));

    await _userStore.update(await _db, user.toJson(), finder: finder);
  }

  Future deleteUser(String userId) async {
    final finder = Finder(filter: Filter.equals("id", userId));

    await _userStore.delete(await _db, finder: finder);
  }

  Future<User> getSingleUser(String userId) async {
    final finder = Finder(filter: Filter.equals("id", userId));
    final recordSnapshot = await _userStore.findFirst(await _db, finder: finder);

    return recordSnapshot.value.isNotEmpty ? User.fromJson(recordSnapshot.value) : null;
  }

  // Verify user is in the local DB or not when login
  Future<User> getUserByGoogleAccountId(String googleAccountId) async {
    final finder = Finder(filter: Filter.equals("googleAccountId", googleAccountId));
    final recordSnapshot = await _userStore.findFirst(await _db, finder: finder);

    return recordSnapshot.value.isNotEmpty ? User.fromJson(recordSnapshot.value) : null;
  }

  // In future, when multiple logins needed
  Future<List<User>> getAllUsers() async {
    final recordSnapshots = await _userStore.find(await _db);
    List<User> userList = recordSnapshots.map((snapshot) {
      final user = User.fromJson(snapshot.value);
      print("user.id: " + user.id);
      print("snapshot.key: " +
          snapshot.key.toString());
      user.id = snapshot.key.toString();
      return user;
    });

    return userList;
  }
}