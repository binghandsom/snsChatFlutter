////Jaguar ORM
//import 'package:jaguar_query/jaguar_query.dart';
//import 'package:jaguar_orm/jaguar_orm.dart';
//
//part 'settings.jorm.dart';
//
//// This is a table for Settings, which is used for User's customization of the app
//class Settings {
//  Settings({this.id, this.notification});
//
//  Settings.make(this.id, this.notification);
//
//  @PrimaryKey()
//  String id;
//
//  @Column(isNullable: true)
//  String userId; // User object
//
//  @Column(isNullable: true)
//  bool notification;
//
//  @override
//  String toString() {
//    return 'Settings{id: $id, userId: $userId, notification: $notification}';
//  }
//}
//
//@GenBean()
//class SettingsBean extends Bean<Settings> with _SettingsBean {
//  SettingsBean(Adapter adapter) : super(adapter);
//
//  final String tableName = 'settings';
//}
