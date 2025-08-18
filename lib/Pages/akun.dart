import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aitekno_smartfarm/Routes/routes.dart';

class AkunScreen extends StatefulWidget {
  @override
  _AkunScreenState createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _ubahPassword() async {
  String oldPassword = _oldPasswordController.text.trim();
  String newPassword = _newPasswordController.text.trim();
  String confirmPassword = _confirmPasswordController.text.trim();

  if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
    _showMessage("Semua kolom harus diisi.");
    return;
  }

  if (newPassword != confirmPassword) {
    _showMessage("Password baru dan konfirmasi tidak cocok.");
    return;
  }

  try {
    User user = _auth.currentUser!;
    AuthCredential credential = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);

    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    // Tampilkan pop-up sukses
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Berhasil"),
          content: const Text("Password berhasil diubah. Silakan login kembali."),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                Navigator.of(context).pop(); // Tutup dialog
                await _auth.signOut(); // Logout
                Navigator.pushReplacementNamed(context, '/loginpage'); // Arahkan ke login
              },
            ),
          ],
        );
      },
    );
  } catch (e) {
    _showMessage("Gagal mengubah password: $e");
  }
}

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/loginpage');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _auth.currentUser?.email ?? 'Email tidak ditemukan';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        toolbarHeight: 80,
        centerTitle: true,
        automaticallyImplyLeading: false, // Tambahkan ini
        title: const Text(
          'Akun',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profil box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 0, 100, 0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Color.fromARGB(255, 0, 100, 0)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Pengaturan akun
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 0, 100, 0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Pengaturan Akun',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ExpansionTile(
                        title: const Text(
                          "Ubah Password",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down_circle, color: Colors.green),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _oldPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password Lama',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Password Baru',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Konfirmasi Password Baru',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _ubahPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 0, 100, 0),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Simpan Password'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Logout button
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 192, 13, 0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 135, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Logout', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
