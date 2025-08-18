import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aitekno_smartfarm/widgets/SensorDataPanelWidget.dart';
import 'package:aitekno_smartfarm/widgets/GrafikDataPanelWidget.dart';
import 'package:aitekno_smartfarm/widgets/GrafikDataPanelWidgetW.dart';
import 'package:aitekno_smartfarm/widgets/TabelDataPanelWidget.dart';

class LingkunganScreen extends StatefulWidget {
  @override
  _LingkunganScreenState createState() => _LingkunganScreenState();
}

class _LingkunganScreenState extends State<LingkunganScreen> {
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
      body: Column(
        children: [
          // Header dengan Kotak Plot
          Stack(
            alignment: Alignment.center,
            children: [
              // Gambar Header
              Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/headerlingkungan.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Kotak Pilihan Plot di Tengah Header
              Positioned(
                bottom: 20,
                child: PlotBox(
                  plotName: selectedPlot,
                  isSelected: true,
                  onTap: () {
                    // Optional: Bisa tambahkan logika jika ingin berpindah plot di sini
                    final plotKey = selectedPlot.toLowerCase().replaceAll(' ', '');
                    listenToPlotData(plotKey);
                  },
                ),
              ),

            ],
          ),

          // Konten yang bisa di-scroll
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),

                  // Sensor Data Panel
                  SensorDataPanelWidget(
                    selectedPlot: selectedPlot,
                    plotData: plotData,
                  ),

                  SizedBox(height: 40),

                  // Grafik Data Panel
                  GrafikDataPanelWidget(
                    selectedPlot: selectedPlot,
                    plotData: plotData,
                  ),

                  SizedBox(height: 40),

                  

                  GrafikBulananWidget(
                    plotData: plotData, // Gunakan plotData langsung
                  ),

                  SizedBox(height: 40),
                  
                 TabelDataPanelWidget(
                    plotData: plotData,
                  ),
                  SizedBox(height: 20),
                ],
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

