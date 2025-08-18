import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  Future<void> register() async {
    if (passwordController.text != confirmPasswordController.text) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Password tidak sama'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Berhasil'),
          content: const Text('Registrasi berhasil! Silakan login.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke halaman login
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registrasi gagal';
      if (e.code == 'email-already-in-use') {
        message = 'email sudah digunakan';
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                color: Color(0xFF006400),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(80),
                  bottomRight: Radius.circular(80),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/images/sitanamputih.png',
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "REGISTER",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: Column(
                  children: [
                    _buildInputField(Icons.person, 'Email', emailController),
                    const SizedBox(height: 30),
                    _buildPasswordField(
                      'Password',
                      passwordController,
                      isPasswordVisible,
                      (value) {
                        setState(() {
                          isPasswordVisible = value;
                        });
                      },
                    ),
                    const SizedBox(height: 30),
                    _buildPasswordField(
                      'Konfirmasi Password',
                      confirmPasswordController,
                      isConfirmPasswordVisible,
                      (value) {
                        setState(() {
                          isConfirmPasswordVisible = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006400),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'REGISTER',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'Sudah Punya akun',
                style: const TextStyle(color: Colors.black54),
                children: [
                  TextSpan(
                    text: ' Login disini',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.pop(context); // Kembali ke halaman login
                      },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agro Smart Farm @ 2025',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(IconData icon, String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String hint,
    TextEditingController controller,
    bool isPasswordVisible,
    Function(bool) onVisibilityChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.vpn_key),
          hintText: hint,
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              onVisibilityChanged(!isPasswordVisible);
            },
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
