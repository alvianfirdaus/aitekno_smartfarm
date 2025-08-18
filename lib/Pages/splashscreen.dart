import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aitekno_smartfarm/Routes/routes.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 2)); // Splash delay
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/daftaralatpage');
    } else {
      Navigator.pushReplacementNamed(context, Routes.loginPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logositanam.png', width: 170, height: 170),
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Agro Smart Farm @ 2025',
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xff4a4a4a),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
