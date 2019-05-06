import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// To show either take photo from camera or select photo from Gallery
showOptionsDialog(BuildContext context) {
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select Group Photo'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text('Take Photo'),
              onPressed: () {},
            ),
            SimpleDialogOption(
              child: Text('Select photo from Gallery'),
              onPressed: () {},
            )
          ],
        );
      });
}

//Future getImage(ImageSource source) async {
//  var image = await ImagePicker.pickImage(source: ImageSource.camera);
//  if (await image.exists()) {
//    imageExists = true;
//  }
//  setState(() {
//    _image = image;
//  });
//}