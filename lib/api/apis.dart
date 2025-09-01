import 'dart:developer';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http_parser/http_parser.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/models/message.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static late ChatUser me;
  static User get user => auth.currentUser!;

  // for accessing push notifications
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    await fMessaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Firebase Messaging Token: $t');
      }
    });
    // for handling foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Got a message whilst in the foreground!');
      log('Message data: ${message.data}');

      if (message.notification != null) {
        log('Message also contained a notification: ${message.notification}');
      }
    });
  }

  // for sending push notifications
  static Future<void> sendPushNotification(
    ChatUser chatUser,
    String msg,
  ) async {
    try {
      final body = {
        "token": chatUser.pushToken,
        "title": chatUser.name,
        "body": msg,
        "android_channel_id": "chats",

        "data": {"some_data": "User ID: ${me.id}"},
      };

      final res = await http.post(
        // Uri.parse('http://10.0.2.2:3000/send-notification'),
        Uri.parse('http://192.168.137.1:3000/send-notification'),
        headers: {HttpHeaders.contentTypeHeader: 'application/json'},
        body: jsonEncode(body),
      );
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nSending push notification: $e');
    }
  }

  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((doc) async {
      if (doc.exists) {
        me = ChatUser.fromJson(doc.data()!);
        getFirebaseMessagingToken();
        APIs.updateActiveStatus(true);
        log('My Data: ${doc.data()}');
      } else {
        await createUser().then((_) => getSelfInfo());
      }
    });
  }

  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      about: "Hey I am using We Chat!",
      image: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
      email: user.email.toString(),
      pushToken: '',
    );
    await firestore.collection('users').doc(user.uid).set(chatUser.toJson());
  }

  // get all users
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for updating user information
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  static Future<String?> uploadProfileImage(String path) async {
    try {
      log('Starting image upload for path: $path');
      final request = http.MultipartRequest(
        'POST',
        // Uri.parse('http://10.0.2.2:3000/upload'),
        Uri.parse('http://192.168.137.1:3000/upload'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          path,
          contentType: MediaType('image', 'jpeg'), // Explicitly set MIME type
        ),
      );
      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final resBody = await response.stream.bytesToString();
      log('Server response: ${response.statusCode} - $resBody');
      if (response.statusCode == 200) {
        final data = json.decode(resBody);
        log('Uploaded image URL: ${data['url']}');
        return data['url'];
      } else {
        log('Upload failed: ${response.statusCode} - $resBody');
        return null;
      }
    } catch (e) {
      log('Upload error: $e');
      return null;
    }
  }

  // update profile picture of user
  static Future<void> updateProfilePicture(String path) async {
    final imageUrl = await uploadProfileImage(path);
    if (imageUrl != null) {
      me.image = imageUrl;
      await firestore.collection('users').doc(user.uid).update({
        'image': imageUrl,
      });
      await getSelfInfo();
      CachedNetworkImageProvider(imageUrl).evict();
    } else {
      throw Exception('Failed to upload profile picture');
    }
  }

  //for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
    ChatUser chatUser,
  ) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  // update online or last active status
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  ///*******chat_screen related APIs

  // useful for getting conversation id
  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  // Get all messages for a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
    ChatUser user,
  ) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // Send a message
  static Future<void> sendMessage(
    ChatUser chatUser,
    String msg,
    Type type,
  ) async {
    // message sending time
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final Message message = Message(
      told: chatUser.id,
      msg: msg,
      read: '',
      type: type,
      fromId: user.uid,
      sent: time,
    );

    final ref = firestore.collection(
      'chats/${getConversationID(chatUser.id)}/messages',
    );
    ref
        .doc(time)
        .set(message.toJson())
        .then(
          (value) =>
              sendPushNotification(chatUser, type == Type.text ? msg : 'Image'),
        );
  }

  // update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.fromId)}/messages')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get only last message of a specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
    ChatUser user,
  ) {
    return firestore
        .collection('chats/${getConversationID(user.id)}/messages')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  // send chat image
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.137.1:3000/upload'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          file.path,
          contentType: MediaType('image', file.path.split('.').last),
        ),
      );

      final response = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(resBody);
        final imageUrl = data['url']; // backend should return image URL

        // send image as a chat message
        await APIs.sendMessage(chatUser, imageUrl, Type.image);
        log("Chat image uploaded & sent: $imageUrl");
      } else {
        log("Chat image upload failed: ${response.statusCode} - $resBody");
      }
    } catch (e) {
      log("Error uploading chat image: $e");
    }
  }

  // for deleting messages
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.told)}/messages')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      try {
        // Call backend API to delete the image file
        final res = await http.post(
          // Uri.parse("http://10.0.2.2:3000/delete"),
          Uri.parse("http://192.168.137.1:3000/delete"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"url": message.msg}), // msg contains image URL
        );

        if (res.statusCode == 200) {
          log("Image deleted from server");
        } else {
          log("Failed to delete image: ${res.body}");
        }
      } catch (e) {
        log("Error deleting image: $e");
      }
    }
  }
}
