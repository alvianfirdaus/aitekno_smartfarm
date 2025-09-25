import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aitekno_smartfarm/Pages/kendali.dart';
import 'package:aitekno_smartfarm/Pages/lingkungan.dart';
import 'package:aitekno_smartfarm/Pages/catatan.dart';
import 'package:aitekno_smartfarm/Pages/hitung_nutrisi.dart';
import 'package:aitekno_smartfarm/Pages/akun.dart';
import 'package:aitekno_smartfarm/Pages/edukasi.dart';

class DashboardScreen extends StatefulWidget {
  final int selectedIndex;

  const DashboardScreen({Key? key, this.selectedIndex = 0}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
          Column(
            children: [
              // Gambar Header
              Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/DashboardHeader.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Grid Menu
              Expanded(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      // HAPUS shrinkWrap & NeverScrollableScrollPhysics
      // shrinkWrap: true, // <-- hapus ini
      // physics: NeverScrollableScrollPhysics(), // <-- hapus ini
      physics: const BouncingScrollPhysics(), // optional: efek scroll iOS, bisa pakai AlwaysScrollableScrollPhysics()
      padding: const EdgeInsets.only(bottom: 24), // biar ada ruang di bawah
      children: [
        DashboardItem(
          imagePath: 'assets/images/iconcontrol.png',
          label: 'Kendali IOT',
          onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => KendaliScreen()),
          ),
        ),
        DashboardItem(
          imagePath: 'assets/images/iconlingkungan.png',
          label: 'Status Lingkungan',
          onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => LingkunganScreen()),
          ),
        ),
        DashboardItem(
          imagePath: 'assets/images/iconscript.png',
          label: 'Catatan',
          onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => CatatanScreen()),
          ),
        ),
        DashboardItem(
          imagePath: 'assets/images/icondeteksi.png',
          label: 'Rekomendasi Pupuk',
          onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => HitungNutrisiScreen()),
          ),
        ),
        DashboardItem(
          imagePath: 'assets/images/iconedu.png',
          label: 'Edukasi Pertanian',
          onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => EdukasiScreen()),
          ),
        ),
      ],
    ),
  ),
),
            ],
          ),
          // PlotBox di tengah atas gambar (responsif & dinamis)
          Positioned(
            top: 158,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
          ),
        ],
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
          color: isSelected ? Color.fromARGB(255, 255, 255, 255) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color.fromARGB(255, 255, 255, 255) : Colors.green.shade900,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 8, 102, 12).withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // <--- penting untuk fleksibilitas lebar
          children: [
            Icon(
              Icons.devices,
              color: isSelected ? Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Perangkat : $plotName',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                softWrap: true,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Color.fromARGB(255, 39, 128, 15) : Colors.green[900],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const DashboardItem({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.green.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 48,
                  height: 48,
                ),
                SizedBox(height: 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
