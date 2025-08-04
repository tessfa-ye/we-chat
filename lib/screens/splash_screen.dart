import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: mq.height * 0.15,
            right: mq.width * 0.25,
            width: mq.width * 0.6,
            child: Image.asset('images/application.png'),
          ),
          Positioned(
            bottom: mq.height * 0.1,
            width: mq.width,
            child: Text(
              'this is the opening screen of the app and it will be replaced by the login screen 🚮',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                letterSpacing: .5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
