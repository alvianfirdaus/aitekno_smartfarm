import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:aitekno_smartfarm/Routes/routes.dart';
import 'package:aitekno_smartfarm/Pages/editcatatan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatatanScreen extends StatefulWidget {
  @override
  _CatatanScreenState createState() => _CatatanScreenState();
}

class _CatatanScreenState extends State<CatatanScreen> {
  String selectedPlot = "Plot 01"; // Default selected plot
  Map<String, dynamic> plotData = {}; // Plot data

  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadSelectedPlot(); // Load saved plot
  }

  Future<void> _loadSelectedPlot() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlot = prefs.getString('selected_plot') ?? "Plot 01";
    setState(() {
      selectedPlot = savedPlot;
    });
    listenToPlotData(savedPlot.toLowerCase().replaceAll(' ', ''));
  }

  // Listen to Firebase Realtime Database updates
  void listenToPlotData(String plot) {
    databaseReference.child(plot).onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          plotData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/headercatatann.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Plot selection buttons overlaid on the image
         Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 158, left: 16, right: 16),
            child: PlotBox(
              plotName: selectedPlot,
              isSelected: true,
              onTap: () {
                final plotKey = selectedPlot.toLowerCase().replaceAll(' ', '');
                listenToPlotData(plotKey);
              },
            ),
          ),
         ),

          // Main content below the image
          Column(
            children: [
              SizedBox(height: 230), // Space for the image

              // List of notes
              Expanded(
              child: plotData.isNotEmpty && plotData["zcatatan"] != null
                  ? ListView.builder(
                      itemCount: (plotData["zcatatan"] as Map?)?.keys.length ?? 0,
                      itemBuilder: (context, index) {
                        var sortedKeys = (plotData["zcatatan"] as Map?)?.keys.toList() ?? [];

                        if (sortedKeys.isEmpty) return SizedBox(); // Hindari error jika kosong

                        sortedKeys.sort((a, b) => int.parse(b).compareTo(int.parse(a)));

                        String key = sortedKeys[index];
                        Map<String, dynamic>? catatan =
                            (plotData["zcatatan"][key] as Map?)?.cast<String, dynamic>();

                        if (catatan == null) return SizedBox(); // Jika null, jangan tampilkan

                        return CatatanCard(
                          tanggal: catatan["tanggal"] ?? "Tidak ada tanggal",
                          waktu: catatan["waktu"] ?? "Tidak ada waktu",
                          catatan: catatan["catatan"] ?? "Tidak ada catatan",
                          onDelete: () async {
                            try {
                              await databaseReference.child('$selectedPlot/zcatatan/$key').remove();
                            } catch (e) {
                              print("Terjadi kesalahan saat menghapus data: $e");
                            }
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditCatatanScreen(
                                  selectedPlot: selectedPlot,
                                  catatanKey: key, // Key catatan yang valid
                                  initialCatatan: catatan["catatan"] ?? "", 
                                  initialTanggal: catatan["tanggal"] ?? "",
                                  initialWaktu: catatan["waktu"] ?? "",
                                ),
                              ),
                            );
                          },
                          onInfo: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Detail Catatan"),
                                content: Text(
                                  "Tanggal: ${catatan['tanggal'] ?? "Tidak ada"}\n"
                                  "Waktu: ${catatan['waktu'] ?? "Tidak ada"}\n"
                                  "Catatan: ${catatan['catatan'] ?? "Tidak ada"}",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Tutup"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    )
                  : Center(child: Text("Belum ada catatan.")),
            ),

            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Pindah ke halaman tambah catatan
          Navigator.pushNamed(context, '/addcatatan', arguments: selectedPlot);
        },
        backgroundColor: Colors.orange,
        child: Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
      ),
    );
  }
}

class PlotBox extends StatelessWidget {
  final bool isSelected;
  final String plotName;
  final VoidCallback onTap;

  const PlotBox({
    required this.isSelected,
    required this.plotName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.green.shade900,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.devices,
              color: isSelected ? Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
            ),
            SizedBox(width: 8),
            Text(
              'Perangkat : $plotName',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatatanCard extends StatelessWidget {
  final String tanggal;
  final String waktu;
  final String catatan;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onInfo;

  const CatatanCard({
    required this.tanggal,
    required this.waktu,
    required this.catatan,
    required this.onDelete,
    required this.onEdit,
    required this.onInfo,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Konfirmasi"),
              content: Text("Apakah Anda yakin ingin menghapus catatan ini?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("Tidak"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("Ya"),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 16),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        width: double.infinity,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tanggal,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: const Color.fromARGB(255,0,101,31)),
                ),
                SizedBox(height: 4),
                Text(
                  waktu,
                  style: TextStyle(fontSize: 14, color: Color.fromARGB(255,0,101,31)),
                ),
                SizedBox(height: 8),
                // Row untuk menyusun teks catatan & ikon di satu baris
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Expanded agar teks catatan fleksibel
                    Expanded(
                      child: Text(
                        catatan,
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                    
                    // Ikon Edit & Info di kanan sejajar teks
                    IconButton(
                      icon: Icon(Icons.edit, color: Color.fromARGB(255, 11, 111, 9)),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: Icon(Icons.info, color: Color.fromARGB(255, 255, 152, 0)),
                      onPressed: onInfo,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
