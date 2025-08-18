import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aitekno_smartfarm/Pages/akun.dart';
import 'package:aitekno_smartfarm/Pages/lingkungan.dart';
import 'package:aitekno_smartfarm/Pages/dashboard.dart';
import 'package:aitekno_smartfarm/Pages/tambahAlat.dart';

class DaftarAlatPage extends StatefulWidget {
  const DaftarAlatPage({Key? key}) : super(key: key);

  @override
  State<DaftarAlatPage> createState() => _DaftarAlatPageState();
}

class _DaftarAlatPageState extends State<DaftarAlatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String? userEmail;
  String? userUid;
  Map<String, dynamic> userPlots = {};

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      userEmail = user.email;
      userUid = user.uid;

      final plotsSnapshot = await _dbRef.get();
      Map<String, dynamic> temp = {};

      if (plotsSnapshot.exists) {
        for (final child in plotsSnapshot.children) {
          final plotId = child.key ?? '';
          final plotData = Map<String, dynamic>.from(child.value as Map);

          if (plotData.containsKey('id')) {
            final idList = plotData['id'];

            if (idList is List && idList.contains(userUid)) {
              temp[plotId] = plotData;
              print('UID user login: $userUid');
            }
          }
        }
      }

      setState(() {
        userPlots = temp;
      });
    }
  }

  void showDeleteConfirmationDialog(String plotName) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'Hapus Perangkat',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Text('Apakah Anda yakin ingin menghapus perangkat "$plotName"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tidak'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await deleteDeviceForCurrentUser(plotName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 0, 100, 0), // Warna hijau
            foregroundColor: Colors.white, // Teks putih
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded
            ),
          ),
          child: const Text('Iya'),
        ),
      ],
    ),
  );
}

  Future<void> deleteDeviceForCurrentUser(String plotName) async {
    try {
      final deviceRef = _dbRef.child(plotName);
      final snapshot = await deviceRef.get();

      if (snapshot.exists && userUid != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        if (data.containsKey('id')) {
          List<dynamic> idList = List.from(data['id']);

          idList.removeWhere((uid) => uid == userUid);

          // Update id array meskipun kosong, tanpa menghapus node plot
          await deviceRef.update({'id': idList});

          setState(() {
            userPlots.remove(plotName);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('UID Anda berhasil dihapus dari "$plotName".')),
          );
        }
      }
    } catch (e) {
      print('Error saat menghapus UID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menghapus UID.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF006400),
      appBar: AppBar(
        backgroundColor: const Color(0xFF006400),
         automaticallyImplyLeading: false, // Tambahkan ini
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TambahAlatPage()),
              );
            },
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Image.asset('assets/images/sitanamputih.png', height: 80),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(color: Colors.white, fontSize: 23),
                    ),
                    Text(
                      userEmail ?? '',
                      style: const TextStyle(color: Colors.amber, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Perangkat IoT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    userPlots.isEmpty
                        ? Center(
                            child: Container(
                              height: 550,
                              width: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  
                                ],
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/promo.png'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: userPlots.entries.map((entry) {
                              final plotName = entry.key;
                              return GestureDetector(
                                onTap: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('selected_plot', plotName);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DashboardScreen(),
                                    ),
                                  );
                                },
                                onLongPress: () {
                                  showDeleteConfirmationDialog(plotName);
                                },
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 60) / 2,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF006400),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.devices, color: Colors.white, size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Perangkat\n$plotName',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          height: 1.3,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                    const SizedBox(height: 30),
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
