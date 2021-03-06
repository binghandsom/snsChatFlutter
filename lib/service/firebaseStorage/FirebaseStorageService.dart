import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  // Returns remote URL of the file
  // String type value: User, UserContact, GroupPhoto, Message. Defines the Category of the file when it's uploaded to the Storage
  // String id: userId, UserContactId, conversationGroupId, messageId
  // Directory in Firebase Storage format:
  Future<String> uploadFile(String filePath, String type, String id) async {
    try {
      File file = File(filePath);
      print("file.path: " + file.path);

      int lastSlash = file.path.lastIndexOf("/");
      int lastDot = file.path.lastIndexOf(".");
      String fileName = file.path.substring(lastSlash + 1, lastDot);
      String fileFormat = file.path.substring(lastDot + 1, file.path.length);

      print("fileName: " + fileName);

      String filePathInFirebaseStorage = '$type/$id/$fileName.$fileFormat';
      print("filePathInFirebaseStorage: " + filePathInFirebaseStorage);

      // Upload
      StorageReference storageRef = FirebaseStorage.instance.ref().child(filePathInFirebaseStorage);
      String uploadPath = await storageRef.getPath();
      print("Uploading to " + uploadPath);
      StorageUploadTask uploadTask = storageRef.putFile(file);

      // Get Remote URL
      StorageTaskSnapshot downloadUrl = await uploadTask.onComplete;
      final String url = (await downloadUrl.ref.getDownloadURL());
      print('URL Is $url');

      return url;
    } catch (e) {
      print("Upload failed");
      print("Reason: " + e.toString());
      return null;
    }
  }
}
