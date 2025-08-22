import 'dart:developer';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:we_chat/api/apis.dart';
import 'package:we_chat/helper/dialogs.dart';
import '../../main.dart';
import '../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isAnimate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        isAnimate = true;
      });
    });
  }

  _handleGoogleBtnClick() {
    //showing progress bar
    Dialogs.showProgressBar(context);
    _signInWithGoogle().then((user) async {
      //hiding progress bar
      Navigator.pop(context);
      if (user != null) {
        log('\nUser signed in: ${user.user}');
        log('\nUserAdditionalInfo: ${user.additionalUserInfo}');

        if ((await APIs.userExists())) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');
      log('Starting Google Sign-In...');
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            "287503120557-n52h77d180jr1kmfcmrvmuutsbogbeec.apps.googleusercontent.com",
        scopes: ['email', 'profile'],
      );
      log('GoogleSignIn initialized');

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      log('Google Sign-In result: $googleUser');

      if (googleUser == null) {
        throw Exception('Google Sign-In was canceled by the user');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      log(
        'Google Auth: accessToken=${googleAuth.accessToken}, idToken=${googleAuth.idToken}',
      );

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      log('Signing in with Firebase...');
      final userCredential = await APIs.auth.signInWithCredential(credential);
      log('Firebase Sign-In successful: ${userCredential.user}');
      return userCredential;
    } catch (e) {
      log('\n_signInWithGoogle: $e');
      Dialogs.showSnackBar(context, 'some thing went wrong(check internet!)');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Welcome to We Chat'),
      ),
      body: Stack(
        children: [
          AnimatedPositioned(
            top: mq.height * 0.15,
            right: isAnimate ? mq.width * 0.25 : -mq.width * 0.5,
            width: mq.width * 0.6,
            duration: const Duration(seconds: 1),
            child: Image.asset('images/application.png'),
          ),
          Positioned(
            bottom: mq.height * 0.1,
            left: mq.width * 0.09,
            width: mq.width * 0.8,
            height: mq.height * 0.05,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 203, 224, 148),
                shape: StadiumBorder(),
                elevation: 1,
              ),
              onPressed: () {
                _handleGoogleBtnClick();
              },
              icon: Image.asset('images/google.png', height: mq.height * 0.03),
              label: RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(text: 'Log in with '),
                    TextSpan(
                      text: 'Google',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
