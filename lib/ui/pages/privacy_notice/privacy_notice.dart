import 'package:flutter/material.dart';

class PrivacyNoticePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return new PrivacyNoticePageState();
  }

}

class PrivacyNoticePageState extends State<PrivacyNoticePage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return  new Scaffold(
      appBar: new AppBar(
        title: new Text('Privacy Notice'),
      ),
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text("Privacy Notice")
        ],
      ),
    );
  }

}