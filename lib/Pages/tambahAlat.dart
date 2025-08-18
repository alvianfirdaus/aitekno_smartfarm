import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:aitekno_smartfarm/Pages/akun.dart';

class TambahAlatPage extends StatefulWidget {
  const TambahAlatPage({Key? key}) : super(key: key);

  @override
  State<TambahAlatPage> createState() => _TambahAlatPageState();
}

class _TambahAlatPageState extends State<TambahAlatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  final TextEditingController _alatController = TextEditingController();
  bool _scanned = false; // Untuk mencegah scan berulang-ulang

  void _onScan(Barcode barcode) {
    if (_scanned) return;
    setState(() {
      _alatController.text = barcode.rawValue ?? '';
      _scanned = true;
    });
  }

  Future<void> _connectDevice() async {
    final String plotName = _alatController.text.trim();
    final String? userUid = _auth.currentUser?.uid;

    if (plotName.isEmpty || userUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID alat kosong atau pengguna tidak terautentikasi.')),
      );
      return;
    }

    try {
      final plotRef = _dbRef.child(plotName);
      final snapshot = await plotRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        List<dynamic> idList = [];
        if (data.containsKey('id')) {
          idList = List.from(data['id']);
        }

        if (!idList.contains(userUid)) {
          idList.add(userUid);
          await plotRef.update({'id': idList});
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
                'Berhasil',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            content: Text('Berhasil terkoneksi dengan $plotName'),
            actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/daftaralatpage');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Tombol hijau
                    foregroundColor: Colors.white, // Teks putih
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Ujung membulat
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ),
          ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plot "$plotName" tidak ditemukan di database.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006400),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006400),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AkunScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
  children: [
    const SizedBox(height: 40),
    Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Arahkan kamera ke QR Code Perangkat",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 300,
                  child: MobileScanner(
                    fit: BoxFit.cover,
                    onDetect: (BarcodeCapture capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode != null) {
                        _onScan(barcode);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                controller: _alatController,
                enabled: false, // Membuat kolom tidak bisa diketik
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  // labelText: 'ID Perangkat',
                  filled: true,
                  fillColor: Color.fromARGB(255, 224, 224, 224), // Warna latar belakang abu-abu
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
                SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _connectDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 100, 0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'connect',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
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
