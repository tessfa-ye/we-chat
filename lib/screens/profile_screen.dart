// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_chat/api/apis.dart';
import 'package:we_chat/helper/dialogs.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  void initState() {
    super.initState();
    // Fetch latest user data when screen loads
    APIs.getSelfInfo().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile Screen')),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              Dialogs.showProgressBar(context);
              await APIs.updateActiveStatus(false);
              // Sign out from app
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  Navigator.pop(context); // Hide progress dialog
                  Navigator.pop(context); // Pop ProfileScreen

                  APIs.auth = FirebaseAuth.instance;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                });
              });
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(width: mq.width, height: mq.height * .03),
                  Stack(
                    children: [
                      // Profile picture
                      _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                mq.height * .1,
                              ),
                              child: Image.file(
                                File(_image!),
                                width: mq.height * .2,
                                height: mq.height * .2,
                                fit: BoxFit.cover,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(
                                mq.height * .1,
                              ),
                              child: CachedNetworkImage(
                                width: mq.height * .2,
                                height: mq.height * .2,
                                fit: BoxFit.cover,
                                imageUrl: APIs.me.image,
                                cacheKey:
                                    APIs.me.image +
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                placeholder: (context, url) =>
                                    const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                errorWidget: (context, url, error) =>
                                    const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                              ),
                            ),
                      // Edit image button
                      Positioned(
                        right: -10,
                        bottom: 0,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: _showBottomSheet,
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(Icons.edit, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mq.height * .03),
                  Text(
                    widget.user.email,
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  SizedBox(height: mq.height * .05),
                  TextFormField(
                    initialValue: APIs.me.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'e.g. Tess',
                      label: const Text('Name'),
                    ),
                  ),
                  SizedBox(height: mq.height * .02),
                  TextFormField(
                    initialValue: APIs.me.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                        val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.info, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'e.g. Feeling Happy',
                      label: const Text('About'),
                    ),
                  ),
                  SizedBox(height: mq.height * .05),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: const StadiumBorder(),
                      minimumSize: Size(mq.width * .35, mq.height * .043),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfo()
                            .then((value) {
                              Dialogs.showSnackBar(
                                context,
                                'Profile Updated Successfully!',
                              );
                            })
                            .catchError((e) {
                              Dialogs.showSnackBar(
                                context,
                                'Failed to update profile: $e',
                              );
                            });
                      }
                    },
                    icon: const Icon(Icons.edit, size: 25, color: Colors.white),
                    label: const Text(
                      'UPDATE',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(
            top: mq.height * .03,
            bottom: mq.height * .05,
          ),
          children: [
            const Text(
              'Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .25, mq.height * .1),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      log('Image path: ${image.path}');
                      setState(() {
                        _image = image.path;
                      });
                      try {
                        Dialogs.showProgressBar(context);
                        await APIs.updateProfilePicture(_image!);
                        setState(() {
                          _image = null; // Clear local image
                        });
                        Navigator.pop(context); // Hide progress bar
                        Navigator.pop(context); // Hide bottom sheet
                        Dialogs.showSnackBar(
                          context,
                          'Profile picture updated successfully!',
                        );
                      } catch (e) {
                        Navigator.pop(context); // Hide progress bar
                        Navigator.pop(context); // Hide bottom sheet
                        Dialogs.showSnackBar(
                          context,
                          'Failed to update profile picture: $e',
                        );
                        log('Profile picture update error: $e');
                      }
                    }
                  },
                  child: Image.asset('images/gallery.png'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * .25, mq.height * .1),
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      log('Image path: ${image.path}');
                      setState(() {
                        _image = image.path;
                      });
                      try {
                        Dialogs.showProgressBar(context);
                        await APIs.updateProfilePicture(_image!);
                        setState(() {
                          _image = null; // Clear local image
                        });
                        Navigator.pop(context); // Hide progress bar
                        Navigator.pop(context); // Hide bottom sheet
                        Dialogs.showSnackBar(
                          context,
                          'Profile picture updated successfully!',
                        );
                      } catch (e) {
                        Navigator.pop(context); // Hide progress bar
                        Navigator.pop(context); // Hide bottom sheet
                        Dialogs.showSnackBar(
                          context,
                          'Failed to update profile picture: $e',
                        );
                        log('Profile picture update error: $e');
                      }
                    }
                  },
                  child: Image.asset('images/camera.png'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
